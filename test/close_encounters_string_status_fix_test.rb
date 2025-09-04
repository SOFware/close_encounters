require "test_helper"

module CloseEncounters
  class CloseEncountersStringStatusFixTest < ActiveSupport::TestCase
    test "contact handles string status correctly" do
      service = ParticipantService.create!(name: "string_contact_test")

      # First call with integer status
      CloseEncounters.contact("string_contact_test", status: 200, response: "First")
      assert_equal 1, service.events.count

      # Second call with STRING status - should not create duplicate
      CloseEncounters.contact("string_contact_test", status: "200", response: "Second")
      assert_equal 1, service.events.count, "String '200' should be treated same as integer 200"

      # Different status as string should create new event
      CloseEncounters.contact("string_contact_test", status: "404", response: "Error")
      assert_equal 2, service.events.count
      assert_equal 404, service.events.last.status
    end

    test "scan handles string status correctly" do
      service = ParticipantService.create!(name: "string_scan_test")

      passing_verifier = ->(response) { true }
      passing_verifier.define_singleton_method(:to_s) { "always passes" }

      # First call with integer status
      CloseEncounters.scan("string_scan_test", status: 200, response: "First", verifier: passing_verifier)
      assert_equal 1, service.events.count

      # Second call with STRING status - should not create duplicate (verification passes)
      CloseEncounters.scan("string_scan_test", status: "200", response: "Second", verifier: passing_verifier)
      assert_equal 1, service.events.count, "String '200' should be treated same as integer 200"
    end

    test "scan with string status and failing verification" do
      service = ParticipantService.create!(name: "string_scan_fail_test")

      failing_verifier = ->(response) { false }
      failing_verifier.define_singleton_method(:to_s) { "always fails" }

      # First call creates event
      CloseEncounters.scan("string_scan_fail_test", status: "200", response: "First", verifier: failing_verifier)
      assert_equal 1, service.events.count

      # Second call with string status and failing verification should create new event
      # because 200 is in verify_scan_statuses and verification fails
      CloseEncounters.scan("string_scan_fail_test", status: "200", response: "Second", verifier: failing_verifier)
      assert_equal 2, service.events.count, "Should create new event when verification fails"
    end

    test "verify_scan_statuses works with string status" do
      service = ParticipantService.create!(name: "verify_statuses_test")

      # Create initial event
      service.events.create!(status: 200, response: "Initial")

      failing_verifier = ->(response) { false }
      failing_verifier.define_singleton_method(:to_s) { "always fails" }

      # String "200" should be converted to 200 and match verify_scan_statuses
      CloseEncounters.scan("verify_statuses_test", status: "200", response: "Test", verifier: failing_verifier)

      # Should create new event because status 200 is in verify_scan_statuses and verification fails
      assert_equal 2, service.events.count
    end

    test "production scenario fixed" do
      service = ParticipantService.create!(name: "production_fixed")

      failing_verifier = ->(response) { false }
      failing_verifier.define_singleton_method(:to_s) { "production verifier" }

      # Simulate production where status might come as string
      # First call
      CloseEncounters.scan("production_fixed", status: "200", response: "Response 1", verifier: failing_verifier)
      assert_equal 1, service.events.count

      # Subsequent calls with string "200" and failing verification
      # Should create new events because verification fails (intended behavior)
      CloseEncounters.scan("production_fixed", status: "200", response: "Response 2", verifier: failing_verifier)
      assert_equal 2, service.events.count

      # But if we use contact instead (no verification)
      service2 = ParticipantService.create!(name: "production_contact")

      # Multiple calls with string status should NOT create duplicates
      5.times do |i|
        CloseEncounters.contact("production_contact", status: "200", response: "Response #{i}")
      end

      assert_equal 1, service2.events.count, "Contact should not create duplicates even with string status"
    end
  end
end
