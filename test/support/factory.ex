defmodule Cambiatus.Factory do
  @moduledoc """
  This module holds functionality to enable us to build data samples for use in testing
  """

  use ExMachina.Ecto, repo: Cambiatus.Repo

  import Ecto.Query

  alias Cambiatus.{
    Accounts.User,
    Auth.Invitation,
    Commune.Action,
    Commune.Check,
    Commune.Community,
    Commune.Claim,
    Commune.Network,
    Commune.Subdomain,
    Repo,
    Commune.Mint,
    Commune.Objective,
    Shop.Product,
    Commune.Transfer,
    Commune.Validator,
    Kyc.KycData,
    Kyc.Address,
    Kyc.Country,
    Kyc.State,
    Kyc.City,
    Kyc.Neighborhood,
    Notifications.NotificationHistory,
    Notifications.PushSubscription
  }

  def user_factory do
    %User{
      account: 1..12 |> Enum.map(fn _ -> Faker.Util.lower_letter() end) |> Enum.join(),
      name: sequence(:name, &"u-name#{&1}"),
      email: sequence(:email, &"mail#{&1}@company#{&1}.com"),
      bio: sequence(:bio, &"my bio  is so awesome I put a number in it #{&1}"),
      location: sequence(:location, &"some loc #{&1}"),
      interests: sequence(:interests, &"playing-#{&1}, coding-#{&1}, testing-#{&1}"),
      avatar: sequence(:avatar, &"ava-#{&1}"),
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:created_tx, &"tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"eos-acc-#{&1}")
    }
  end

  def push_subscription_factory do
    %PushSubscription{
      endpoint: sequence(:endpoint, &"Endpoint #{&1}: "),
      auth_key: sequence(:auth_key, &"Auth Key #{&1}: "),
      p_key: sequence(:p_key, &"P256 key #{&1}: "),
      account: build(:user)
    }
  end

  def transfer_factory do
    %Transfer{
      from: build(:user),
      to: build(:user),
      amount: sequence(:amount, &"#{&1}"),
      memo: sequence(:memo, &"the memo is - #{&1}"),
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:created_tx, &"created-tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"created-eos-acc-#{&1}"),
      created_at: NaiveDateTime.utc_now()
    }
  end

  def product_factory do
    %Product{
      creator: build(:user),
      community: build(:community),
      title: sequence(:title, &"title-#{&1}"),
      description: sequence(:description, &"desc-#{&1}"),
      price: sequence(:price, &"#{&1}.544"),
      image: sequence(:image, &"image-#{&1}"),
      track_stock: true,
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:tx, &"c_tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"acc-eos-#{&1}"),
      created_at: NaiveDateTime.utc_now(),
      units: sequence(:units, &"#{&1}"),
      is_deleted: false,
      deleted_at: NaiveDateTime.utc_now()
    }
  end

  def network_factory do
    %Network{
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:tx, &"c_tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"acc-eos-#{&1}"),
      created_at: NaiveDateTime.utc_now(),
      community: build(:community),
      account: build(:user),
      invited_by: build(:user)
    }
  end

  def community_factory do
    %Community{
      symbol: sequence(:symbol, &"symbol-#{&1}"),
      creator: sequence(:creator, &"creator-#{&1}"),
      logo: sequence(:logo, &"logo-#{&1}"),
      name: sequence(:name, &"community-name#{&1}"),
      description: sequence(:description, &"desc-#{&1}"),
      inviter_reward: sequence(:mix_balance, &"#{&1}.78"),
      invited_reward: sequence(:mix_balance, &"#{&1}.78"),
      issuer: sequence(:issuer, &"issuer-#{&1}"),
      supply: sequence(:supply, &"#{&1}.767"),
      max_supply: sequence(:max_supply, &"#{&1}.9809"),
      min_balance: sequence(:mix_balance, &"#{&1}.87"),
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:tx, &"c_tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"acc-eos-#{&1}"),
      created_at: NaiveDateTime.utc_now()
    }
  end

  def objective_factory do
    %Objective{
      description: sequence(:community_objective_description, &"desc-#{&1}"),
      creator: build(:user),
      community: build(:community),
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:tx, &"c_tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"acc-eos-#{&1}"),
      created_at: NaiveDateTime.add(NaiveDateTime.utc_now(), sequence(:numeric, & &1))
    }
  end

  def action_factory do
    %Action{
      objective: build(:objective),
      creator: build(:user),
      reward: 1.45,
      description: "general description",
      deadline: NaiveDateTime.utc_now(),
      usages: 10,
      usages_left: 5,
      verifications: 10,
      verification_type: sequence(:verification_type, ["automatic", "claimable"]),
      is_completed: false,
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:tx, &"c_tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"acc-eos-#{&1}"),
      created_at: NaiveDateTime.utc_now()
    }
  end

  def validator_factory do
    %Validator{
      validator: build(:user),
      action: build(:action),
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:tx, &"c_tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"acc-eos-#{&1}"),
      created_at: NaiveDateTime.utc_now()
    }
  end

  def claim_factory do
    %Claim{
      status: "pending",
      action: build(:action),
      claimer: build(:user),
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:tx, &"c_tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"acc-eos-#{&1}"),
      created_at: NaiveDateTime.utc_now()
    }
  end

  def check_factory do
    %Check{
      is_verified: false,
      claim: build(:claim),
      validator: build(:validator),
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:tx, &"c_tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"acc-eos-#{&1}"),
      created_at: NaiveDateTime.utc_now()
    }
  end

  def notification_history_factory do
    %NotificationHistory{
      recipient: build(:user),
      type:
        sequence(:notification_type, ["sale", "transfer", "sale_history", "claim", "verification"]),
      payload: "some rad json",
      is_read: false
    }
  end

  def mint_factory do
    %Mint{
      memo: "some rad memo",
      quantity: sequence(:quantity, &"#{&1}.5687"),
      community: build(:community),
      to: build(:user),
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:tx, &"c_tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"acc-eos-#{&1}"),
      created_at: NaiveDateTime.utc_now()
    }
  end

  def invitation_factory do
    %Invitation{
      community: build(:community),
      creator: build(:user)
    }
  end

  def kyc_data_factory do
    user_type = sequence(:user_type, ["juridical", "natural"])

    {document_type, document} =
      case user_type do
        "natural" ->
          document_type =
            sequence(:natural_document_type, ["cedula_de_identidad", "dimex", "nite"])

          document =
            case document_type do
              "cedula_de_identidad" ->
                "912345678"

              "dimex" ->
                "91234567890"

              "nite" ->
                "8123456789"
            end

          {document_type, document}

        "juridical" ->
          document_type = sequence(:juridical_document_type, ["gran_empresa", "mipyme"])

          document =
            case document_type do
              "gran_empresa" ->
                "1-111-111111"

              "mipyme" ->
                "1-111-111111"
            end

          {document_type, document}
      end

    %KycData{
      account: build(:user),
      user_type: user_type,
      country: Repo.one(Country),
      document: document,
      document_type: document_type,
      phone: "8601-2101"
    }
  end

  def address_factory() do
    country = Repo.one(Country)
    province = build(:existing_state, %{country: country})
    canton = build(:existing_city, %{state: province})
    district = build(:existing_neighborhood, %{city: canton})

    %Address{
      account: build(:user),
      street: sequence(:street, &"#{&1}th Lorem Srt"),
      neighborhood_id: district.id,
      city_id: canton.id,
      state_id: province.id,
      country_id: country.id,
      zip: Enum.random(Address.costa_rica_zip_codes()),
      number: ""
    }
  end

  def country_factory() do
    %Country{
      name: sequence(:country, &"Country number #{&1}")
    }
  end

  def state_factory() do
    %State{
      name: sequence(:name, &"State #{&1}")
    }
  end

  def city_factory() do
    %City{
      name: sequence(:name, &"City #{&1}")
    }
  end

  def neighborhood_factory() do
    %Neighborhood{name: sequence(:name, &"Nice Neighborhood #{&1}")}
  end

  def existing_state_factory(%{country: country}) do
    query = from(s in State, where: s.country_id == ^country.id)

    query
    |> Repo.all()
    |> Enum.random()
  end

  def existing_city_factory(%{state: s}) do
    query = from(c in City, where: c.state_id == ^s.id)

    query
    |> Repo.all()
    |> Enum.random()
  end

  def existing_neighborhood_factory(%{city: city}) do
    query = from(n in Neighborhood, where: n.city_id == ^city.id)

    query
    |> Repo.all()
    |> Enum.random()
  end

  def subdomain_factory() do
    %Subdomain{
      name: sequence(:name, &"#{&1}.cambiatus.io")
    }
  end
end
