# Plugin Agents

[![CI](https://github.com/flipbook-labs/plugin-agents/actions/workflows/ci.yml/badge.svg)](https://github.com/flipbook-labs/plugin-agents/actions/workflows/ci.yml)

Plugin Agents is a Roblox library for exposing Studio plugin actions to
in-Studio agents through a small, MCP-inspired gateway.

This repository is in early setup. The initial package will provide:

- A generic actions registry for named, parameterized plugin behaviors
- A single `BindableFunction` gateway for agent discovery and invocation
- A small manifest format inspired by MCP tools, without claiming MCP wire
  protocol compatibility

## Installation

### Wally

```toml
[dependencies]
PluginAgents = "flipbook-labs/plugin-agents@x.x.x"
```

## Releases

Releases are managed by [Changewrite](https://github.com/flipbook-labs/changewrite)
using [`changewrite.toml`](changewrite.toml) and [`cliff.toml`](cliff.toml).

## License

The contents of this repository are available under the MIT License. For full
license text, see [LICENSE](LICENSE).