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

      assert_equal event2, ParticipantEvent.newest.first
    end

    it "returns the last-inserted event when timestamps tie" do
      service = ParticipantService.create!(name: "tie")
      frozen = Time.current.change(usec: 0)
      older = service.events.create!(status: 200, response: "first", created_at: frozen, updated_at: frozen)
      newer = service.events.create!(status: 500, response: "second", created_at: frozen, updated_at: frozen)

      assert newer.id > older.id, "expected the second insert to have the larger id"
      assert_equal newer, service.events.newest.first
    end

    it "has a composite index supporting the newest-event lookup" do
      index = ActiveRecord::Base.connection
        .indexes("close_encounters_participant_events")
        .find { |i| i.columns == ["close_encounters_participant_service_id", "created_at"] }

      assert index, "expected a composite index on (service_id, created_at) for the newest-event query"
    end

    it "can store metadata" do
      service = ParticipantService.create!(name: "test")
      event = service.events.create!(status: 200, response: "OK", metadata: {foo: "bar"})
      assert_equal({"foo" => "bar"}, event.metadata)
    end

    it "can check if an event is verified" do
      service = ParticipantService.create!(name: "test")
      event = service.events.build(status: 200, response: "OK", metadata: {verified: true})
      assert event.verified?
      event.metadata = {verified: false}
      refute event.verified?
    end

    it "is not verified if the metadata is not present" do
      service = ParticipantService.create!(name: "test")
      event = service.events.build(status: 200, response: "OK")
      refute event.verified?
    end
  end
end
