defmodule BeSpiral.Factory do
  @moduledoc """
  This module holds functionality to enable us to build data samples for use in testing
  """

  use ExMachina.Ecto, repo: BeSpiral.Repo

  alias BeSpiral.{
    Accounts.User,
    Commune.Action,
    Commune.AvailableSale,
    Commune.Check,
    Commune.Claim,
    Commune.Community,
    Commune.Network,
    Commune.Objective,
    Commune.Sale,
    Commune.Transfer,
    Commune.Validator,
    Notifications.PushSubscription
  }

  def user_factory do
    %User{
      account: sequence(:account, &"u-account-key#{&1}"),
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

  def available_sale_factory do
    %AvailableSale{
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
      units: sequence(:units, &"#{&1}")
    }
  end

  def sale_factory do
    %Sale{
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
      name: sequence(:name, &"shop-name#{&1}"),
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
      created_at: NaiveDateTime.utc_now()
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
      is_completed: sequence(:is_completed, [true, false]),
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
      action: build(:action),
      claimer: build(:user),
      is_verified: sequence(:is_completed, [true, false]),
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:tx, &"c_tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"acc-eos-#{&1}"),
      created_at: NaiveDateTime.utc_now()
    }
  end

  def check_factory do
    %Check{
      claim: build(:claim),
      validator: build(:user),
      is_verified: sequence(:is_completed, [true, false]),
      created_block: sequence(:created_block, &"#{&1}"),
      created_tx: sequence(:tx, &"c_tx-#{&1}"),
      created_eos_account: sequence(:created_eos_account, &"acc-eos-#{&1}"),
      created_at: NaiveDateTime.utc_now()
    }
  end
end
