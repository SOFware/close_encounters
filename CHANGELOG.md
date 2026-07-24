# Change log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.3.1] - Unreleased

## [0.3.0] - 2026-07-24

### Added

- Publish an `event_recorded.close_encounters` notification whenever a status change is recorded (83ed88c)
- CloseEncounters.record and pluggable response adapters (Adapters::NetHTTP) for tracking any HTTP client (d86e4e8)

### Changed

- Update dependencies (reissue 0.5.1, standard, sqlite3, puma, and others) and migrate the SimpleCov config to 1.0 (83ed88c)
- Develop and release on Ruby 4.0.6; CI now tests on 3.4 and 4.0.6 (83ed88c)
- Align the release workflow with reissue's shared workflow, adding checksum generation and a dry-run input (83ed88c)

### Deprecated

- CloseEncounters::Middleware, which tracked inbound requests; use CloseEncounters.record for outbound responses (d86e4e8)

### Fixed

- The tracking middleware no longer breaks the request it observes, rebuilds its service map each request, and ignores services without a domain (83ed88c)
- The newest-event lookup is now deterministic on timestamp ties and backed by a composite index (e94afe5)
