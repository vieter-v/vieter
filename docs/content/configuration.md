---
weight: 20
---
# Configuration

By default, all vieter commands try to read in the TOML file `~/.vieterrc` for
configuration. The location of this file can be changed by using the `-f` flag.

If the above file doesn't exist or you wish to override some of its settings,
configuration is also possible using environment variables. Every variable in
the config file has a respective environment variable of the following form:
say the variable is called `api_key`, then the respective environment variable
would be `VIETER_API_KEY`. In essence, it's the variable in uppercase prepended
with `VIETER_`.

If a variable is both present in the config file & as an environment variable,
the value in the environment variable is used.

{{< hint info >}}
**Note**
All environment variables can also be provided from a file by appending them
with `_FILE`. This for example allows you to provide the API key from a Docker
secrets file.
{{< /hint >}}

## Commands

The first argument passed to Vieter determines which command you wish to use.
Each of these can contain subcommands (e.g. `vieter targets list`), but all
subcommands will use the same configuration. Below you can find the
configuration variable required for each command.

### `vieter server`

* `port`: HTTP port to run on
    * Default: `8000`
* `log_level`: log verbosity level. Value should be one of `FATAL`, `ERROR`,
  `WARN`, `INFO` or `DEBUG`.
    * Default: `WARN`
* `pkg_dir`:  where Vieter should store the actual package archives.
* `data_dir`: where Vieter stores the repositories, log file & database.
* `api_key`: the API key to use when authenticating requests.
* `default_arch`: this setting serves two main purposes:
    * Packages with architecture `any` are always added to this architecture.
      This prevents the server from being confused when an `any` package is
      published as the very first package for a repository.
    * Targets added without an `arch` value use this value instead.
* `global_schedule`: build schedule for any target that does not have a
  schedule defined. For information about this syntax, see
  [here](/usage/builds/schedule).
    * Default: `0 3` (3AM every night)
* `base_image`: Docker image to use when building a package. Any Pacman-based
  distro image should work, as long as `/etc/pacman.conf` is used &
  `base-devel` exists in the repositories. Make sure that the image supports
  the architecture of your cron daemon.
    * Default: `archlinux:base-devel` (only works on `x86_64`). If you require
      `aarch64` support, consider using
      [`menci/archlinuxarm:base-devel`](https://hub.docker.com/r/menci/archlinuxarm)
      ([GitHub](https://github.com/Menci/docker-archlinuxarm)). This is the
      image used for the Vieter CI builds.
* `max_log_age`: maximum age of logs (in days). Logs older than this will get
  cleaned by the log removal daemon. If set to a negative value, no logs are
  ever removed. The age of logs is determined by the time the build was
  started.
    * Default: `-1`
* `log_removal_schedule`: cron schedule defining when to clean old logs.
    * Default: `0 0` (every day at midnight)

### `vieter cron`

* `log_level`: log verbosity level. Value should be one of `FATAL`, `ERROR`,
  `WARN`, `INFO` or `DEBUG`.
    * Default: `WARN`
* `log_file`: log file to write logs to.
    * Default: `vieter.log` (in `data_dir`)
* `address`: *public* URL of the Vieter repository server to build for. From
  this server the list of Git repositories is retrieved. All built packages are
  published to this server.
* `api_key`: API key of the above server.
* `data_dir`: directory to store log file in.
* `base_image`: Docker image to use when building a package. Any Pacman-based
  distro image should work, as long as `/etc/pacman.conf` is used &
  `base-devel` exists in the repositories. Make sure that the image supports
  the architecture of your cron daemon.
    * Default: `archlinux:base-devel` (only works on `x86_64`). If you require
      `aarch64` support, consider using
      [`menci/archlinuxarm:base-devel`](https://hub.docker.com/r/menci/archlinuxarm)
      ([GitHub](https://github.com/Menci/docker-archlinuxarm)). This is the image
      used for the Vieter CI builds.
* `max_concurrent_builds`: how many builds to run at the same time.
    * Default: `1`
* `api_update_frequency`: how frequently (in minutes) to poll the Vieter
  repository server for a new list of Git repositories to build.
    * Default: `15`
* `image_rebuild_frequency`: Vieter periodically builds a builder image using
  the configured base image. This makes sure build containers do not have to
  download a lot of packages when updating their system. This setting defines
  how frequently (in minutes) to rebuild this builder image.
    * Default: `1440` (every 24 hours)
* `global_schedule`: build schedule for any Git repository that does not have a
  schedule defined. For information about this syntax, see
  [here](/usage/builds/schedule).
    * Default: `0 3` (3AM every night)

### `vieter logs`

* `api_key`: the API key to use when authenticating requests.
* `address`: Base URL of your Vieter instance, e.g. https://example.com

### `vieter targets`

* `api_key`: the API key to use when authenticating requests.
* `address`: Base URL of your Vieter instance, e.g. https://example.com
* `base_image`: image to use when building a package using `vieter targets
  build`.
    * Default: `archlinux:base-devel`

### `vieter agent`

* `log_level`: log verbosity level. Value should be one of `FATAL`, `ERROR`,
  `WARN`, `INFO` or `DEBUG`.
    * Default: `WARN`
* `address`: *public* URL of the Vieter repository server to build for. From
  this server jobs are retrieved. All built packages are published to this
  server.
* `api_key`: API key of the above server.
* `data_dir`: directory to store log file in.
* `max_concurrent_builds`: how many builds to run at the same time.
    * Default: `1`
* `polling_frequency`: how often (in seconds) to poll the server for new
  builds. Note that the agent might poll more frequently when it's actively
  processing builds.
* `image_rebuild_frequency`: Vieter periodically builds images that are then
  used as a basis for running build containers. This is to prevent each build
  from downloading an entire repository worth of dependencies. This setting
  defines how frequently (in minutes) to rebuild these images.
    * Default: `1440` (every 24 hours)
* `arch`: architecture for which this agent should pull down builds (e.g.
  `x86_64`)
