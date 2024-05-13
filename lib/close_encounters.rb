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
      service.connection_info = connection_info
    end
  end
end
