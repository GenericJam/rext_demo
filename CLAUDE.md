# rext_demo — Agent Instructions

Proof-of-concept app for [rext](../rext). **Read `../rext/CLAUDE.md` first** for
shared conventions (toolchain paths, quality gates, the "don't write slop"
list). This file covers only what's specific to the demo.

## What it demonstrates

The desktop paradigm: two windows (`CounterWindow` id `"main"`,
`MirrorWindow` id `"mirror"`), each a supervised process, kept in sync by plain
`send/2`. `CounterWindow.notify_mirror/1` pushes the count to
`Rext.Window.via("mirror")` on every change; the mirror reacts in `handle_info`.
This is the intended shape for cross-window state on desktop — message passing
between processes, not a shared store or a nav stack.

## Run / drive

```bash
export PATH="/Users/kevin/.local/share/mise/installs/erlang/29.0/bin:/Users/kevin/.local/share/mise/installs/elixir/1.20.0-otp-29/bin:$PATH"
mix test                 # headless proof of cross-window sync
mix rext.run             # live: opens windows + renderer
```

Live dist drive (agent workflow):

```elixir
n = :"rext_demo_app@127.0.0.1"; Node.connect(n)
Rext.Test.click(n, :inc, "main")
Rext.Test.assigns(n, "mirror")   # mirror follows the counter
```

## Notes

- `config :rext, :port` is ephemeral under test, fixed (8137) otherwise.
- Windows must be started before `notify_mirror` can find the mirror; at boot
  the counter's mount notifies only if the mirror is already up (no-op
  otherwise), so window start order is not load-bearing.
- Held to the same gate as the rest of the ecosystem: `mix format`,
  `mix credo --strict` (ExSlop), `mix compile --warnings-as-errors`.
