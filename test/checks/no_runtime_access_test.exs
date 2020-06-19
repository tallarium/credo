defmodule TallariumCredo.Checks.NoRuntimeAccessTest do
  use Credo.Test.Case

  alias TallariumCredo.Checks.NoRuntimeAccess

  @check_params modules: [Mix.Project]

  test "disallows runtime access to specified module" do
    """
    defmodule Sample do
      def mix_project do
        Mix.Project
      end
    end
    """
    |> to_source_file()
    |> run_check(NoRuntimeAccess, @check_params)
    |> assert_issue(fn issue -> assert issue.trigger == "Mix.Project" end)
  end

  test "disallows access in module attribute expression" do
    """
    defmodule Sample do
      @mix_project Mix.Project
    end
    """
    |> to_source_file()
    |> run_check(NoRuntimeAccess, @check_params)
    |> assert_issue(fn issue -> assert issue.trigger == "Mix.Project" end)
  end

  test "allows access to fields in module attribute expression" do
    """
    defmodule Sample do
      @mix_project_config Mix.Project.config
    end
    """
    |> to_source_file()
    |> run_check(NoRuntimeAccess, @check_params)
    |> refute_issues()
  end

  test "disallows access after safe access" do
    """
    defmodule Sample do
      @mix_project_config Mix.Project.config

      @mix_project Mix.Project

      def mix_project do
        Mix.Project.config
      end
    end
    """
    |> to_source_file()
    |> run_check(NoRuntimeAccess, @check_params)
    |> assert_issues(fn issues ->
      assert length(issues) == 2
      assert issues |> Enum.all?(fn issue -> issue.trigger == "Mix.Project" end)
    end)
  end
end
