defmodule Cambiatus.Repo.Migrations.ClaimStatusDataAnalysisUpdate do
  use Ecto.Migration

  alias Cambiatus.Repo
  alias Cambiatus.Commune.Claim

  def up do
    # loop on all claims, find if they already got all the checks needed
    Claim
    |> Repo.all()
    |> Enum.map(fn claim ->
      claim = claim |> Repo.preload(:action) |> Repo.preload(:checks)

      # count positive and negative votes
      positive_votes = claim.checks |> Enum.count(& &1.is_verified)
      negative_votes = claim.checks |> Enum.count(&(!&1.is_verified))

      new_status =
        if positive_votes + negative_votes >= claim.action.verifications do
          if positive_votes > negative_votes do
            "approved"
          else
            "rejected"
          end
        else
          "pending"
        end

      claim
      |> Ecto.Changeset.change(status: new_status)
      |> Repo.update()
    end)
  end

  def down do
    Repo.update_all(Claim, set: [status: "pending"])
  end
end
