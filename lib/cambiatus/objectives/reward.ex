defmodule Cambiatus.Objectives.Reward do
  @moduledoc """
  Ecto Model to represent rewards or grants given by community leaders to specific users, based on an action of type `automatic`
  """

  use Ecto.Schema
  @type t :: %__MODULE__{}

  alias Cambiatus.Objectives.Action

  schema "rewards" do
    belongs_to(:action, Action)
    belongs_to(:receiver, User, references: :account, type: :string)

    timestamps()
  end
end
