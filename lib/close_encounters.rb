require "close_encounters/version"
require "close_encounters/engine"

module CloseEncounters
  module_function

  autoload :ParticipantService, "close_encounters/participant_service"
  autoload :ParticipantEvent, "close_encounters/participant_event"

  module Adapters
    autoload :NetHTTP, "close_encounters/adapters/net_http"
  end

  class Configuration
    attr_accessor :auto_contact, :verify_scan_statuses

    def initialize
      @auto_contact = !!ENV["CLOSE_ENCOUNTERS_AUTO_CONTACT"]
      @verify_scan_statuses = [200, 201]
    end
  end

  def self.configuration
    @configuration ||= Configuration.new
  end

  # Deprecator for CloseEncounters. Registered with the host app in the engine
  # so warnings flow through the app's configured deprecation behavior.
  def self.deprecator
    @deprecator ||= ActiveSupport::Deprecation.new("a future release", "CloseEncounters")
  end

  def self.configure
    yield(configuration)
  end

  # Record a contact with a third party service if the status has changed
  #
  # @param name [String] the name of the service
  # @param status [Integer] the HTTP status of the contact
  # @param response [String] the response object
  def contact(name, status:, response:)
    service = ParticipantService.find_by!(name:)
    status = status.to_i # Ensure status is always an integer

    created = nil
    # Use a transaction with a lock to prevent race conditions
    service.with_lock do
      unless service.events.newest.pick(:status) == status
        created = service.events.create!(status: status, response:)
      end
    end

    # Instrument after the transaction commits so subscribers see a persisted event.
    instrument(name, created) if created
    created
  end

  # Record the outcome of an HTTP request to a service straight from the
  # client's response object, using an adapter to read the status and body.
  #
  # An adapter is any object responding to #status(response) and
  # #body(response); CloseEncounters::Adapters::NetHTTP ships for Net::HTTP.
  # Delegates to #scan when a verifier is given, otherwise #contact.
  #
  #   CloseEncounters.record("SomeService", response, adapter: Adapters::NetHTTP)
  #   CloseEncounters.record("SomeService", response, adapter: Adapters::NetHTTP, verifier: my_verifier)
  #
  # @param name [String] the name of the service
  # @param response [Object] the HTTP client's response object
  # @param adapter [#status, #body] reads the status and body from the response
  # @param verifier [#call, #to_s, nil] when given, records a verified scan
  def record(name, response, adapter:, verifier: nil)
    status = adapter.status(response)
    body = adapter.body(response)
    if verifier
      scan(name, status:, response: body, verifier:)
    else
      contact(name, status:, response: body)
    end
  end

  # Publish an ActiveSupport::Notifications event whenever a new
  # ParticipantEvent is recorded, so consumers can react to status changes
  # instead of polling. Subscribe with:
  #
  #   ActiveSupport::Notifications.subscribe("event_recorded.close_encounters") do |*args|
  #     payload = ActiveSupport::Notifications::Event.new(*args).payload
  #     # payload => { name:, service:, event:, status: }
  #   end
  def instrument(name, event)
    ActiveSupport::Notifications.instrument(
      "event_recorded.close_encounters",
      name:, service: event.participant_service, event:, status: event.status
    )
  end
  private_class_method :instrument

  VERIFIED_SIGNATURE = "ok"
  UNVERIFIED_SIGNATURE = "unverified"

  # Record a verification of a contact with a third party service where the
  # verification is a callable which must also respond to to_s.
  #
  # The verifier may return:
  #   * true / :ok           — response is verified
  #   * false / nil          — response failed verification (generic)
  #   * any other value      — failed verification with a distinguishing
  #                            "signature" (e.g. "missing:user.email").
  #                            Stable signatures let scan suppress repeated
  #                            identical failures while still recording when
  #                            the failure mode changes meaningfully.
  #
  # Creates a new event if:
  # 1. The status has changed from the last recorded status, OR
  # 2. The status is in the verify_scan list AND the verification signature
  #    differs from the last recorded signature.
  #
  # @param name [String] the name of the service
  # @param status [Integer] the HTTP status of the contact
  # @param response [String] the response object
  # @param verifier [#call, #to_s] the verification callable
  def scan(name, status:, response:, verifier:)
    service = ParticipantService.find_by!(name:)
    status = status.to_i # Ensure status is always an integer

    created = nil
    service.with_lock do
      last_event = service.events.newest.first
      last_status = last_event&.status

      signature = signature_for(verifier.call(response))
      verified = (signature == VERIFIED_SIGNATURE)
      last_signature = signature_for_event(last_event)

      metadata = {verified:, signature:, verification: verifier.to_s}

      if last_status != status
        created = service.events.create!(status:, response:, metadata:)
      elsif verify_scan_statuses.include?(status) && last_signature != signature
        created = service.events.create!(status:, response:, metadata:)
      end
    end

    instrument(name, created) if created
    created
  end

  # Normalize a verifier return value into a stable signature string.
  def signature_for(result)
    case result
    when true, :ok then VERIFIED_SIGNATURE
    when false, nil then UNVERIFIED_SIGNATURE
    else result.to_s
    end
  end

  # Read the signature off a previously stored event, falling back to the
  # legacy verified flag for events created before signatures existed.
  def signature_for_event(event)
    return nil unless event
    stored = event.metadata.to_h["signature"]
    return stored if stored
    event.verified? ? VERIFIED_SIGNATURE : UNVERIFIED_SIGNATURE
  end
  alias_method :verify, :scan
  module_function :verify

  # Determine if contacts with third party services should be recorded automatically
  # using the Rack Middleware
  #
  # Set the CLOSE_ENCOUNTERS_AUTO_CONTACT environment variable to enable this feature
  # or call CloseEncounters.auto_contact! in an initializer
  #
  # @return [Boolean] whether or not to automatically record contacts
  def auto_contact?
    # If auto_contact is explicitly set, use that value
    return configuration.auto_contact unless configuration.auto_contact.nil?
    # Otherwise check the environment variable
    !!ENV["CLOSE_ENCOUNTERS_AUTO_CONTACT"]
  end

  # Enable automatic contact recording in the Rack Middleware
  def auto_contact!
    configuration.auto_contact = true
  end

  # Get the statuses that should be verified
  def verify_scan_statuses = configuration.verify_scan_statuses

  # Get the status of the most recent contact with a third party service
  #
  # @param name [String] the name of the service
  # @return [Integer] the HTTP status of the most recent contact
  def status(name)
    ParticipantService.find_by!(name: name).events.newest.pick(:status)
  end

  # Ensure that a participant service exists
  #
  # @param name [String] the name of the service
  # @param connection_info [Hash] the connection information for the service
  def ensure_service(name, connection_info: {})
    ParticipantService.find_or_create_by!(name: name) do |service|
      service.connection_info = connection_info unless service.connection_info.present?
    end
  end
end
