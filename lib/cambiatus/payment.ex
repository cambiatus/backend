defmodule Cambiatus.Payment do
  alias Cambiatus.Repo
  alias Cambiatus.Accounts.User

  def create_intent(args \\ %{}) do
    Stripe.SetupIntent.create(args)
  end

  def create_customer(%User{} = user) do
    user = Repo.preload(user, [:kyc_data, :address])

    params = %{
      name: user.name,
      description: user.account,
      email: user.email
    }

    Stripe.Customer.create(params)
  end

  def create_checkout() do
    # TODO: Create community options
    params = %{
      payment_method_types: ["card"],
      line_item: [%{}]
    }
  end
end
