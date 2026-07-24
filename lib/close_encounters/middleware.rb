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
    rescue => e
      # Tracking must never break the request it is observing.
      Rails.logger&.error("[CloseEncounters] middleware tracking failed: #{e.class}: #{e.message}")
      nil
    end

    # Built per request rather than memoized: the middleware is instantiated
    # once per process, so caching here would never reflect services added or
    # changed after boot.
    def participant_services
      CloseEncounters::ParticipantService.all.each_with_object({}) do |service, map|
        domain = service.connection_info&.[]("domain")
        map[domain] = service.name if domain
      end
    end
  end
end
