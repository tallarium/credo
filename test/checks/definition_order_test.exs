defmodule TallariumCredo.Checks.DefinitionOrderTest do
  use Credo.Test.Case

  alias TallariumCredo.Checks.DefinitionOrder

  @check_params []

  test "disallows" do
    """
    defmodule Sample do
      def g, do: nil
      def f, do: g()
    end
    """
    |> to_source_file()
    |> run_check(DefinitionOrder, @check_params)
    |> assert_issue(fn issue ->
      assert issue.line_no == 2
      assert issue.trigger == "g"
    end)
  end

  test "allows" do
    """
    defmodule Sample do
      def f, do: g()
      def g, do: nil
    end
    """
    |> to_source_file()
    |> run_check(DefinitionOrder, @check_params)
    |> refute_issues()
  end

  test "allows when in cycle" do
    """
    defmodule Sample do
      def f, do: g()
      def g, do: h()
      def h, do: f()
    end
    """
    |> to_source_file()
    |> run_check(DefinitionOrder, @check_params)
    |> refute_issues()
  end

  test "disallows (once per referand)" do
    """
    defmodule Sample do
      def g do nil end
      def f, do: g()
      def e, do: g()
    end
    """
    |> to_source_file()
    |> run_check(DefinitionOrder, @check_params)
    |> assert_issue(fn issue ->
      assert issue.line_no == 2
      assert issue.trigger == "g"
    end)
  end

  test "disallows (multiple implementation)" do
    """
    defmodule Sample do
      def g(nil), do: nil
      def g(_), do: nil
      def f(nil), do: nil
      def f(_), do: g()
    end
    """
    |> to_source_file()
    |> run_check(DefinitionOrder, @check_params)
    |> assert_issue(fn issue ->
      assert issue.line_no == 2
      assert issue.trigger == "g"
    end)
  end
end
