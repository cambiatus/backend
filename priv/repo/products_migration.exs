IO.puts("Migrating product data")

alias Cambiatus.Shop.{Product, ProductImage}
alias Cambiatus.Repo

Product
|> Repo.all()
|> Enum.map(fn product ->
  {:ok, product} =
    product
    |> Product.changeset(%{inserted_at: product.created_at, updated_at: product.created_at})
    |> Repo.update()
    IO.puts("migrated")
end)
|> Enum.map(fn product ->
  if is_nil(product) or is_nil(product.image) do
    product
  else
    {:ok, product} =
      %ProductImage{}
      |> ProductImage.changeset(%{uri: product.image, product_id: product.id})
      |> Repo.insert()

    product
  end
end)

IO.puts("✅ Migration done")
