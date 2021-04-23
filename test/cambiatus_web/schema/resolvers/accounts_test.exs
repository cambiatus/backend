defmodule CambiatusWeb.Schema.Resolvers.AccountsTest do
  @moduledoc """
  This module integration tests to for resolvers that work with the accounts context
  """
  use Cambiatus.ApiCase
  import Plug.Test

  alias EosjsAuthWrapper, as: EosWrap

  alias Cambiatus.{
    Accounts.User,
    Commune.Transfer,
    Auth.Ecdsa,
    Auth,
    Auth.SignUp,
    Auth.Session
  }


  setup %{conn: conn} do
    updated_conn = put_req_header(conn, "user-agent", "Test agent")
    {:ok, conn: updated_conn}
  end

  @eos_account %{
    priv_key: "5Jhua6LXYtwYS9jWSdYwEHVyfVG3MbitNWMELNBzFGhmdX1UHUy",
    pub_key: "EOS4yryLa548uFLFjbcDuBwRA86ChDLqBcGY68n9Gp4tyS6Uw9ffW",
    name: "nertnertn123"
  }

  @valid_params %{
    public_key: "EOS7xQw4jGivKZYYbfLg4fPg9A7zDRvCfT3kGSuHdWWLDeN1pwcwB",
    password: "sdfasfdf",
    user_type: "natural"
  }

  describe "Accounts Resolver" do
    test "collects a user account given the account name" do
      assert Repo.aggregate(User, :count, :account) == 0
      user = insert(:user)

      conn = build_conn() |> auth_user(user)

      variables = %{
        "account" => user.account
      }

      query = """
      query($account: String!){
        user(account: $account) {
        account
        avatar
        bio
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => profile
        }
      } = json_response(res, 200)

      assert Repo.aggregate(User, :count, :account) == 1
      assert profile["account"] == user.account
    end

    test "fetches user address" do
      assert Repo.aggregate(User, :count, :account) == 0
      address = insert(:address)
      user = address.account

      conn = build_conn() |> auth_user(user)

      variables = %{
        "account" => user.account
      }

      query = """
      query($account: String!) {
        user(account: $account) {
          account
          address {
            zip
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => profile
        }
      } = json_response(res, 200)

      assert Repo.aggregate(User, :count, :account) == 1
      assert profile["account"] == user.account
      assert profile["address"]["zip"] == address.zip
    end

    test "fetches user KYC data" do
      assert Repo.aggregate(User, :count, :account) == 0
      kyc = insert(:kyc_data)
      user = kyc.account
      conn = build_conn() |> auth_user(user)

      variables = %{
        "account" => user.account
      }

      query = """
      query($account: String!){
        user(account: $account) {
          account
          kyc {
            userType
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => profile
        }
      } = json_response(res, 200)

      assert Repo.aggregate(User, :count, :account) == 1
      assert profile["account"] == user.account
      assert profile["kyc"]["userType"] == kyc.user_type
    end

    test "updates a user account details given the account name" do
      assert Repo.aggregate(User, :count, :account) == 0
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      variables = %{
        "input" => %{
          "bio" => "new bio"
        }
      }

      query = """
      mutation($input: UserUpdateInput!){
        updateUser(input: $input) {
          account
          bio
        }
      }
      """

      res = conn |> post("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "updateUser" => profile
        }
      } = json_response(res, 200)

      assert Repo.aggregate(User, :count, :account) == 1
      assert profile["account"] == user.account
      refute profile["bio"] == user.bio
    end
  end

  describe "Accounts Auth" do
    test "valid sign up" do
      _community = insert(:community, %{symbol: "BES"})
      _invite_user = insert(:user, %{account: "cambiatustes"})
      attrs = params_for(:user) |> Map.merge(@valid_params)
      assert {:ok, %{user: user, token: token}} = SignUp.sign_up(attrs, :bypass_eos)
    end

    test "sign up, update and signout", %{conn: conn} do
      _community = insert(:community, %{symbol: "BES"})
      _invite_user = insert(:user, %{account: "cambiatustes"})
      attrs = params_for(:user) |> Map.merge(@valid_params)

      assert {:ok, %{user: user, token: token}} = SignUp.sign_up(attrs, :bypass_eos)

      conn = conn |> put_req_header("authorization", "Bearer #{token}")

      account_variables = %{
        "input" => %{
          "name" => "changed"
        }
      }

      update_query = """
      mutation($input: UserUpdateInput!){
        updateUser(input: $input){
          name
        }
      }
      """

      %{
        "data" => %{
          "updateUser" => updatedUser
        }
      } =
        conn
        |> post("/api/graph", query: update_query, variables: account_variables)
        |> json_response(200)

      assert account_variables["input"]["name"] == updatedUser["name"]

      signout_query = """
      mutation {
        signOut
      }
      """

      assert Session.get_user_token(%{account: user.account, filter: :session}) != nil

      assert %{
        "data" => %{
          "signOut" => _logout_message
        }
      } =
        conn
        |> post("/api/graph", query: signout_query)
        |> json_response(200)

      assert Session.get_user_token(%{account: user.account, filter: :session}) == nil

    end

    test "valid sign", %{conn: conn} do
      assert Repo.aggregate(User, :count, :account) == 0
      _user = insert(:user, account: @eos_account.name)

      account_variables = %{
        "account" => @eos_account.name
      }

      auth_session_query = """
      query($account: String!){
        genAuth(account: $account)
      }
      """

      %{
        "data" => %{
          "genAuth" => phrase
        }
      } =
        conn
        |> get("/api/graph", query: auth_session_query, variables: account_variables)
        |> json_response(200)

      conn = conn |> init_test_session(%{}) |> fetch_session() |> put_session(:phrase, phrase)

      {:ok, %{"signature" => signature}} = EosWrap.sign(phrase, @eos_account.priv_key)

      signature_variables = %{
        "signature" => signature
      }

      sign_in_query = """
      mutation($signature: String!) {
        signInV2(signature: $signature) {
          user {
            account
          }
        }
      }
      """

      %{
        "data" => %{
          "signInV2" => user_data
        }
      } =
        conn
        |> put_req_header("user-agent", "Test agent")
        |> post("/api/graph", query: sign_in_query, variables: signature_variables)
        |> json_response(200)

      assert user_data["user"]["account"] == @eos_account.name

      assert Auth.Session.get_user_token(%{account: @eos_account.name, filter: :auth}) == nil
    end

    test "invalid sign", %{conn: conn} do
      assert Repo.aggregate(User, :count, :account) == 0
      _user = insert(:user, account: @eos_account.name)

      account_variables = %{
        "account" => @eos_account.name
      }

      auth_session_query = """
      query($account: String!){
        genAuth(account: $account)
      }
      """

      %{
        "data" => %{
          "genAuth" => phrase
        }
      } =
        conn
        |> get("/api/graph", query: auth_session_query, variables: account_variables)
        |> json_response(200)

      {:ok, %{"signature" => signature}} = EosWrap.sign(phrase, "5KQwrPbwdL6PhXujxW37FSSQZ1JiwsST4cqQzDeyXtP79zkvFD3")

      assert Ecdsa.verify_signature(@eos_account.name, signature, phrase) == false

      assert Auth.Session.get_user_token(%{account: @eos_account.name, filter: :auth})
             |> Map.values()
             |> Enum.member?(@eos_account.name) == true
    end
  end

  describe "payment history" do
    setup do
      assert Repo.aggregate(User, :count, :account) == 0
      assert Repo.aggregate(Transfer, :count, :id) == 0

      utc_today = NaiveDateTime.utc_now()
      utc_yesterday = NaiveDateTime.add(utc_today, -(24 * 60 * 60))

      user1 = insert(:user, %{account: "user1"})
      user2 = insert(:user, %{account: "user2"})

      transfers = [
        # user1 -> user2
        insert(:transfer, %{from: user1, to: user2, created_at: utc_today}),
        insert(:transfer, %{from: user1, to: user2, created_at: utc_today}),
        insert(:transfer, %{from: user1, to: user2, created_at: utc_yesterday}),

        # user1 <- user2
        insert(:transfer, %{from: user2, to: user1, created_at: utc_today})
      ]

      assert Repo.aggregate(User, :count, :account) == 2
      assert Repo.aggregate(Transfer, :count, :id) == 4

      %{
        :users => [user1, user2],
        :transfers => transfers,
        :variables => %{
          # tests are based on the `user1` profile
          "account" => user1.account,
          "first" => Enum.count(transfers)
        }
      }
    end

    test "incoming transfers", %{variables: variables} do
      query = """
        query ($account: String!, $first: Int!) {
          user(account: $account) {
            transfers(first: $first, direction: INCOMING) {
              fetchedCount
            }
          }
        }
      """

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "transfers" => %{
              "fetchedCount" => user1_incoming_transfers_count
            }
          }
        }
      } = json_response(res, 200)

      assert user1_incoming_transfers_count == 1
    end

    test "outgoing transfers", %{variables: variables} do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      query = """
        query ($account: String!, $first: Int!) {
          user(account: $account) {
            transfers(first: $first, direction: OUTGOING) {
              fetchedCount
            }
          }
        }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "transfers" => %{
              "fetchedCount" => user1_outgoing_transfers_count
            }
          }
        }
      } = json_response(res, 200)

      assert user1_outgoing_transfers_count == 3
    end

    test "transfers for the date", %{variables: variables} do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)
      today_date = Date.to_string(Date.utc_today())

      query = """
        query ($account: String!, $first: Int!) {
          user(account: $account) {
            transfers(first: $first, date: "#{today_date}") {
              fetchedCount
            }
          }
        }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "transfers" => %{
              "fetchedCount" => user1_today_transfers_count
            }
          }
        }
      } = json_response(res, 200)

      assert user1_today_transfers_count == 3
    end

    test "incoming transfers for the date", %{variables: variables} do
      today_date = Date.to_string(Date.utc_today())

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      query = """
        query ($account: String!, $first: Int!) {
          user(account: $account) {
           transfers(first: $first, direction: INCOMING, date: "#{today_date}") {
              fetchedCount
            }
          }
        }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "transfers" => %{
              "fetchedCount" => user1_today_incoming_transfers_count
            }
          }
        }
      } = json_response(res, 200)

      assert user1_today_incoming_transfers_count == 1
    end

    test "outgoing transfers for the date", %{variables: variables} do
      today_date = Date.to_string(Date.utc_today())

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      query = """
        query ($account: String!, $first: Int!) {
          user(account: $account) {
            transfers(first: $first, direction: OUTGOING, date: "#{today_date}") {
              fetchedCount
            }
          }
        }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "transfers" => %{
              "fetchedCount" => user1_today_outgoing_transfers_count
            }
          }
        }
      } = json_response(res, 200)

      assert user1_today_outgoing_transfers_count == 2
    end

    test "incoming transfers for the date from user2 to user1", %{
      users: _users,
      variables: variables
    } do
      today_date = Date.utc_today() |> Date.to_string()

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      query = """
        query ($account: String!, $first: Int!) {
          user(account: $account) {
            transfers(
              first: $first,
              direction: INCOMING,
              secondPartyAccount: "user2",
              date: "#{today_date}"
            ) {
              fetchedCount
              edges {
                node {
                  from {
                    account
                  }
                  to {
                    account
                  }
                }
              }
            }
          }
        }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "transfers" => %{
              "fetchedCount" => transfers_from_user2_to_user1_for_today_count,
              "edges" => collected_transfers
            }
          }
        }
      } = json_response(res, 200)

      get_account = & &1["node"][&2]["account"]

      assert Enum.all?(
               collected_transfers,
               fn t -> get_account.(t, "from") == "user2" && get_account.(t, "to") == "user1" end
             ) == true

      assert transfers_from_user2_to_user1_for_today_count == 1
    end

    test "outgoing transfers for the date from user1 to user2", %{
      users: _users,
      variables: variables
    } do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      today_date = Date.utc_today() |> Date.to_string()

      query = """
        query ($account: String!, $first: Int!) {
          user(account: $account) {
            transfers(
              first: $first,
              direction: OUTGOING,
              secondPartyAccount: "user2",
              date: "#{today_date}"
            ) {
              fetchedCount
              edges {
                node {
                  from {
                    account
                  }
                  to {
                    account
                  }
                }
              }
            }
          }
        }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "transfers" => %{
              "fetchedCount" => transfers_from_user1_to_user2_for_today_count,
              "edges" => collected_transfers
            }
          }
        }
      } = json_response(res, 200)

      get_account = & &1["node"][&2]["account"]

      assert Enum.all?(
               collected_transfers,
               fn t -> get_account.(t, "from") == "user1" && get_account.(t, "to") == "user2" end
             ) == true

      assert transfers_from_user1_to_user2_for_today_count == 2
    end

    test "list of payers to `user1`", %{users: users, variables: variables} do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      [_, user2] = users
      account_part = String.slice(user2.account, 0, 3)

      query = """
      query ($account: String!) {
        user(account: $account) {
          getPayersByAccount(account: "#{account_part}") {
            account
            name
            avatar
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, users: users, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "getPayersByAccount" => payers
          }
        }
      } = json_response(res, 200)

      %{"account" => account, "avatar" => avatar, "name" => name} = hd(payers)

      assert account == user2.account
      assert avatar == user2.avatar
      assert name == user2.name
    end
  end
end
