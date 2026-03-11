# Changelog

All notable changes to BugCourier are documented in this file.

## [v1.1.1](https://github.com/sgnh/bug-courier/compare/v1.1.0...v1.1.1) — 2026-03-11

### Fixed

- Middleware now rescues only `StandardError`, avoiding interception of fatal Ruby exceptions such as `SystemExit` and `SignalException`
- `GithubClient` now handles transport failures that return no HTTP response without raising secondary `NoMethodError` exceptions

## [v1.1.0](https://github.com/sgnh/bug-courier/compare/v1.0.0...v1.1.0) — 2026-03-11

### Added

- `ignore_exceptions` configuration option to skip reporting for specific exception classes (e.g., `ActiveRecord::RecordNotFound`, `ActionController::RoutingError`)
- Supports both class constants and string class names in the ignore list
- Install generator now includes commented-out `ignore_exceptions` example in the initializer

### Changed

- `ExceptionHandler#handle` checks ignored exceptions before processing

## [v1.0.0](https://github.com/sgnh/bug-courier/compare/v0.1.2...v1.0.0) — 2026-03-10

### Changed

- Bumped to first stable release (1.0.0)

### Documentation

- Added GitHub Copilot integration section to README explaining automatic issue creation and pull request workflows

## [v0.1.2](https://github.com/sgnh/bug-courier/compare/v0.1.1...v0.1.2) — 2026-03-10

### Fixed

- Changed middleware insertion order from `insert_before(0, ...)` to `insert_after(ActionDispatch::DebugExceptions, ...)` to ensure proper functionality within the Rails middleware stack

## [v0.1.1](https://github.com/sgnh/bug-courier/compare/v0.1.0...v0.1.1) — 2026-03-10

### Changed

- Lowered required Ruby version from `>= 3.2.0` to `>= 2.7.0`
- Lowered `railties` dependency from `>= 7.0` to `>= 6.1` for broader Rails compatibility

## [v0.1.0] — 2026-03-10

### Added

- Initial open source release
- Rack middleware to catch uncaught exceptions automatically
- `ExceptionHandler` with full error details, backtraces, and request context
- `GithubClient` for creating GitHub issues via the API
- Deduplication support to avoid duplicate issues (comments on existing ones instead)
- Rate limiting (default: 10 issues per hour)
- Configurable labels, assignees, and optional callback after issue creation
- Rails generator (`rails generate bug_courier:install`) to scaffold an initializer
- Railtie for automatic middleware integration in Rails apps
