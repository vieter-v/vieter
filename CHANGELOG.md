# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased](https://git.rustybever.be/Chewing_Bever/vieter)

## Changed

* Better config system
    * Support for both a config file & environment variables
    * Each env var can now be provided from a file by appending it with `_FILE`
      & passing the path to the file as value
* Revamped web framework
    * All routes now return proper JSON where applicable & the correct status
      codes

## Added

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

## Fixed

* Each package can now only have one version in the repository at once
  (required by Pacman)
* Packages with unknown fields in .PKGINFO are now allowed
* Old packages are now properly removed

## [0.1.0](https://git.rustybever.be/Chewing_Bever/vieter/src/tag/0.1.0)

### Changed

* Improved logging

## [0.1.0-rc.1](https://git.rustybever.be/Chewing_Bever/vieter/src/tag/0.1.0-rc.1)

### Added

* Ability to publish packages
* Re-wrote repo-add in V
