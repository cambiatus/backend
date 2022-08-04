IO.puts("""
Replace the following empty string ingested by the event-source with nil:
  Objectives.Action.photo_proof_instructions
  Objectives.Action.image
  Objectives.Claim.proof_photo
  Objectives.Claim.proof_code
  Commune.Community.logo
  Commune.Community.description
  Commune.Community.website
  Commune.Transfer.memo
  Shop.Product.description

""")


import Ecto.Query

alias Cambiatus.Repo
alias Cambiatus.Objectives.{Action, Claim}
alias Cambiatus.Commune.{Community, Transfer}
alias Cambiatus.Shop.Product

fields = %{
  Action => [:photo_proof_instructions, :image],
  Claim => [:proof_photo, :proof_code],
  Community => [:logo, :description, :website],
  Product => [:description],
  Transfer => [:memo]
}

# Iterate over the schemas defined as the keys in the field map
# Then iterate over the fields defined as the values in the fields map
# And for each field find entries with empty strings and update them as nil

Enum.each(Map.keys(fields), fn schema ->
  fields
  |> Map.get(schema)
  |> Enum.each(fn field ->
    schema
    |> where([s], field(s, ^field) == "")
    |> update([s], set: [{^field, nil}])
    |> Repo.update_all([])
    |> case do
      {0, nil} ->
        IO.puts("No values were changed for #{schema}.#{field}")

      {changes_num, _} ->
        IO.puts("#{changes_num} changes were made to #{schema}.#{field}")
    end
  end)
end)
