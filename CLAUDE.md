# rext_demo — Agent Instructions

**Read `../rext/CLAUDE.md` first** — toolchain paths, the transport
architecture, quality gates, the "don't write slop" list all apply here
unchanged. This file covers only what's specific to rext_demo.

## What this is, and isn't

This is `mix rext.new`'s output, unmodified except for the two fixes below —
not a hand-authored app. It exists to give `mix rext.release`
(`../rext_dev/lib/mix/tasks/rext.release.ex`) and the generator
(`../rext_new/lib/mix/tasks/rext.new.ex`) a real app to run against, since both
need something that actually boots a window to be worth testing.

**Naming note:** `../rext/CLAUDE.md`'s repo topology table lists a `rext_demo`
as a *sibling, multi-window* proof-of-concept — a separate, more deliberate
demo than this one. This repo is single-window (whatever `rext_new`
generates) and isn't currently a git repo (no `.git`, no remote) — it was
generated locally as a throwaway test subject. If this becomes the canonical
`rext_demo`, it should grow a second window (the multi-window story is the
whole point of "another view is another window" on desktop) and get git-inited
with a remote; if a separate, already-multi-window `rext_demo` exists
elsewhere, rename this one to avoid confusion.

## Two framework bugs this surfaced

Building the release pipeline against this app caught two real bugs, fixed
upstream (not here — this app just regenerate-and-rebuilds clean once you pull
the fixes into `../rext`, `../rext_dev`, `../rext_new`):

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

If you regenerate this app from a stale `rext_new`/`rext_dev`/`rext`, you'll
hit both again.

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

## Known limitation to fix before this is a real release story

`mix rext.release`'s launcher pins `REXT_PORT` to a fixed port (8137) rather
than reading back the bridge's actual (possibly fallen-back) port, so only one
instance can run at a time. A port-file handshake — the release writes its
resolved port to a well-known file at boot, the launcher reads it before
launching the renderer — removes this. Not yet built.
