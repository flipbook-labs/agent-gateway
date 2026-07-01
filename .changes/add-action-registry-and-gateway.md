---
bump: minor
category: Features
---

Add `createActionRegistry` and `createGateway` — the core public API. Plugins register named actions with input schemas via the registry; the gateway publishes a `BindableFunction` under `CoreGui` so agents can discover (`list`) and invoke (`call`) them over a stable protocol.