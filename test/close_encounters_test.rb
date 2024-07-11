require "test_helper"

module CloseEncounters
  class CloseEncountersTest < ActiveSupport::TestCase
    fixtures :all

    test ".contact creates a new event if the status has changed" do
      service = close_encounters_participant_services(:aliens)
      # _working_event = close_encounters_participant_events(:working)

      CloseEncounters.contact("aliens", status: 500, response: "Oops! Nothing worked.")

      _(service.events.count).must_equal 2
      _(service.events.last.status).must_equal 500
    end

    test ".contact does not create a new event if the status has not changed" do
      service = close_encounters_participant_services(:others)
      # _failing_event = close_encounters_participant_events(:failing)

      CloseEncounters.contact("others", status: 500, response: "Failed again.")

      _(service.events.count).must_equal 1
    end

    test ".contact raises an error if the service is not found" do
      expect { CloseEncounters.contact("service", status: 200, response: "Yay! Everything worked.") }.must_raise ActiveRecord::RecordNotFound
    end

    test ".status returns the status of the most recent event" do
      service = close_encounters_participant_services(:aliens)
      service.events.create!(status: 200, response: "Yay! Everything worked.")
      service.events.create!(status: 500, response: "Oops! Nothing worked.")

      _(CloseEncounters.status("aliens")).must_equal 500
    end

    test ".status raises an error if the service is not found" do
      expect { CloseEncounters.status("service") }.must_raise ActiveRecord::RecordNotFound
    end

    test ".ensure_service creates a new service if it does not exist" do
      assert_difference("CloseEncounters::ParticipantService.count", 1) do
        CloseEncounters.ensure_service("New Service")
      end

      _(ParticipantService.find_by(name: "New Service")).wont_be_nil
    end

    test ".ensure_service does not create a new service if it exists" do
      CloseEncounters.ensure_service("aliens")

      _(ParticipantService.where(name: "aliens").count).must_equal 1
    end

    test ".ensure_service does not overwrite the connection info if it exists" do
      service = close_encounters_participant_services(:aliens)
      service.update!(connection_info: {"key" => "value"})

      CloseEncounters.ensure_service("aliens", connection_info: {"new_key" => "new_value"})

      _(service.reload.connection_info).must_equal({"key" => "value"})
    end
  end
end
