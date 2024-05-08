require "test_helper"

module CloseEncounters
  class ParticipantServiceTest < ActiveSupport::TestCase
    fixtures :all

    it "requires a name" do
      participant_service = CloseEncounters::ParticipantService.new
      assert_not participant_service.valid?
      assert_includes participant_service.errors.messages[:name], "can't be blank"
    end

    it "stores encrypted connection info" do
      participant_service = CloseEncounters::ParticipantService.new(name: "Test Service")
      connection_info = {"token" => "abc123"}
      participant_service.connection_info = connection_info
      participant_service.save!
      assert_equal connection_info, participant_service.connection_info
    end

    it "has many events" do
      participant_service = close_encounters_participant_services(:aliens)
      event = participant_service.events.create!(status: 200, response: "Yay! Everything worked.")
      assert_includes participant_service.events, event
    end
  end
end
