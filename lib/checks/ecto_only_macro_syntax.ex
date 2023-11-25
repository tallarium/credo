defmodule TallariumCredo.Checks.EctoOnlyMacroSyntax do
  @moduledoc """
  Permit only the use of the macro syntax from the Ecto.Query module
  """

  use Credo.Check,
    base_priority: :high,
    category: :consistency,
    explanations: [
      check: """
      Ecto.Query provides two syntaxes for building queries: the macro syntax and
      the keyword syntax. The macro syntax is preferred as it is more flexible.
      """
    ]

  import Destructure

  @doc false
  @impl true
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    initial_state = d(%{issue_meta, has_ecto_query_import?: false, issues: []})

    d(%{issues}) = Credo.Code.prewalk(source_file, &traverse/2, initial_state)
    issues
  end

  defp traverse(
         {:import, _meta, [{:__aliases__, _aliases_meta, [:Ecto, :Query]}]} = ast,
         state
       ) do
    {ast, %{state | has_ecto_query_import?: true}}
  end

  defp traverse(
         {:from, meta, [{:in, _meta, _children} | _]} = ast,
         d(%{has_ecto_query_import?}) = state
       )
       when has_ecto_query_import? do
    issues = state.issues ++ [issue_for(state.issue_meta, meta[:line])]
    {ast, %{state | issues: issues}}
  end

  defp traverse(ast, state) do
    {ast, state}
  end

  defp issue_for(issue_meta, line_no) do
    format_issue(issue_meta,
      message: "Only the macro syntax from Ecto.Query is permitted",
      line_no: line_no
    )
  end
end
