# rext_demo — Agent Instructions

Proof-of-concept app for [rext](../rext). **Read `../rext/CLAUDE.md` first** for
shared conventions (toolchain paths, transport architecture, quality gates, the
"don't write slop" list) — they apply here unchanged. This file covers only
what's specific to the demo.

## What it demonstrates

The desktop paradigm: two windows (`CounterWindow` id `"main"`,
`MirrorWindow` id `"mirror"`), each a supervised process, kept in sync by plain
`send/2`. `CounterWindow.notify_mirror/1` pushes the count to
`Rext.Window.via("mirror")` on every change; the mirror reacts in `handle_info`.
This is the intended shape for cross-window state on desktop — message passing
between processes, not a shared store or a nav stack.

It doubles as the **test subject for the release/installer pipeline** — both
`mix rext.release` and `mix rext.installer` need a real app with a real window
to package, publish, install, and launch.

> **History:** this repo had two independent lineages that were merged on
> 2026-08-08 — a local multi-window demo (never pushed) and a single-window
> `mix rext.new` output pushed to `github.com/GenericJam/rext_demo` while
> building the release pipeline. The merge keeps the multi-window app and the
> release/installer knowledge. `../rext/CLAUDE.md`'s topology table lists
> `rext_demo` as the multi-window PoC; that is now unambiguously this repo.

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

## Framework bugs this surfaced

Building the release/installer pipeline against this app caught real bugs,
fixed upstream (not here — this app just regenerate-and-rebuilds clean once
you pull the fixes into `../rext`, `../rext_dev`, `../rext_new`):

1. **Generated apps never opened a window at all.** `Rext.boot/1` used to run
   only from `RextDev.Boot` (`../rext_dev`), which is `only: :dev, runtime:
   false` — absent from any release. Fixed by moving the `Rext.boot/1` call
   into `RextDemo.Application.start/2` itself, so it runs in dev, test, *and*
   a release. See `lib/rext_demo/application.ex`.
2. **`mix release` crashed at boot, on any OS.** The default `RELEASE_MODE=
   embedded` preloads every module at startup, including `rext_nif.erl`'s
   `-on_load` hook, which unconditionally called `erlang:load_nif`. With no
   compiled `.so`/`.dll` present, that's a fatal crash before the app even
   starts — fixed in `../rext/src/rext_nif.erl` to degrade instead of crash
   when the native lib is missing.
3. **The installer shipped stray runtime artifacts.** A local test run leaves
   `release.out.log`/`.err.log` (the launcher's redirected output) and
   possibly `bin/erl_crash.dump` sitting in the release root; `mix
   rext.installer` packages that directory wholesale, so they'd end up in the
   shipped installer. Fixed by `RextDev.Release.clean_stray_artifacts!/1`,
   called at the end of `mix rext.release` — caught by actually running the
   installer end-to-end and looking at what got compressed in, not by reading
   the code.

If you regenerate this app from a stale `rext_new`/`rext_dev`/`rext`, you'll
hit these again.

## Reproducing the release + launcher proof

```bash
mix deps.get
mix rext.release
_build/prod/rel/rext_demo/bin/run.bat
```

Verified working end-to-end on Windows: boots the packaged release cold, shows
the native WinForms window, and a click driven over dist
(`Rext.Test.click(node, :inc)`) updates it live on screen. Close the window and
confirm the whole process tree (renderer, `erl.exe`, the launcher's `cmd`) exits
— that's the shutdown half of the proof, and it's just as load-bearing as the
boot half.

## Reproducing the installer proof

```bash
mix rext.installer
```

Silently install, run, and uninstall (`ISCC.exe`-produced `setup.exe` accepts
`/VERYSILENT /SUPPRESSMSGBOXES /NORESTART`; the uninstaller is `unins000.exe`
in the install dir). Verified: install lands the app in `Program Files` with a
working Start Menu shortcut and the app boots identically to the raw release;
uninstall — run *while the app was still running* — stopped the release
cleanly (the renderer self-exits once its bridge connection drops) and
removed every file and shortcut, no orphaned `erl.exe`/`rext_renderer.exe`.
That "uninstall while running" case is the one worth re-testing after any
change to the launcher or the `[UninstallRun]` stop step — it's the actual
race the safe-uninstall design has to win.

## Known limitation to fix before this is a real release story

`mix rext.release`'s launcher pins `REXT_PORT` to a fixed port (8137) rather
than reading back the bridge's actual (possibly fallen-back) port, so only one
instance can run at a time. A port-file handshake — the release writes its
resolved port to a well-known file at boot, the launcher reads it before
launching the renderer — removes this. Not yet built.

## Notes

- `config :rext, :port` is ephemeral under test, fixed (8137) otherwise.
- Windows must be started before `notify_mirror` can find the mirror; at boot
  the counter's mount notifies only if the mirror is already up (no-op
  otherwise), so window start order is not load-bearing.
- Held to the same gate as the rest of the ecosystem: `mix format`,
  `mix credo --strict` (ExSlop), `mix compile --warnings-as-errors`.
