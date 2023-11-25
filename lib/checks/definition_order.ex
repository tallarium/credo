defmodule TallariumCredo.Checks.DefinitionOrder do
  @moduledoc """
  Check that functions are generally ordered in a top-down fashion
  """

  use Credo.Check,
    base_priority: :high,
    category: :refactor,
    explanations: [
      check: """
      Functions should be ordered in a top-down fashion, so that the file reads
      from top to bottom.
      """
    ]

  import Destructure
  alias Credo.Code.Module

  @explanation [
    check: @moduledoc,
    params: []
  ]

  @default_params []

  @definition_types %{
    def: :fn,
    defp: :fn
  }
  @definition_words Map.keys(@definition_types)

  def run(source_file, params \\ []) do
    issue_meta = IssueMeta.for(source_file, params)

    Credo.Code.prewalk(
      source_file,
      &traverse(&1, &2, issue_meta)
    )
  end

  defp traverse(
         {:defmodule, _meta, _arguments} = ast,
         issues,
         issue_meta
       ) do
    definitions = Credo.Code.prewalk(ast, &traverse_definitions/2, %{})

    new_issues =
      definitions
      |> check_references()
      |> Enum.map(&issue_for_infraction(&1, issue_meta, definitions))

    {ast, issues ++ new_issues}
  end

  defp traverse(ast, issues, _issue_meta), do: {ast, issues}

  #

  defp traverse_definitions({definition_word, meta, [_, [{:do, body} | _]]} = ast, definitions)
       when definition_word in @definition_words do
    type = @definition_types[definition_word]
    name = Module.def_name(ast)
    references = Credo.Code.prewalk(body, &traverse_body/2, [])

    definitions =
      definitions
      |> Map.put_new({type, name}, d(%{references, meta}))
      |> add_references({type, name}, references)

    {ast, definitions}
  end

  defp traverse_definitions(ast, definitions), do: {ast, definitions}

  #

  defp traverse_body({obj, _meta, args} = ast, references) when not is_nil(args) do
    {ast, [{:fn, obj} | references]}
  end

  defp traverse_body(ast, references), do: {ast, references}

  #

  defp check_references(definitions) do
    expanded_definitions = definitions |> expand_transitive_references()

    definitions
    |> referrers()
    |> Enum.filter(
      &(referand_defined?(&1, expanded_definitions) and
          invalid_reference?(&1, expanded_definitions))
    )
    |> group_by_referand()
  end

  defp referand_defined?({referand, _}, definitions) do
    Map.has_key?(definitions, referand)
  end

  defp invalid_reference?({referand, referrer}, definitions) do
    cyclical = referrer in definitions[referand].references

    not cyclical and
      definition_line(referand, definitions) < definition_line(referrer, definitions)
  end

  #

  defp issue_for_infraction({referand, referrers}, issue_meta, definitions) do
    referrers = referrers |> Enum.map_join(", ", &name/1)

    format_issue(issue_meta,
      message: "#{name(referand)} should appear after #{referrers}, which references it",
      line_no: definition_line(referand, definitions),
      trigger: "#{name(referand)}"
    )
  end

  #

  defp expand_transitive_references(definitions) do
    referrers = definitions |> referrers() |> group_by_referand() |> Enum.into(%{})
    all_objects = Map.keys(definitions)
    definitions |> expand_objects(all_objects, referrers)
  end

  def expand_objects(definitions, objects, referrers) do
    expanded_definitions =
      for object <- objects, reduce: definitions do
        definitions -> definitions |> expand_from_object(object, referrers)
      end

    expanded_objects =
      expanded_definitions
      |> Enum.filter(fn {object, expanded_definition} ->
        expanded_definition != definitions[object]
      end)

    if expanded_objects |> length() != 0,
      do: expanded_definitions |> expand_objects(expanded_objects, referrers),
      else: expanded_definitions
  end

  def expand_from_object(definitions, object, referrers) do
    # Add all its references to those that reference it
    for referrer <- referrers[object] || [], reduce: definitions do
      definitions -> definitions |> add_references(referrer, definitions[object].references)
    end
  end

  #

  defp add_references(definitions, definition, new_references) do
    Map.update!(
      definitions,
      definition,
      fn obj -> Map.update!(obj, :references, &Enum.uniq(new_references ++ &1)) end
    )
  end

  def referrers(definitions) do
    for {referrer, d(%{references})} <- definitions, referand <- references do
      {referand, referrer}
    end
  end

  def group_by_referand(referrers) do
    referrers
    |> Enum.group_by(
      fn {referand, _} -> referand end,
      fn {_, referrer} -> referrer end
    )
  end

  defp definition_line(definition, definitions) do
    definitions[definition].meta[:line]
  end

  def name({_definition_type, name}), do: name
end
