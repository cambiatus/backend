defmodule Cambiatus.Repo.Migrations.InitialMigration do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add(:account, :string, primary_key: true)
      add(:name, :string)
      add(:email, :string)
      add(:bio, :string)
      add(:location, :string)
      add(:interests, :string)
      add(:avatar, :string)

      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end

    create table(:communities, primary_key: false) do
      add(:symbol, :string, primary_key: true)
      add(:parent_community_id, references(:communities, column: :symbol, type: :string))
      add(:issuer, :string)
      add(:creator, :string)
      add(:logo, :string)
      add(:name, :string, null: false)
      add(:description, :string, null: false)
      add(:supply, :float, null: false)
      add(:max_supply, :float, null: false)
      add(:min_balance, :float, null: false)
      add(:inviter_reward, :float, null: false)
      add(:invited_reward, :float, null: false)
      add(:allow_subcommunity, :boolean, null: false)
      add(:subcommunity_price, :float)

      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end

    create table(:network) do
      add(:community_id, references(:communities, column: :symbol, type: :string))
      add(:account_id, references(:users, column: :account, type: :string))
      add(:invited_by_id, references(:users, column: :account, type: :string))

      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end

    create table(:shop) do
      add(:community_id, references(:communities, column: :symbol, type: :string))
      add(:title, :string)
      add(:description, :string)
      add(:price, :float)
      add(:rate, :integer)
      add(:image, :string)
      add(:is_buy, :boolean)

      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end

    create table(:shop_ratings) do
      add(:shop_id, references(:shop))
      add(:account_id, references(:users, column: :account, type: :string))
      add(:rating, :integer)

      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end

    create table(:transfers) do
      add(:from_id, references(:users, column: :account, type: :string))
      add(:to_id, references(:users, column: :account, type: :string))
      add(:amount, :float)
      add(:community_id, references(:communities, column: :symbol, type: :string))
      add(:memo, :string)

      add(:created_block, :integer)
      add(:created_tx, :string)
      add(:created_eos_account, :string)
      add(:created_at, :utc_datetime)
    end
  end
end
