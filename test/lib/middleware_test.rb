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
  end
end
