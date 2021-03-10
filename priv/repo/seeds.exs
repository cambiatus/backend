IO.puts("Running Seeds...")

# Insert Cambiatus user
data = %{account: "cambiatus123", name: "cambiatus", email: "test@gmail.com"}
changeset = Cambiatus.Accounts.User.changeset(%Cambiatus.Accounts.User{}, data)
{:ok, _} = Cambiatus.Repo.insert(changeset)

IO.puts("Seeding done.")
