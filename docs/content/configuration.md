---
weight: 20
---
# Configuration

All vieter operations by default try to read in the TOML file `~/.vieterrc` for
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
with `_FILE`. This for example allows you to provide the API key from a docker
secrets file.
{{< /hint >}}

## Modes

The vieter binary can run in several "modes", indicated by the first argument
passed to them. Each mode requires a different configuration.

### Server

* `log_level`: defines how much logs to show. Valid values are one of `FATAL`,
  `ERROR`, `WARN`, `INFO` or `DEBUG`. Defaults to `WARN`
* `log_file`: log file to write logs to. Defaults to `vieter.log` in the
  current directory.
* `pkg_dir`:  where Vieter should store the actual package archives.
* `download_dir`: where Vieter should initially download uploaded files.
* `api_key`: the API key to use when authenticating requests.
* `repo_dir`: where Vieter should store the contents of the repository.
* `repos_file`: JSON file where the list of Git repositories is saved
* `default_arch`: architecture to always add packages of arch `any` to.

{{< hint info >}}
**Note**  
Because Vieter hard links files between `download_dir` & `pkg_dir`, they need
to be on the same file system.
{{< /hint >}}

### Builder

* `api_key`: the API key to use when authenticating requests.
* `address`: Base your URL of your Vieter instance, e.g. https://example.com
* `base_image`: image to use when building a package. It should be an Archlinux
  image. The default if not configured is `archlinux:base-devel`, but this
  image only supports arm64. If you require aarch64 support as well, consider
  using
  [`menci/archlinuxarm:base-devel`](https://hub.docker.com/r/menci/archlinuxarm)
  ([GH](https://github.com/Menci/docker-archlinuxarm))

### Repos

* `api_key`: the API key to use when authenticating requests.
* `address`: Base your URL of your Vieter instance, e.g. https://example.com
