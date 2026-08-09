defmodule RextDemo.Application do
  @moduledoc false
  use Application

  @impl true
  def start(_type, _args) do
    # Rext.boot/1 belongs here, not in dev tooling: RextDev.Boot is
    # `runtime: false`, so a release that relied on it would open no windows
    # at all. See CLAUDE.md's "framework bugs this surfaced".
    with {:ok, pid} <-
           Supervisor.start_link([], strategy: :one_for_one, name: RextDemo.Supervisor) do
      Rext.boot(RextDemo)
      {:ok, pid}
    end
  end
end

defmodule RextDemo do
  @moduledoc """
  Proof-of-concept rext app: two windows that stay in sync purely by BEAM
  message passing.

  This is the desktop paradigm made concrete — an app is *several* windows at
  once, and each window is its own supervised process. The `Counter` window owns
  the state and, on every change, sends it to the `Mirror` window; the mirror
  just displays what it receives. No shared mutable state, no navigation stack —
  two processes talking, which is exactly what OTP is good at.
  """
  use Rext.App

  @impl true
  def windows do
    [
      {RextDemo.CounterWindow, id: "main", title: "Counter", size: {420, 320}},
      {RextDemo.MirrorWindow, id: "mirror", title: "Mirror", size: {420, 200}}
    ]
  end
end
