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
CloseEncounters.contact("SomeThirdPartyService", status: response.status.to_i, response.body)
```

If the services regularly returns 200 responses, no new events will be recorded.
When it switches to a different status, a new event will be recorded.

```ruby
CloseEncounters.status("SomeThirdPartyService") # => 200
# evuntually you use `contact` and it records a 500 and you'll be able to get
CloseEncounters.status("SomeThirdPartyService") # => 500
```

### Rack Middleware

Setup your middleware in your `config/application.rb` or `config/environments/production.rb`.

```ruby
config.middleware.use CloseEncounters::Middleware
```

This will automatically track responses from third-party services when you store a "domain" key in the
`connection_info` in the ParticipantService records.

Alternatively, you can use the `auto_contact!` method to automatically turn on the rack middleware:

```ruby
CloseEncounters.auto_contact!
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

## License
The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
