# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased](https://git.rustybever.be/vieter/vieter/src/branch/dev)

### Added

* Server port can now be configured

### Changed

* Moved all API routes under `/v1` namespace
* Renamed `vieter repos` to `vieter targets`
* Renamed `/v1/api/repos` namespace to `/v1/api/targets`

## [0.3.0](https://git.rustybever.be/vieter/vieter/src/tag/0.3.0)

Nothing besides bumping the versions.

## [0.3.0-rc.1](https://git.rustybever.be/vieter/vieter/src/tag/0.3.0-rc.1)

### Added

* Database migrations
* Improved GitRepo & BuildLog API
    * Pagination using `limit` & `offset` query params
    * GitRepo: filter by repo
    * BuildLog: filter by start & end date, repo, exit code & arch
* CLI flags to take advantage of above API improvements
* Added CLI command to generate all man pages
* PKGBUILDs now install man pages
* Hosted CLI man pages ([vieter(1)](https://rustybever.be/man/vieter/vieter.1.html))
* Proper HTTP API docs ([link](https://rustybever.be/docs/vieter/api/))

### Changed

* Packages from target repo are available during builds
    * This can be used as a basic way to support AUR dependencies, by adding
      the dependencies to the same repository
* Every build now updates its packages first instead of solely relying on the
  updated builder image
* Build logs now show commands being executed

### Fixed

* `POST /api/logs` now correctly uses epoch timestamps instead of strings

## [0.3.0-alpha.2](https://git.rustybever.be/vieter/vieter/src/tag/0.3.0-alpha.2)

### Added

* Web API for adding & querying build logs
* CLI commands to access build logs API
* Cron build logs are uploaded to above API
* Proper ASCII table output in CLI
* `vieter repos build id` command to run builds locally

### Removed

* `vieter build` command
    * This command was used alongside cron for periodic builds, but this has
      been replaced by `vieter cron`

### Changed

* `vieter build` command now only builds a single repository & uploads the
  build logs
* Official Arch packages are now split between `vieter` & `vieter-git`
    * `vieter` is the latest release
    * `vieter-git` is the latest commit on the dev branch
* Full refactor of Docker socket code

## [0.3.0-alpha.1](https://git.rustybever.be/vieter/vieter/src/tag/0.3.0-alpha.1)

### Changed

* Switched from compiler fork to fully vanilla compiler mirror
* `download_dir`, `repos_file` & `repos_dir` config values have been replaced
  with `data_dir`
* Storage of metadata (e.g. Git repositories) is now done using Sqlite

### Added

* Implemented own cron daemon for builder
    * Build schedule can be configured globally or individually per repository
* Added CLI command to show detailed information per repo

### Fixed

* Binary no longer panics when an env var is missing

## [0.2.0](https://git.rustybever.be/vieter/vieter/src/tag/0.2.0)

### Changed

* Better config system
    * Support for both a config file & environment variables
    * Each env var can now be provided from a file by appending it with `_FILE`
      & passing the path to the file as value
* Revamped web framework
    * All routes now return proper JSON where applicable & the correct status
      codes

### Added

* Very basic build system
    * Build is triggered by separate cron container
    * Packages build on cron container's system
    * A HEAD request is used to determine whether a package should be rebuilt
      or not
    * Hardcoded planning of builds
    * Builds are sequential
* API for managing Git repositories to build
* CLI to list, add & remove Git repos to build
* Published packages on my Vieter instance
* Support for multiple repositories
* Support for multiple architectures per repository

### Fixed

* Each package can now only have one version in the repository at once
  (required by Pacman)
* Packages with unknown fields in .PKGINFO are now allowed
* Old packages are now properly removed

## [0.1.0](https://git.rustybever.be/vieter/vieter/src/tag/0.1.0)

### Changed

* Improved logging

## [0.1.0-rc.1](https://git.rustybever.be/vieter/vieter/src/tag/0.1.0-rc.1)

### Added

* Ability to publish packages
* Re-wrote repo-add in V
