defmodule TallariumCredo.Checks.NoSpecParameterNamesTest do
  use Credo.Test.Case

  alias TallariumCredo.Checks.NoSpecParameterNames

  test "disallows parameter names in the spec" do
    """
    defmodule Foo do
      @spec foo(bar :: integer, integer) :: integer
      def foo(bar), do: bar
    end
    """
    |> to_source_file()
    |> run_check(NoSpecParameterNames)
    |> assert_issue()
  end

  test "handles zero-arity specs gracefully" do
    """
    defmodule Foo do
      @spec foo() :: integer
      def foo, do: 1
    end
    """
    |> to_source_file()
    |> run_check(NoSpecParameterNames)
    |> refute_issues()
  end
end
