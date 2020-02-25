defmodule Cambiatus.Eos do
  @moduledoc """
  EOS Wallet and Chain Handler
  """

  @callback netlink(new_user :: binary, inviter :: binary, community :: binary) :: any
  @callback cambiatus_community() :: binary
  @callback cambiatus_account() :: binary

  @eosrpc_wallet Application.get_env(:cambiatus, :eosrpc_wallet)
  @eosrpc_helper Application.get_env(:cambiatus, :eosrpc_helper)

  require Logger

  @spec unlock_wallet :: true
  def unlock_wallet do
    cambiatus_wallet()
    |> @eosrpc_wallet.unlock(cambiatus_wallet_password())
    |> case do
      {:ok, _res} ->
        true

      # wallet already unlocked
      {:error, %{body: %{"error" => %{"code" => 3_120_007}}}} ->
        true

      {:error, error} ->
        Logger.error(error)
        false
    end
  end

  def create_account(%{
        "account" => account_name,
        "ownerKey" => owner_key,
        "activeKey" => active_key
      }) do
    case EOSRPC.Chain.get_account(account_name) do
      {:ok, _} ->
        {:error, "Account already exists"}

      {:error, _} ->
        unlock_wallet()

        cambiatus_acc()
        |> @eosrpc_helper.new_account(account_name, owner_key, active_key)
        |> case do
          {:ok, %{body: %{"transaction_id" => trx_id}}} ->
            {:ok, %{transaction_id: trx_id, account: account_name}}

          {:error, %{body: %{"error" => error}}} ->
            {:error, error}

          unhandled_reply ->
            {:error, unhandled_reply}
        end
    end
  end

  def create_account(%{"ownerKey" => _, "activeKey" => _} = params) do
    params
    |> Map.merge(%{"account" => random_eos_account()})
    |> create_account()
  end

  def netlink(new_user, inviter, community \\ cambiatus_community())

  def netlink(new_user, inviter, community) do
    netlink(%{"new_user" => new_user, "inviter" => inviter, "community" => community})
  end

  @doc """
  This function should be called after signup with eos account link, to insert the user immediately
  under Cambiatus Global community
  """
  @deprecated "Use netlink/3 instead"
  def netlink_cambiatus(new_user),
    do:
      netlink(%{
        "new_user" => new_user,
        "inviter" => cambiatus_acc(),
        "community" => cambiatus_cmm()
      })

  @doc """
  Netlink function should be called for signup on Global Cambiatus community or for each
  community invitation, after the signup process
  """
  @deprecated "Use netlink/3 instead"
  def netlink(%{"new_user" => new_user, "inviter" => inviter, "community" => community} = m)
      when is_map(m) do
    unlock_wallet()

    response =
      @eosrpc_helper.auto_push([
        %{
          account: mcc_contract(),
          authorization: [%{actor: cambiatus_acc(), permission: "active"}],
          data: %{
            cmm_asset: "0 #{community}",
            new_user: new_user,
            inviter: inviter
          },
          name: "netlink"
        }
      ])

    case response do
      {:ok, %{body: %{"transaction_id" => trx_id}}} ->
        %{transaction_id: trx_id}

      {:error, %{body: %{"error" => error}}} ->
        {:error, error}

      unhandled_reply ->
        {:error, unhandled_reply}
    end
  end

  def issue(account, amount, memo) do
    unlock_wallet()

    response =
      @eosrpc_helper.auto_push([
        %{
          account: mcc_contract(),
          authorization: [%{actor: cambiatus_acc(), permission: "active"}],
          data: %{
            to: account,
            quantity: amount,
            memo: memo
          },
          name: "issue"
        }
      ])

    case response do
      {:ok, %{"transaction_id" => trx_id}} ->
        %{transaction_id: trx_id}

      {:error, %{body: %{"error" => error}}} ->
        {:error, error}

      unhandled_reply ->
        {:error, unhandled_reply}
    end
  end

  @spec random_eos_account :: binary
  def random_eos_account do
    generate_account = fn ->
      12
      |> :crypto.strong_rand_bytes()
      |> Base.encode32()
      |> binary_part(0, 12)
      |> String.downcase()
    end

    new_account = generate_account.()

    case EOSRPC.Chain.get_account(new_account) do
      {:ok, _} ->
        random_eos_account()

      {:error, _} ->
        new_account
    end
  end

  @spec parse_symbol(binary) :: {float, binary}
  def parse_symbol(asset) do
    {amount, symbol} =
      asset
      |> Float.parse()

    symbol =
      symbol
      |> String.slice(1..-1)

    {amount, symbol}
  end

  @spec compare_symbols(binary, binary) :: boolean
  def compare_symbols(asset1, asset2) do
    {_, sym1} = parse_symbol(asset1)
    {_, sym2} = parse_symbol(asset2)
    sym1 == sym2
  end

  @spec cambiatus_account :: binary
  def cambiatus_account do
    :cambiatus
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:cambiatus_account)
  end

  @deprecated "Use cambiatus_account/0 instead"
  def cambiatus_acc do
    :cambiatus
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:cambiatus_account)
  end

  @spec cambiatus_wallet :: binary
  def cambiatus_wallet do
    :cambiatus
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:cambiatus_wallet)
  end

  @spec cambiatus_wallet_password :: binary
  def cambiatus_wallet_password do
    :cambiatus
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:cambiatus_wallet_pass)
  end

  @spec mcc_contract :: binary
  def mcc_contract do
    :cambiatus
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:mcc_contract)
  end

  @deprecated "Use cambiatus_community/0 instead"
  @spec cambiatus_cmm :: binary
  def cambiatus_cmm do
    :cambiatus
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:cambiatus_cmm)
  end

  @spec cambiatus_community :: binary
  def cambiatus_community do
    :cambiatus
    |> Application.get_env(__MODULE__)
    |> Keyword.get(:cambiatus_cmm)
  end
end
