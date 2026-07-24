module CloseEncounters
  module Adapters
    # Adapter for Net::HTTP responses. An adapter is any object responding to
    # #status(response) and #body(response); see CloseEncounters.record.
    module NetHTTP
      module_function

      # Net::HTTP exposes the status as a String (e.g. "200").
      def status(response) = response.code.to_i

      def body(response) = response.body
    end
  end
end
