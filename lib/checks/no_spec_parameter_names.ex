defmodule TallariumCredo.Checks.NoSpecParameterNames do
  @moduledoc """
  Disallows the use of parameter names in the spec.
  """

  use Credo.Check, base_priority: :high, category: :refactoring

  import Destructure

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    d(%{issues}) =
      Credo.Code.prewalk(source_file, fn ast, state -> traverse(ast, state, issue_meta) end, %{
        issues: []
      })

    issues
  end

  defp traverse({:spec, meta, [{_, _, [{_, _, args} | _]}]} = ast, state, issue_meta)
       when is_list(args) do
    # catch e.g. (a :: integer), where the operator is "::"
    parameter_names = for {:"::", _, [{name, _, _}, _]} <- args, do: name

    if parameter_names != [] do
      issues = [
        issue_for(issue_meta, meta[:line], Enum.join(parameter_names, ", ")) | state.issues
      ]

      {ast, %{state | issues: issues}}
    else
      {ast, state}
    end
  end

  defp traverse(ast, state, _issue_meta) do
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
