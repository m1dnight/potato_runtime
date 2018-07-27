# Potato

**TODO: Add description**

## Running a Potato Node

To start up a Potato node you need to start the project with a name and a cookie.

```
iex --sname bob --cookie "secret" -S mix
iex --sname alice --cookie "secret" -S mix
```

## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `potato` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:potato, "~> 0.1.0"}
  ]
end
```
