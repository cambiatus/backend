IO.puts("Replacing empty strings with null")

import Ecto.Query

alias Cambiatus.Repo
alias Cambiatus.Objectives.{Action, Claim}

fields = %{Action => [:image], Claim => [:proof_photo, :proof_code]}

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
