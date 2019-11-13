defmodule BeSpiral.Commune.Mint do
  @moduledoc """
  Data structure to represent an instance of minted/issued currency
  """

  use Ecto.Schema
  @type t :: %__MODULE__{}

  alias BeSpiral.{
    Accounts.User,
    Commune.Community
  }

  schema "mints" do
    field(:quantity, :float)
    field(:memo, :string)
    belongs_to(:community, Community, references: :symbol, type: :string)
    belongs_to(:to, User, references: :account, type: :string)

    field(:created_block, :integer)
    field(:created_tx, :string)
    field(:created_eos_account, :string)
    field(:created_at, :utc_datetime)
  end
end
