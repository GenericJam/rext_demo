import Config

# rect boots this app's windows (see Rect.App).
config :rect, :app, RectDemo

# Bridge port. Ephemeral under test so leftover nodes never collide; a fixed
# port in dev so the renderer knows where to connect. Override per-run from the
# CLI with `mix rect.run --port N` (which wins over this), and note the bridge
# falls back to an ephemeral port if the chosen one is busy.
config :rect, :port, if(config_env() == :test, do: 0, else: 8137)
