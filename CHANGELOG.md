# Change log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/)
and this project adheres to [Semantic Versioning](http://semver.org/).

## [0.1.2] - Unreleased

### Added

- Check if the table exits before conditionally setting up the serialize column

### Removed

- Appending engine migrations to the main app's migration path

## [0.1.1] - 2024-07-11

### Added

- Support for Importmaps
- `reissue` gem for managing releases

### Fixed

- Alter newest scope to properly return a relation limited to 1 record
- Update ensure_service to not overwrite existing connection_info
- Allow specs to run properly locally
- Incorrect manifest paths for sprockets
