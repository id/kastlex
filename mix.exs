defmodule Kastlex.Mixfile do
  use Mix.Project

  def project do
    [app: :kastlex,
     version: "0.0.1",
     elixir: "~> 1.0",
     elixirc_paths: elixirc_paths(Mix.env),
     compilers: [:phoenix, :gettext] ++ Mix.compilers,
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [mod: {Kastlex, []},
     applications: [:logger, :phoenix, :cowboy, :gettext, :yamerl,
                    :yaml_elixir, :comeonin, :erlzk, :brod, :guardian, :ssl]]
  end

  # Specifies which paths to compile per environment.
  defp elixirc_paths(:test), do: ["lib", "web", "test/support"]
  defp elixirc_paths(_),     do: ["lib", "web"]

  defp deps do
    [{:phoenix, "~> 1.2"},
     {:phoenix_live_reload, "~> 1.0", only: :dev},
     {:gettext, "~> 0.11"},
     {:cowboy, "~> 1.0"},
     {:yaml_elixir, "~> 1.2"},
     {:brod, "~> 2.2.0"},
     {:exrm, "~> 1.0"},
     {:guardian, "~> 0.13.0"},
     {:erlzk, "~> 0.6.3"},
     {:comeonin, "~> 2.5"}
    ]
  end

end
