defmodule TallariumCredo.Checks.NoRuntimeAccess do
  @moduledoc """
  Disallows runtime access to the specified modules.
  """

  use Credo.Check,
    base_priority: :high,
    category: :warning,
    explanations: [
      check: """
      Disallows runtime access to the specified modules. This is useful for
      ensuring that modules are only accessed at compile time, for example to
      access module attributes.
      """,
      params: [
        modules: "Modules to disallow access to."
      ]
    ]

  import Destructure

  @default_params [
    modules: []
  ]

  @doc false
  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    disallowed_modules =
      params
      |> Params.get(:modules, __MODULE__)
      |> Enum.map(&module_to_path/1)

    initial_state =
      d(%{
        issue_meta,
        disallowed_modules,
        issues: [],
        in_module_attribute?: false,
        in_dot_access?: false
      })

    d(%{issues}) = Credo.Code.prewalk(source_file, &traverse/2, initial_state)

    issues
  end

  defp traverse({:@, _meta, _arguments} = ast, state) do
    enter_with_flag(ast, state, :in_module_attribute?)
  end

  defp traverse({:., _meta, _arguments} = ast, state) do
    enter_with_flag(ast, state, :in_dot_access?)
  end

  defp traverse(
         {:__aliases__, meta, module} = ast,
         d(%{issue_meta, disallowed_modules, issues, in_module_attribute?, in_dot_access?}) =
           state
       ) do
    module_path = if is_list(module), do: module, else: [module]

    # Allow access to the fields of the specified modules, in the expression
    # for a module attribute. This ensures the module itself can't be accessed
    # at runtime.
    safe_access? = in_module_attribute? and in_dot_access?

    new_issues =
      if safe_access? do
        []
      else
        for disallowed_module <- disallowed_modules,
            List.starts_with?(module_path, disallowed_module) do
          issue_for(issue_meta, meta[:line], module_path_to_str(disallowed_module))
        end
      end

    {ast, %{state | issues: new_issues ++ issues}}
  end

  defp traverse(ast, state) do
    {ast, state}
  end

  defp enter_with_flag(ast, state, flag) when is_atom(flag) do
    if state[flag] == false do
      # Do a sub-walk with the flag on
      new_state = Credo.Code.prewalk(ast, &traverse/2, %{state | flag => true})
      # Tell the outer walk not to go down this subtree
      {nil, %{new_state | flag => false}}
    else
      # If the flag is on already, we are already in the sub-walk and should
      # continue as normal
      {ast, state}
    end
  end

  defp issue_for(issue_meta, line_no, trigger) do
    format_issue(issue_meta,
      message: "Runtime access to #{trigger} is not allowed. Use a module attribute.",
      line_no: line_no,
      trigger: trigger
    )
  end

  #

  defp module_to_path(module) when is_atom(module) do
    module
    |> Atom.to_string()
    |> String.split(".")
    |> case do
      ["Elixir" | rest] -> rest
      path -> path
    end
    |> Enum.map(&String.to_atom/1)
  end

  defp module_path_to_str(module) when is_list(module) do
    Enum.join(module, ".")
  end
end
