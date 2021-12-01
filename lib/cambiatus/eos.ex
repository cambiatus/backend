defmodule Cambiatus.Eos do
  @moduledoc """
  EOS Wallet and Chain Handler
  """

  @callback netlink(
              new_user :: binary,
              inviter :: binary,
              community :: binary,
              user_type :: binary
            ) :: any
  @callback cambiatus_community() :: binary
  @callback cambiatus_account() :: binary

  @eosrpc_wallet Application.compile_env(:cambiatus, :eosrpc_wallet)
  @eosrpc_helper Application.compile_env(:cambiatus, :eosrpc_helper)
  @eosrpc_chain Application.compile_env(:cambiatus, :eosrpc_chain)

  require Logger

  import Number.Currency

  @spec unlock_wallet() :: atom()
  def unlock_wallet() do
    cambiatus_wallet()
    |> @eosrpc_wallet.unlock(cambiatus_wallet_password())
    |> case do
      {:ok, _res} ->
        :ok

      # wallet already unlocked
      {:error, %{body: %{"error" => %{"code" => 3_120_007}}}} ->
        :ok

      {:error, :econnrefused} ->
        Sentry.capture_message("Can't reach wallet via http",
          extra: %{wallet_name: cambiatus_wallet()}
        )

        :error

      {:error, error} ->
        Sentry.capture_message("Something went wrong while unlocking wallet",
          extra: %{error: error}
        )

        :error
    end
  end

  @spec create_account(String.t(), String.t()) ::
          {:ok, map()}
          | {:error, :account_already_exists | :blockchain_unaccessible | :wallet_error}
  def create_account(public_key, account \\ random_eos_account()) do
    case @eosrpc_chain.get_account(account) do
      {:ok, _} ->
        {:error, :account_already_exists}

      {:error, :nxdomain} ->
        {:error, :blockchain_unacessible}

      {:error, :econnrefused} ->
        {:error, :blockchain_unacessible}

      {:error, _} ->
        case unlock_wallet() do
          :ok ->
            push_create_account_transaction(account, public_key, public_key)

          :error ->
            {:error, :wallet_error}
        end
    end
  end

  def push_create_account_transaction(account_name, owner_key, active_key) do
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

  @doc """
  Netlink function should be called for signup on Global Cambiatus community or for each
  community invitation, after the signup process
  """
  def netlink(new_user, inviter, community_id \\ cambiatus_community(), user_type \\ "natural")

  def netlink(new_user, inviter, community_id, user_type) do
    unlock_wallet()

    asset = build_asset(community_id)

    action = %{
      account: mcc_contract(),
      authorization: [%{actor: cambiatus_acc(), permission: "active"}],
      data: %{
        cmm_asset: asset,
        new_user: new_user,
        inviter: inviter,
        user_type: user_type
      },
      name: "netlink"
    }

    response = @eosrpc_helper.auto_push([action])

    case response do
      {:ok, %{body: %{"transaction_id" => trx_id}}} ->
        {:ok, %{transaction_id: trx_id}}

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

  def format_amount(amount, symbol, format \\ "%n") do
    [precision_string, symbol_code] = String.split(symbol, ",")
    precision = String.to_integer(precision_string)

    number_to_currency(amount, unit: symbol_code, precision: precision, format: format)
  end

  def build_asset(symbol) do
    [precision_string, symbol_code] = symbol |> String.split(",")
    precision = String.to_integer(precision_string)

    if precision == 0 do
      "0 #{symbol_code}"
    else
      (["0."] ++ Enum.map(1..precision, fn _ -> "0" end) ++ [" #{symbol_code}"]) |> Enum.join()
    end
  end

  @spec parse_symbol(binary) :: {float, binary}
  def parse_symbol(asset) do
    {amount, symbol} = Float.parse(asset)
    symbol = String.slice(symbol, 1..-1)

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

  def get_public_key(account) do
    EOSRPC.Chain.get_account(account)
    |> case do
      {:error, _} ->
        {:error, "Account not found"}

      {:ok, %{body: account_info}} ->
        [%{"required_auth" => %{"keys" => [%{"key" => public_key} | _]}} | _] =
          account_info["permissions"]

        {:ok, public_key}
    end
  end

  def verify_sign(sign, phrase, public_key) do
    EosjsAuthWrapper.verify(sign, phrase, public_key)
  end
end
