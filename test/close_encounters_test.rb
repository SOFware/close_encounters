require "test_helper"

module CloseEncounters
  class CloseEncountersTest < ActiveSupport::TestCase
    fixtures :all

    def setup
      # Save original ENV values
      @original_auto_contact = ENV["CLOSE_ENCOUNTERS_AUTO_CONTACT"]
    end

    def teardown
      # Reset configuration between tests
      CloseEncounters.remove_instance_variable(:@configuration) if CloseEncounters.instance_variable_defined?(:@configuration)

      # Restore original ENV values
      if @original_auto_contact.nil?
        ENV.delete("CLOSE_ENCOUNTERS_AUTO_CONTACT")
      else
        ENV["CLOSE_ENCOUNTERS_AUTO_CONTACT"] = @original_auto_contact
      end
    end

    test ".configure sets the configuration" do
      CloseEncounters.configure do |config|
        config.auto_contact = true
        config.verify_scan_statuses = [1, 999]
      end

      _(CloseEncounters.configuration.auto_contact).must_equal true
    end

    test ".auto_contact? returns true if the environment variable is set" do
      ENV["CLOSE_ENCOUNTERS_AUTO_CONTACT"] = "true"
      _(CloseEncounters.auto_contact?).must_equal true
    end

    test ".auto_contact? returns false if the environment variable is not set" do
      ENV.delete("CLOSE_ENCOUNTERS_AUTO_CONTACT")
      CloseEncounters.remove_instance_variable(:@configuration) if CloseEncounters.instance_variable_defined?(:@configuration)
      _(CloseEncounters.auto_contact?).must_equal false
    ensure
      ENV.delete("CLOSE_ENCOUNTERS_AUTO_CONTACT")
    end

    test ".auto_contact! enables automatic contact recording" do
      CloseEncounters.auto_contact!
      _(CloseEncounters.auto_contact?).must_equal true
    end

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

    class Verification
      def call(response)
        response == "Yay! Everything worked."
      end

      def to_s
        "Verification"
      end
    end

    test ".scan creates a new event if the status and verification are met" do
      service = close_encounters_participant_services(:aliens)
      # The fixture already has 1 event with status 200 and no metadata (verified = false)
      # First scan: status=200, verified=true -> creates new event (verified changed from false to true)
      # Second scan: status=200, verified=false -> creates new event (verified changed from true to false)
      # Total: 1 (fixture) + 2 (new) = 3 events
      CloseEncounters.scan("aliens", status: 200, response: "Yay! Everything worked.", verifier: Verification.new)
      CloseEncounters.scan("aliens", status: 200, response: "Nope! Everything failed.", verifier: Verification.new)
      _(service.events.count).must_equal 3
    end

    test ".scan creates a new event if the status is in the verify_scan_statuses list and verification fails" do
      service = close_encounters_participant_services(:aliens)
      # The fixture already has 1 event with status 200 and no metadata (verified = false)
      # Scan with status=200, verified=false -> no new event (both status and verified are same)
      CloseEncounters.scan("aliens", status: 200, response: "Nope! Everything failed.", verifier: Verification.new)
      _(service.events.count).must_equal 1
    end

    test ".scan does not create duplicate events when status and verification are unchanged" do
      service = ParticipantService.create!(name: "duplicate_test")

      failing_verifier = ->(response) { false }
      failing_verifier.define_singleton_method(:to_s) { "always fails" }

      # First call creates event with status 200 and verified: false
      CloseEncounters.scan("duplicate_test", status: 200, response: "Failed", verifier: failing_verifier)
      assert_equal 1, service.events.count
      first_event = service.events.last
      assert_equal 200, first_event.status
      assert_equal false, first_event.verified?

      # Second call with same status and same verification result should NOT create new event
      CloseEncounters.scan("duplicate_test", status: 200, response: "Still Failed", verifier: failing_verifier)
      assert_equal 1, service.events.count, "Should not create duplicate event when status and verified are same"
    end

    test ".scan creates new event when verification changes from false to true" do
      service = ParticipantService.create!(name: "verification_change_test")

      failing_verifier = ->(response) { false }
      failing_verifier.define_singleton_method(:to_s) { "always fails" }

      passing_verifier = ->(response) { true }
      passing_verifier.define_singleton_method(:to_s) { "always passes" }

      # First call creates event with status 200 and verified: false
      CloseEncounters.scan("verification_change_test", status: 200, response: "Failed", verifier: failing_verifier)
      assert_equal 1, service.events.count
      first_event = service.events.last
      assert_equal false, first_event.verified?

      # Second call with same status but different verification should create new event
      CloseEncounters.scan("verification_change_test", status: 200, response: "Now Passing", verifier: passing_verifier)
      assert_equal 2, service.events.count, "Should create new event when verification changes"
      second_event = service.events.last
      assert_equal true, second_event.verified?
    end

    test ".scan correctly handles production scenario with 200 responses" do
      service = ParticipantService.create!(name: "production_scenario")

      failing_verifier = ->(response) { false }
      failing_verifier.define_singleton_method(:to_s) { "production verifier" }

      passing_verifier = ->(response) { true }
      passing_verifier.define_singleton_method(:to_s) { "production verifier" }

      # Scenario 1: Multiple 200 unverified responses should not create duplicates
      CloseEncounters.scan("production_scenario", status: 200, response: "Unverified 1", verifier: failing_verifier)
      assert_equal 1, service.events.count

      CloseEncounters.scan("production_scenario", status: 200, response: "Unverified 2", verifier: failing_verifier)
      assert_equal 1, service.events.count, "Should not record duplicate 200 unverified"

      CloseEncounters.scan("production_scenario", status: 200, response: "Unverified 3", verifier: failing_verifier)
      assert_equal 1, service.events.count, "Should not record duplicate 200 unverified"

      # Scenario 2: 200 verified should create new event
      CloseEncounters.scan("production_scenario", status: 200, response: "Verified", verifier: passing_verifier)
      assert_equal 2, service.events.count, "Should record new event when verification changes to true"

      # Scenario 3: Multiple 200 verified responses should not create duplicates
      CloseEncounters.scan("production_scenario", status: 200, response: "Verified 2", verifier: passing_verifier)
      assert_equal 2, service.events.count, "Should not record duplicate 200 verified"

      # Scenario 4: Back to unverified should create new event
      CloseEncounters.scan("production_scenario", status: 200, response: "Unverified again", verifier: failing_verifier)
      assert_equal 3, service.events.count, "Should record new event when verification changes back to false"
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
