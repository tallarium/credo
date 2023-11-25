defmodule TallariumCredo.Checks.DestructureTest do
  use Credo.Test.Case

  alias TallariumCredo.Checks.Destructure

  test "warns if destructured keys are two or more in number" do
    """
    defmodule MyModule do
      def my_function(%{a: a, b: b}) do
        IO.puts a
        IO.puts b
      end
    end
    """
    |> to_source_file()
    |> run_check(Destructure)
    |> assert_issue()
  end

  test "does not warn if destructured keys are one in number" do
    """
    defmodule MyModule do
      def my_function(%{a: a}) do
        IO.puts a
      end
    end
    """
    |> to_source_file()
    |> run_check(Destructure)
    |> refute_issues()
  end

  test "does not warn if Destructure is used" do
    """
    defmodule MyModule do
      import Destructure
      def my_function(d(%{a, b})) do
        IO.puts a
        IO.puts b
      end
    end
    """
    |> to_source_file()
    |> run_check(Destructure)
    |> refute_issues()
  end

  test "ignores map definitions" do
    """
    defmodule MyModule do
      def my_function do
        %{a: "1", b: "2"}
      end
    end
    """
    |> to_source_file()
    |> run_check(Destructure)
    |> refute_issues()
  end

  test "ignores functions named identically to the key" do
    """
    defmodule MyModule do
      def my_function do
        %{f: f(), g: g()}
      end

      defp f(_x), do: 1
      defp g(_x), do: 2
    end
    """
    |> to_source_file()
    |> run_check(Destructure)
    |> refute_issues()
  end
end
