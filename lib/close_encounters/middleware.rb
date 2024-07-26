module CloseEncounters
  class Middleware
    def initialize(app, tracker: CloseEncounters)
      @app = app
      @tracker = tracker
    end

    def call(env)
      status, headers, response = @app.call(env)

      record_contact(env["SERVER_NAME"], status, response)

      [status, headers, response]
    end

    private

    def record_contact(host, status, response)
      if (name = participant_services[host])
        @tracker.contact(name, status:, response:)
      end
    end

    def participant_services
      @participant_services ||= CloseEncounters::ParticipantService.all
        .map do |service|
          [service.connection_info["domain"], service.name]
        end.to_h
    end
  end
end
