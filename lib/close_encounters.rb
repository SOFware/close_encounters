require "close_encounters/version"
require "close_encounters/engine"

module CloseEncounters
  module_function

  autoload :ParticipantService, "close_encounters/participant_service"
  autoload :ParticipantEvent, "close_encounters/participant_event"

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

    # Use a transaction with a lock to prevent race conditions
    service.with_lock do
      unless service.events.newest.pick(:status) == status
        service.events.create!(status: status, response:)
      end
    end
  end

  # Record a verification of a contact with a third party service where the
  # verification is a callable which must also respond to to_s.
  #
  # Creates a new event if:
  # 1. The status has changed from the last recorded status
  # 2. OR the status is in the verify_scan list AND verification fails
  #
  # @param name [String] the name of the service
  # @param status [Integer] the HTTP status of the contact
  # @param response [String] the response object
  # @param verifier [Proc] the verification callable which must also respond to to_s
  def scan(name, status:, response:, verifier:)
    service = ParticipantService.find_by!(name:)
    status = status.to_i # Ensure status is always an integer

    service.with_lock do
      last_event = service.events.newest.first
      last_status = last_event&.status
      last_verified = last_event&.verified?

      # Calculate current verification result
      verified = verifier.call(response)

      # Create a new event if:
      # 1. Status has changed OR
      # 2. Status is in verify_scan_statuses AND verified flag has changed
      if last_status != status
        # Status changed, always create new event
        service.events.create!(status:, response:, metadata: {verified:, verification: verifier.to_s})
      elsif verify_scan_statuses.include?(status) && last_verified != verified
        # Status same but verification result changed for a monitored status
        service.events.create!(status:, response:, metadata: {verified:, verification: verifier.to_s})
      end
    end
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
