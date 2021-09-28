defmodule Cambiatus.Repo.Migrations.ContributionConfigurations do
  use Ecto.Migration

  def change do
    create table(:contribution_configurations) do
      add(:community_id, references(:communities, column: :symbol, type: :string), null: false)

      add(:accepted_currencies, {:array, :currency},
        default: ["USD"],
        null: false,
        comment: "Accepted currencies"
      )

      add(:paypal_account, :string)

      add(:thank_you_title, :string)
      add(:thank_you_message, :string)

      timestamps()
    end

    alter table(:communities) do
      add(:contribution_configuration_id, references(:contribution_configurations))
    end
  end
end
