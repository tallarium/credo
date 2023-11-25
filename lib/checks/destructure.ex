defmodule TallariumCredo.Checks.Destructure do
  @moduledoc """
  Encourages the use of Destructure
  """

  use Credo.Check, base_priority: :high, category: :warning

  import Destructure

  @doc false
  @impl true
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    initial_state = d(%{issue_meta, issues: []})

    d(%{issues}) = Credo.Code.prewalk(source_file, &traverse/2, initial_state)
    issues
  end

  defp traverse({:%{}, meta, args} = ast, state) do
    if is_destructure_expression?(args) do
      issues = state.issues ++ [issue_for(state.issue_meta, meta[:line])]
      {ast, %{state | issues: issues}}
    else
      {ast, state}
    end
  end

  defp traverse(ast, state) do
    {ast, state}
  end

  defp is_destructure_expression?(args) do
    Keyword.keyword?(args) && Enum.count(args, &is_destructure_variable?/1) > 1
  end

  defp is_destructure_variable?(arg) do
    case arg do
      {key, {key, _, nil}} -> true
      _ -> false
    end
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "d(%{}) should be used instead of %{}",
      line_no: line_no
    )
  end
end
