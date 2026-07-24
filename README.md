# CloseEncounters

… of the Third Party.

Add serices and events that can track responses from third-party services.

## Usage
Install it like any other rails engine.

```ruby
rails close_encounters:install:migrations
```

Then when you have it installed and migrated you can start tracking events.

```ruby
response = SomeThirdPartyService.call
CloseEncounters.contact("SomeThirdPartyService", status: response.status.to_i, response: response.body)
```

If the service regularly returns 200 responses, no new events will be recorded.
When it switches to a different status, a new event will be recorded.

```ruby
CloseEncounters.status("SomeThirdPartyService") # => 200
# eventually you use `contact` and it records a 500 and you'll be able to get
CloseEncounters.status("SomeThirdPartyService") # => 500
```

### Recording a response from any HTTP client

`CloseEncounters.record` records a contact straight from an HTTP client's
response object, using an *adapter* to read the status and body. This keeps the
gem independent of any particular HTTP library.

```ruby
response = SomeThirdPartyService.call # a Net::HTTP response
CloseEncounters.record("SomeThirdPartyService", response, adapter: CloseEncounters::Adapters::NetHTTP)
```

Pass a `verifier` to record a verified scan instead of a plain contact:

```ruby
CloseEncounters.record("SomeService", response, adapter: CloseEncounters::Adapters::NetHTTP, verifier: my_verifier)
```

An adapter is any object that responds to `status(response)` and
`body(response)`, so supporting another client is a few lines:

```ruby
module FaradayAdapter
  module_function
  def status(response) = response.status
  def body(response) = response.body
end

CloseEncounters.record("SomeApi", faraday_response, adapter: FaradayAdapter)
```

### Rack Middleware (deprecated)

> **Deprecated.** `CloseEncounters::Middleware` keys on the *inbound* request
> host (`SERVER_NAME`), so it tracks requests arriving at your app rather than
> the outbound responses this gem is meant to monitor. Track responses with
> `CloseEncounters.record` (above) instead. The middleware will be removed in a
> future release.

### Reacting to status changes

Rather than polling `CloseEncounters.status`, you can subscribe to be notified
whenever a new event is recorded (by either `contact` or `scan`). A
notification is only published when an event is actually created — i.e. when
the status or verification signature changes.

```ruby
ActiveSupport::Notifications.subscribe("event_recorded.close_encounters") do |*args|
  payload = ActiveSupport::Notifications::Event.new(*args).payload
  # payload => { name:, service:, event:, status: }
  AlertMailer.status_changed(payload[:name], payload[:status]).deliver_later
end
```

### TODO

- [ ] Add JS to the gem to track events on the front-end.
- [ ] Add a UI to create and manage services.
- [ ] Add a UI to view events.

## Installation
Add this line to your application's Gemfile:

```ruby
gem "close_encounters"
```

And then execute:
```bash
$ bundle
```

Or install it yourself as:
```bash
$ gem install close_encounters
```

## Releasing

This project is managed with [Reissue](https://github.com/SOFware/reissue). Releases are automated via the [shared release workflow](https://github.com/SOFware/reissue/blob/main/.github/workflows/SHARED_WORKFLOW_README.md). Trigger a release by running the "Release gem to RubyGems.org" workflow from the Actions tab.

Changelog entries come from git trailers (`Added:`, `Fixed:`, …) on your commits and/or hand-edits to the `## [Unreleased]` section of `CHANGELOG.md`; Reissue merges both. See [CONTRIBUTING.md](CONTRIBUTING.md#changelog-entries).

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
