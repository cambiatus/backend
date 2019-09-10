defmodule BeSpiral.Commune.SaleHistory do
  @moduledoc """
  This module representes the a Sale History data structure, used to query and change the database
  """

  use Ecto.Schema
  # import Ecto.Changeset
  alias BeSpiral.{
    Accounts.User,
    Commune.Community,
    Commune.Sale
  }

  @type t :: %__MODULE__{}

  schema "sale_history" do
    field(:amount, :float)
    field(:units, :integer)

    belongs_to(:community, Community, references: :symbol, type: :string)
    belongs_to(:sale, Sale)
    belongs_to(:from, User, references: :account, type: :string)
    belongs_to(:to, User, references: :account, type: :string)
  end
end
