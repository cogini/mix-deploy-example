# Changelog
All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [2.0.0] - 2020-01-23
### Added
- Support Elixir 1.9 `mix release`, now the default instead of Distillery
- `elixir_release_release_system` configures `mix` or `distillery`
- `elixir_release_release_name` configures release script name, default `app_name`

### Changed
- `elixir_release_start_command` defaults to `start` instead of `foreground`
