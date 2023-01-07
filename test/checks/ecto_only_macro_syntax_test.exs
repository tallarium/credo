defmodule TallariumCredo.Checks.EctoOnlyMacroSyntaxTest do
  use Credo.Test.Case

  alias TallariumCredo.Checks.EctoOnlyMacroSyntax

  test "disallows the keyword syntax from Ecto.Query" do
    """
    defmodule MyModule do
      import Ecto.Query

      def query do
        from u in User, where: u.name == "John"
      end
    end
    """
    |> to_source_file()
    |> run_check(EctoOnlyMacroSyntax)
    |> assert_issue()
  end

  test "ignores from statements without the Ecto.Query import" do
    """
    defmodule MyModule do
      def query do
        from u in User, where: u.name == "John"
      end

      defp from(_source, _queryable) do
        :ok
      end
    end
    """
    |> to_source_file()
    |> run_check(EctoOnlyMacroSyntax)
    |> refute_issues()
  end
end
