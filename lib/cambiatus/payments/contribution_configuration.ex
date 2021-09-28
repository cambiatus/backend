defmodule Cambiatus.Payments.ContributionConfiguration do
  @moduledoc false

  use Ecto.Schema

  import Ecto.Changeset

  alias Cambiatus.Commune.Community

  schema "contribution_configurations" do
    field(:paypal_account, :string)

    field(:accepted_currencies, {:array, Ecto.Enum},
      values: [:USD, :BRL, :CRC, :BTC, :ETH, :EOS],
      default: [:USD]
    )

    field(:thank_you_title, :string)
    field(:thank_you_message, :string)

    timestamps()

    belongs_to(:community, Community, references: :symbol, type: :string)
  end

  @required_fields ~w(community_id accepted_currencies)a
  @optional_fields ~w(paypal_account thank_you_title thank_you_message)a

  @email_regex ~r/^[A-Za-z0-9._%+-+']+@[A-Za-z0-9.-]+\.[A-Za-z]+$/

  def changeset(%__MODULE__{} = config, attrs) do
    config
    |> cast(attrs, @required_fields ++ @optional_fields)
    |> validate_required(@required_fields)
    |> validate_format(:paypal_account, @email_regex)
  end
end
