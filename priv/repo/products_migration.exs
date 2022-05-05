IO.puts("Migrating product data")

alias Cambiatus.Shop.{Product, ProductImage}
alias Cambiatus.Repo

Product
|> Repo.all()
|> Enum.map(fn product ->
  {:ok, _} =
    product
    |> Product.changeset(
      %{inserted_at: product.created_at, updated_at: product.created_at},
      :update
    )
    |> Repo.update()

  IO.puts("🗓 Product ##{product.id} dates migrated")

  product
end)
|> Enum.map(fn product ->
  if is_nil(product) or is_nil(product.image) or product.image == "" do
    product
    IO.puts("🚫 Product with ID ##{product.id} has no images")
  else
    {:ok, product} =
      %ProductImage{}
      |> ProductImage.changeset(%{uri: product.image, product_id: product.id})
      |> Repo.insert()

    IO.puts("🖼 Product ##{product.id} images migrated")
    product
  end
end)

IO.puts("✅ Migration done")
