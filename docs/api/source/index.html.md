---
title: API Reference

language_tabs: # must be one of https://git.io/vQNgJ
  - shell: cURL

toc_footers:
  - <a href='https://github.com/slatedocs/slate'>Documentation Powered by Slate</a>

includes:
  - repository
  - targets
  - logs

search: true

code_clipboard: true

meta:
  - name: description
    content: Documentation for the Vieter API
---

# Introduction

Welcome to the Vieter API documentation! Here, you can find everything related
to interacting with Vieter's HTTP API.

# Authentication

```shell
curl -H 'X-Api-Key: secret' https://example.com/api/some/path
```

> Don't forget to replace `secret` with your Vieter instance's secret.

Authentication is done by passing the HTTP header `X-Api-Key: secret` along
with each request, where `secret` is replaced with your Vieter server's
configured secret.
