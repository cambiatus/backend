IO.puts("Running Seeds...")

# Insert BeSpiral user
data = %{account: "bespiral"}
changeset = BeSpiral.Accounts.User.changeset(%BeSpiral.Accounts.User{}, data)
{:ok, _} = BeSpiral.Repo.insert(changeset)

IO.puts("Seeding done.")
