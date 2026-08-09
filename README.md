# rext_demo

Proof-of-concept app for [rext](../rext) — mob's desktop sibling — and the proof
vehicle for the release + installer pipeline (`mix rext.release` /
`mix rext.installer` in [rext_dev](../rext_dev)).

Two windows that stay in sync purely by BEAM message passing, showing the
desktop paradigm: an app is *several* windows at once, each its own supervised
process.

- **Counter** (`main`) owns the count; `+` / `−` / `Reset` buttons mutate it.
- **Mirror** (`mirror`) displays the count it receives — every counter change
  sends `{:sync_count, n}` to the mirror process, which re-renders. No shared
  state, no navigation stack: two processes talking.

Generated with `mix rext.new` and extended.

## Run it from source (dev loop)

```bash
# from a checkout with rext / rext_dev as siblings, as your normal login user
mix deps.get
mix rext.run            # builds the renderer if needed, opens the window
mix rext.connect        # drive from IEx / an agent (separate terminal)
```

`Rext.boot/1` runs from `RextDemo.Application.start/2`, so windows open the
moment the app starts — `mix rext.run`, `mix run`, `iex -S mix`, or a release,
all boot the same way. `mix rext.run` additionally builds the native renderer on
first use (no separate build step) and launches a renderer for the app's
**primary window** (`main`, the counter). One renderer draws one window — a
multi-window app runs one renderer per window; the mirror's state is still
observable over dist.

> On macOS, run as your normal user, **not** `sudo`/root — the WindowServer is
> per-user, and the renderer refuses to start as root (it would otherwise crash
> in `NSApplication` init).

Or drive it directly over Erlang distribution — the agent workflow, no renderer
needed:

```elixir
n = :"rext_demo_app@127.0.0.1"
Node.connect(n)
Rext.Test.assigns(n, "main")    #=> %{count: 0}
Rext.Test.click(n, :inc, "main")
Rext.Test.assigns(n, "mirror")  #=> %{count: 1}   # synced across windows
```

## Build a self-contained release (Windows)

```bash
mix rext.release
_build/prod/rel/rext_demo/bin/run.bat
```

Produces a `mix release` (bundled ERTS — no separate Erlang install needed on
the target machine) plus a self-contained WinForms renderer (bundled .NET — no
separate .NET install needed either), tied together by a launcher that starts
the release, waits for the bridge, shows the window, and stops the release
again when the window closes. See `../rext_dev/lib/mix/tasks/rext.release.ex`
for exactly what it produces and its current known limitation (fixed bridge
port, so only one instance at a time).

Verified end-to-end: `run.bat` boots the packaged release cold (no `mix run`,
no source tree involved beyond the packaged output), renders the native
window, and a click driven over Erlang distribution (`Rext.Test.click/2`)
updates it live.

## Build a real installer (Windows)

```bash
mix rext.installer
_build/prod/installer/rext_demo-<version>-setup.exe
```

Wraps the same release + renderer + launcher in an Inno Setup installer:
Start Menu shortcut, optional desktop shortcut, proper "Apps & Features"
registration, and an uninstaller that stops the release before removing
files. Requires `choco install innosetup` (shells out to `ISCC.exe`, doesn't
reimplement it). See `../rext_dev/lib/mix/tasks/rext.installer.ex`.

Verified end-to-end, silently, both directions: `/VERYSILENT` install lands
the app in `Program Files` with a working Start Menu shortcut, the installed
app boots and renders exactly like the raw release does; `/VERYSILENT`
uninstall — run *while the app was still running* — cleanly stopped the
release (which self-terminates the renderer once its bridge connection
drops) and removed every file and shortcut, no orphaned processes.

This is the *cold* path only (new installs, or updates touching native code —
the renderer, the NIF, an ERTS bump). Pure-BEAM-code hot updates are a
separate, not-yet-built mechanism; see `../rext/PLAN.md`'s "Distribution"
section.

## Verified

`mix test` proves the cross-window sync headlessly; a live dist run confirms it
end-to-end (`+`×3 on the counter → counter and mirror both read 3).

> The socket renderer currently displays a single window; multi-window rendering
> is a follow-up. The multi-window *logic* is real and fully drivable via
> `Rext.Test`.

## Why this repo exists

1. Demonstrate the desktop paradigm — cross-window state as message passing
   between processes.
2. Exercise `mix rext.new`'s generator template end-to-end (not just its files —
   whether the generated app actually boots and runs).
3. Serve as the test subject for `mix rext.release`/`mix rext.installer`'s
   packaging pipeline, which needs a real app with a real window to publish,
   install, and launch.

See `CLAUDE.md` for the framework bugs this surfaced.
