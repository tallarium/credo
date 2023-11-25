# (Tallarium) Credo

Custom Elixir rules for the [Credo](https://github.com/rrrene/credo/) static code analysis tool.

## Rules

The current rules are listed below:

* `TallariumCredo.Checks.DefinitionOrder` - functions should be ordered in a top-down fashion.
* `TallariumCredo.Checks.Destructure` - encourage a consistent use of [Destructure](https://hexdocs.pm/destructure/Destructure.html)
* `TallariumCredo.Checks.EctoOnlyMacroSyntax` - permit only the use of [the macro syntax](https://hexdocs.pm/ecto/Ecto.Query.html#module-macro-api) from the [Ecto.Query](https://hexdocs.pm/ecto/Ecto.Query.html) module.
* `TallariumCredo.Checks.NoRuntimeAccess` - disallows runtime access to the specifid modules.
* `TallariumCredo.Checks.NoSpecParameterNames` - disallows the use of parameter names in the spec.

## Releases

1. Update the `:version` field in `mix.exs`
2. Commit, tag and push the change as a separate branch
3. Publish the package.
