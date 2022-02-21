# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased](https://git.rustybever.be/Chewing_Bever/vieter)

## Added

* Very basic build system
    * Build is triggered by separate cron container
    * Packages build on cron container's system
    * Packages are always rebuilt, even if they haven't changed
    * Hardcoded planning of builds
    * Builds are sequential

## Fixed

* Each package can now only have one version in the repository at once
  (required by Pacman)

## [0.1.0](https://git.rustybever.be/Chewing_Bever/vieter/src/tag/0.1.0)

### Changed

* Improved logging

## [0.1.0-rc.1](https://git.rustybever.be/Chewing_Bever/vieter/src/tag/0.1.0-rc.1)

### Added

* Ability to publish packages
* Re-wrote repo-add in V
