import Config

# rext boots this app's windows (see Rext.App).
config :rext, :app, RextDemo

# Bridge port. Ephemeral under test so leftover nodes never collide; a fixed
# port in dev so the renderer knows where to connect. Override per-run from the
# CLI with `mix rext.run --port N` (which wins over this), and note the bridge
# falls back to an ephemeral port if the chosen one is busy.
config :rext, :port, if(config_env() == :test, do: 0, else: 8137)
