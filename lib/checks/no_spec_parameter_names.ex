defmodule TallariumCredo.Checks.NoSpecParameterNames do
  @moduledoc """
  Disallows the use of parameter names in the spec.
  """

  use Credo.Check, base_priority: :high, category: :refactoring

  import Destructure

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)
    initial_state = d(%{issue_meta, issues: []})

    d(%{issues}) = Credo.Code.prewalk(source_file, &traverse/2, initial_state)
    issues
  end

  defp traverse({:spec, meta, [{_, _, [{_, _, args} | _]}]} = ast, d(%{issue_meta}) = state)
       when is_list(args) do
    # catch e.g. (a :: integer), where the operator is "::"
    named_parameters = Enum.filter(args, &match?({:"::", _, _}, &1))

    if named_parameters != [] do
      parameter_names = Enum.map(named_parameters, fn {:"::", _, [{name, _, _}, _]} -> name end)

      issues = [
        issue_for(issue_meta, meta[:line], Enum.join(parameter_names, ", ")) | state.issues
      ]

      {ast, %{state | issues: issues}}
    else
      {ast, state}
    end
  end

  defp traverse(ast, state) do
    {ast, state}
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(issue_meta,
      message: "Parameter names are not allowed in the spec.",
      line_no: line_no,
      trigger: trigger
    )
  end
end
