defmodule Ash.Resource.Transformers.DefaultPrimaryKey do
  @moduledoc """
  Creates the default primary key if one applies.

  Currently, the only resources that get a default primary key are embedded resources.
  The reason for this is that resources must have a primary key, and embedded resources
  actually make sense without one. But this is simulated with a private uuid primary key.
  """
  use Spark.Dsl.Transformer

  alias Spark.Dsl.Transformer
  alias Spark.Error.DslError

  @extension Ash.Resource.Dsl

  def transform(dsl_state) do
    if Transformer.get_persisted(dsl_state, :embedded?) do
      has_pkey? =
        dsl_state
        |> Transformer.get_entities([:attributes])
        |> Enum.any?(& &1.primary_key?)

      if has_pkey? do
        {:ok, dsl_state}
      else
        case Transformer.build_entity(@extension, [:attributes], :uuid_primary_key,
               name: :autogenerated_id,
               private?: true
             ) do
          {:ok, attribute} ->
            {:ok, Transformer.add_entity(dsl_state, [:attributes], attribute)}

          {:error, error} ->
            {:error,
             DslError.exception(
               message:
                 "Could not create default primary key for embedded resource: #{inspect(error)}",
               path: [:attributes, :autogenerated_id]
             )}
        end
      end
    else
      {:ok, dsl_state}
    end
  end

  def after?(Ash.Resource.Transformers.BelongsToSourceField), do: true
  def after?(_), do: false
end
