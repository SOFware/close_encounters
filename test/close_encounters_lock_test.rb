require "test_helper"

module CloseEncounters
  class CloseEncountersLockTest < ActiveSupport::TestCase
    test ".scan with lock prevents duplicate events when status hasn't changed" do
      service = ParticipantService.create!(name: "scan_lock_test")
      service.events.create!(status: 200, response: "Initial")

      verifier = ->(response) { true }
      verifier.define_singleton_method(:to_s) { "always true verifier" }

      # Multiple rapid calls with same status should only keep the original event
      3.times do
        CloseEncounters.scan("scan_lock_test", status: 200, response: "Same status", verifier: verifier)
      end

      # Should still only have 1 event since status didn't change and verification passed
      assert_equal 1, service.events.count
    end

    test ".scan with lock creates event when verification fails for verify_scan_statuses" do
      service = ParticipantService.create!(name: "scan_verify_fail")
      service.events.create!(status: 200, response: "Initial good")

      failing_verifier = ->(response) { false }
      failing_verifier.define_singleton_method(:to_s) { "always fails verifier" }

      # Status 200 is in verify_scan_statuses by default
      # When verification fails, it should create a new event even with same status
      CloseEncounters.scan("scan_verify_fail", status: 200, response: "Bad response", verifier: failing_verifier)

      assert_equal 2, service.events.count
      last_event = service.events.order(:created_at).last
      assert_equal false, last_event.metadata["verified"]
    end

    test ".scan handles nil status when no previous events exist" do
      service = ParticipantService.create!(name: "scan_nil_test")

      verifier = ->(response) { true }
      verifier.define_singleton_method(:to_s) { "test verifier" }

      # No previous events, so newest.pick(:status) returns nil
      # Should create first event
      CloseEncounters.scan("scan_nil_test", status: 200, response: "First", verifier: verifier)

      assert_equal 1, service.events.count
      assert_equal 200, service.events.first.status
    end

    test ".scan metadata includes verification details" do
      service = ParticipantService.create!(name: "scan_metadata_test")

      verifier = ->(response) { response.include?("OK") }
      verifier.define_singleton_method(:to_s) { "checks for OK" }

      CloseEncounters.scan("scan_metadata_test", status: 200, response: "OK response", verifier: verifier)

      event = service.events.first
      assert_equal true, event.metadata["verified"]
      assert_equal "checks for OK", event.metadata["verification"]
    end

    test ".contact handles nil status when no previous events exist" do
      service = ParticipantService.create!(name: "contact_nil_test")

      # No previous events, so newest.pick(:status) returns nil
      # Should create first event
      CloseEncounters.contact("contact_nil_test", status: 200, response: "First")

      assert_equal 1, service.events.count
      assert_equal 200, service.events.first.status
    end
  end
end
