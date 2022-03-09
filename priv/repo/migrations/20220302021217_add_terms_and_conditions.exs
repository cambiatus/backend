defmodule Cambiatus.Repo.Migrations.AddTermsAndConditions do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add(:latest_accepted_terms, :naive_datetime,
        nil: true,
        comment: "Flag that indicates if the user has accepted the latest terms and conditions"
      )
    end
  end
end
