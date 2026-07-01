---
bump: minor
category: Changes
---

Remove the `Surface`/`Surfaces` concept entirely. The gateway only ever served the agent surface, so the abstraction added complexity without benefit. The `surfaces` field is gone from `Action` and `ManifestEntry`, and `dispatch`/`manifest` no longer accept a surface filter argument.