require "test_helper"

module CloseEncounters
  class ParticipantEventTest < ActiveSupport::TestCase
    it "belongs to a participant service" do
      service = close_encounters_participant_services(:aliens)
      event = service.events.create!(status: 200, response: "OK")

      assert_equal service, event.participant_service
    end

    it "returns the newest event" do
      service = ParticipantService.create!(name: "test")
      service.events.create!(status: 200, response: "OK")
      event2 = service.events.create!(status: 404, response: "Not Found")

      assert_equal event2, ParticipantEvent.newest
    end
  end
end
