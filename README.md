# rext_demo

Proof-of-concept app for [rext](../rext) — mob's desktop sibling. Two windows
that stay in sync purely by BEAM message passing, showing the desktop paradigm:
an app is *several* windows at once, each its own supervised process.

- **Counter** (`main`) owns the count; `+` / `−` / `Reset` buttons mutate it.
- **Mirror** (`mirror`) displays the count it receives — every counter change
  sends `{:sync_count, n}` to the mirror process, which re-renders. No shared
  state, no navigation stack: two processes talking.

Generated with `mix rext.new` and extended.

## Run it

```bash
# from a checkout with rext / rext_dev as siblings, as your normal login user
mix deps.get
mix rext.run            # builds the renderer if needed, opens the window
mix rext.connect        # drive from IEx / an agent (separate terminal)
```

`mix rext.run` builds the native renderer on first use (no separate build step),
boots the app, and launches a renderer for the app's **primary window** (`main`,
the counter). One renderer draws one window — a multi-window app runs one
renderer per window; the mirror's state is still observable over dist.

> Run as your normal user, **not** `sudo`/root — the macOS WindowServer is
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

## Verified

`mix test` proves the cross-window sync headlessly; a live dist run confirms it
end-to-end (`+`×3 on the counter → counter and mirror both read 3).

> The socket renderer currently displays a single window; multi-window rendering
> is a follow-up. The multi-window *logic* is real and fully drivable via
> `Rext.Test`.
