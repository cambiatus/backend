defmodule Cambiatus.Repo.Migrations.NoEmptyStringConstraint do
  use Ecto.Migration

  def change do
    create(constraint("actions", :no_empty_string_on_actions_images, check: "image <> ''"))

    create(
      constraint("actions", :no_empty_string_on_actions_photo_proof_instructions,
        check: "photo_proof_instructions <> ''"
      )
    )

    create(
      constraint("claims", :no_empty_string_on_claims_proof_photo, check: "proof_photo <> ''")
    )

    create(constraint("claims", :no_empty_string_on_claims_proof_code, check: "proof_code <> ''"))

    create(constraint("communities", :no_empty_string_on_communities_logo, check: "logo <> ''"))

    create(
      constraint("communities", :no_empty_string_on_communities_description,
        check: "description <> ''"
      )
    )

    create(
      constraint("communities", :no_empty_string_on_communities_website, check: "website <> ''")
    )

    create(
      constraint("products", :no_empty_string_on_products_description, check: "description <> ''")
    )

    create(constraint("transfers", :no_empty_string_on_transfers_memo, check: "memo <> ''"))
  end
end
