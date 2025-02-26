require "close_encounters/version"
require "close_encounters/engine"

module CloseEncounters
  module_function

  autoload :ParticipantService, "close_encounters/participant_service"
  autoload :ParticipantEvent, "close_encounters/participant_event"

  # Record a contact with a third party service if the status has changed
  #
  # @param name [String] the name of the service
  # @param status [Integer] the HTTP status of the contact
  # @param response [String] the response object
  def contact(name, status:, response:)
    service = ParticipantService.find_by!(name:)
    unless service.events.newest.pick(:status) == status
      service.events.create!(status: status, response:)
    end
  end

  # Record a verification of a contact with a third party service where the
  # verification is a callable which must also respond to to_s.
  #
  # For example, provide a callable which checks the JSON Schema for a response body
  # and will record an event if calling the verification returns false.
  #
  # @param name [String] the name of the service
  # @param status [Integer] the HTTP status of the contact
  # @param response [String] the response object
  # @param verifier [Proc] the verification callable which must also respond to to_s
  def verify(name, status:, response:, verifier:)
    service = ParticipantService.find_by!(name:)
    unless service.events.newest.pick(:status) == status && (verified = verifier.call(response))
      service.events.create!(status:, response:, metadata: {verified:, verification: verifier.to_s})
    end
  end

  # Determine if contacts with third party services should be recorded automatically
  # using the Rack Middleware
  #
  # Set the CLOSE_ENCOUNTERS_AUTO_CONTACT environment variable to enable this feature
  # or call CloseEncounters.auto_contact! in an initializer
  #
  # @return [Boolean] whether or not to automatically record contacts
  def auto_contact?
    !!(ENV["CLOSE_ENCOUNTERS_AUTO_CONTACT"] || @auto_contact)
  end

  # Enable automatic contact recording in the Rack Middleware
  def auto_contact!
    @auto_contact = true
  end

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
