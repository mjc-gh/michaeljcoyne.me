---
layout: post
title:  "OpenCode Custom YAML LSP"
date:   2026-05-01T12:20:00Z
description: "The post describes a workaround for configuring OpenCode to properly handle YAML files in Rails projects by disabling the default YAML LSP and using a globally installed yaml-language-server instead."
---

I've been using [OpenCode](https://opencode.ai/) as my go-to coding
agent for personal development. I'll be describing my workflow in an
upcoming post.

Rails makes heavy use of YAML for configuration files as well as for
handling localization translations. Even a small app may have hundreds
of YAML entries for localization. I've noticed that OpenCode sometimes
struggles with editing YAML files and ensuring correct indentation and
key consistency.

YAML is on the [list of supported LSP](https://opencode.ai/docs/lsp/),
but I've had issues with OpenCode initializing these LSPs, especially
within a Rails project. Thus, I've added the following workaround to my
opencode.json config file to address this issue using a globally
installed [yaml-language-server](https://github.com/redhat-developer/yaml-language-server/).

First, we need to install the LSP server with:

```
bun add -g yaml-language-server
```

Next, I've added the following configuration to
`~/.config/opencode/opencode.json`:

```json
{
  "$schema": "https://opencode.ai/config.json",
  "lsp": {
    "yaml-ls": {
      "disabled": true
    },
    "custom-yml": {
      "command": ["bun", "x", "yaml-language-server", "--stdio"],
      "extensions": [".yaml", ".yml"]
    }
  }
}
```

The key is to disable the default `yaml-ls` LSP; without this change,
the `custom-yml` does not kick in.

I believe [this PR](https://github.com/anomalyco/opencode/pull/6986)
should make this configuration unnecessary in the future. For now, this
is a suitable workaround and OpenCode is able to edit YAML files in my
Rails projects without issues. It should even recognize duplicate keys
and formatting issues automatically. How nice!
