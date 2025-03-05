# Change log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.2.2] - Unreleased

## [0.2.1] - 2025-03-05

### Added

- Add alias for verify method as scan.
- Add configuration for auto_contact and verify_scan_statuses.

### Changed

- Ensure that events are only created if the status has changed or if the status is in the verify_scan_statuses list and verification fails.
