defmodule BeSpiral.Repo.Migrations.UpdateCommunityExpiry do
  use Ecto.Migration

  def change do
    alter table(:communities) do
      remove(:parent_community_id)
      remove(:allow_subcommunity)
      remove(:subcommunity_price)

      # Now we can create the token config after the community
      # so some stuff isn't required anymore
      modify(:supply, :float, null: true)
      modify(:max_supply, :float, null: true)
      modify(:min_balance, :float, null: true)

      add(:type, :string)
    end

    create table(:community_expiry_options, primary_key: false) do
      add(:community_id, references(:communities, column: :symbol, type: :string))
      add(:expiration_period, :integer)
      add(:renovation_amount, :float)
    end
  end
end
