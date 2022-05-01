# Vieter CLI

I provide a simple CLI tool that currently only allows changing the Git
repository API. Its usage is quite simple.

First, you need to create a file in your home directory called `.vieterrc` with
the following content:

```toml
address = "https://example.com"
api_key = "your-api-key"
```

You can also use a different file or use environment variables, as described in
[Configuration](/configuration).

Now you're ready to use the CLI tool.

## Usage

* `vieter repos list` returns all repositories currently stored in the API.
* `vieter repos add url branch repo arch...` adds the repository with the given
  URL, branch, repo & arch to the API.
* `vieter repos remove id` removes the repository with the given ID prefix.

You can always check `vieter -help` or `vieter repos -help` for more
information about the commands.
