require "test_helper"
require "minitest/mock"

module CloseEncounters
  class MiddlewareTest < ActiveSupport::TestCase
    def setup
      @app = ->(env) { [200, env, "app"] }
      @mock = Minitest::Mock.new(CloseEncounters)
    end

    def teardown
      @mock.verify
    end

    test "calls contact when domain matches" do
      fixture = close_encounters_participant_services(:aliens)
      @mock.expect(:contact, true, [fixture.name], status: 200, response: "app")
      middleware = CloseEncounters::Middleware.new(@app, tracker: @mock)

      env = {"SERVER_NAME" => "service.example"}
      result = middleware.call(env)
      assert_equal [200, env, "app"], result
    end

    test "does not call contact when domain doesn't match" do
      env = {"SERVER_NAME" => "untracked.example"}
      middleware = CloseEncounters::Middleware.new(@app, tracker: @mock)
      CloseEncounters.stub(:contact, nil) do
        assert middleware.call(env)
      end
    end

    test "returns the app response even when the tracker raises" do
      raising_tracker = Object.new
      raising_tracker.define_singleton_method(:contact) { |*, **| raise "tracking is down" }
      middleware = CloseEncounters::Middleware.new(@app, tracker: raising_tracker)

      env = {"SERVER_NAME" => "service.example"}
      result = middleware.call(env)

      assert_equal [200, env, "app"], result
    end

    test "picks up services created after the middleware was instantiated" do
      calls = []
      tracker = Object.new
      tracker.define_singleton_method(:contact) { |name, **| calls << name }
      middleware = CloseEncounters::Middleware.new(@app, tracker: tracker)

      # No service maps to this domain yet.
      middleware.call({"SERVER_NAME" => "late.example"})
      assert_empty calls

      CloseEncounters::ParticipantService.create!(
        name: "late", connection_info: {"domain" => "late.example"}
      )

      # The next request must see the newly created service.
      middleware.call({"SERVER_NAME" => "late.example"})
      assert_equal ["late"], calls
    end

    test "a service without a domain does not prevent tracking a valid one" do
      CloseEncounters::ParticipantService.create!(name: "no_domain")
      calls = []
      tracker = Object.new
      tracker.define_singleton_method(:contact) { |name, **| calls << name }
      middleware = CloseEncounters::Middleware.new(@app, tracker: tracker)

      middleware.call({"SERVER_NAME" => "service.example"})

      assert_equal ["aliens"], calls
    end
  end
end
