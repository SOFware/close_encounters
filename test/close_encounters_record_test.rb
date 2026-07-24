require "test_helper"

module CloseEncounters
  class CloseEncountersRecordTest < ActiveSupport::TestCase
    fixtures :all

    # A stand-in for a Net::HTTP response: #code is a String, #body a String.
    NetHTTPLike = Struct.new(:code, :body)
    # A stand-in for a Faraday response: #status is already an Integer.
    FaradayLike = Struct.new(:status, :body)

    test ".record uses the adapter to record a contact" do
      service = close_encounters_participant_services(:aliens) # 1 event, status 200
      response = NetHTTPLike.new("500", "Server error")

      CloseEncounters.record("aliens", response, adapter: CloseEncounters::Adapters::NetHTTP)

      _(service.events.count).must_equal 2
      _(service.events.newest.pick(:status)).must_equal 500
      _(service.events.newest.pick(:response)).must_equal "Server error"
    end

    test ".record with a verifier records a scan with verification" do
      ParticipantService.create!(name: "record_scan")
      response = NetHTTPLike.new("200", "Yay! Everything worked.")
      verifier = ->(body) { body == "Yay! Everything worked." }
      verifier.define_singleton_method(:to_s) { "record verifier" }

      event = CloseEncounters.record(
        "record_scan", response,
        adapter: CloseEncounters::Adapters::NetHTTP, verifier: verifier
      )

      _(event.status).must_equal 200
      _(event.verified?).must_equal true
    end

    test ".record works with any adapter responding to status and body" do
      service = ParticipantService.create!(name: "custom_adapter")
      response = FaradayLike.new(503, "down")
      adapter = Object.new
      adapter.define_singleton_method(:status) { |r| r.status }
      adapter.define_singleton_method(:body) { |r| r.body }

      CloseEncounters.record("custom_adapter", response, adapter: adapter)

      _(service.events.newest.pick(:status)).must_equal 503
    end

    test "Adapters::NetHTTP reads status and body from a Net::HTTP response" do
      response = NetHTTPLike.new("204", "")

      _(CloseEncounters::Adapters::NetHTTP.status(response)).must_equal 204
      _(CloseEncounters::Adapters::NetHTTP.body(response)).must_equal ""
    end
  end
end
