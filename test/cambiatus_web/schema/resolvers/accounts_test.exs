defmodule CambiatusWeb.Schema.Resolvers.AccountsTest do
  @moduledoc """
  This module integration tests to for resolvers that work with the accounts context
  """
  use Cambiatus.ApiCase

  alias Cambiatus.{Accounts.User, Auth.Request, Auth.Session, Commune.Transfer}

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
          address { zip }
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
          kyc { userType }
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
        user(input: $input) {
          account
          bio
        }
      }
      """

      res = conn |> post("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => profile
        }
      } = json_response(res, 200)

      assert Repo.aggregate(User, :count, :account) == 1
      assert profile["account"] == user.account
      refute profile["bio"] == user.bio
    end

    test "updates a user account language given the account name" do
      assert Repo.aggregate(User, :count, :account) == 0
      user = insert(:user, account: "test1234")
      conn = build_conn() |> auth_user(user)

      mutation = """
      mutation {
        preference(language: PTBR) {
          account
          language
        }
      }
      """

      res = conn |> post("/api/graph", query: mutation)

      response = json_response(res, 200)

      assert %{
               "data" => %{
                 "preference" => %{
                   "account" => "test1234",
                   "language" => "PTBR"
                 }
               }
             } = response
    end
  end

  describe "payment history" do
    setup do
      assert Repo.aggregate(User, :count, :account) == 0
      assert Repo.aggregate(Transfer, :count, :id) == 0

      utc_today = DateTime.utc_now()
      utc_yesterday = DateTime.add(utc_today, 24 * 60 * 60)

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
          first: Enum.count(transfers)
        }
      }
    end

    test "receiving transfers", %{variables: variables} do
      query = """
        query ($account: String!) {
          user(account: $account) {
            transfers(
              first: #{variables.first},
              filter: {
                direction: { direction: RECEIVING }
              }) {
              count
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
              "count" => user1_incoming_transfers_count
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
        query ($account: String!) {
          user(account: $account) {
            transfers(
              first: #{variables.first},
              filter: {
                direction: { direction: SENDING }
              }) {
              count
            }
          }
        }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "transfers" => %{
              "count" => user1_outgoing_transfers_count
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
        query ($account: String!) {
          user(account: $account) {
            transfers(
              first: #{variables.first},
              filter: {
               date: "#{today_date}"
              }) {
              count
            }
          }
        }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "transfers" => %{
              "count" => user1_today_transfers_count
            }
          }
        }
      } = json_response(res, 200)

      assert user1_today_transfers_count == 3
    end

    test "receiving transfers for the date", %{variables: variables} do
      today_date = Date.to_string(Date.utc_today())

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      query = """
        query ($account: String!) {
          user(account: $account) {
           transfers(
             first: #{variables.first},
             filter: {
              direction: { direction: RECEIVING },
              date: "#{today_date}"
             }) {
              count
            }
          }
        }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "transfers" => %{
              "count" => user1_today_incoming_transfers_count
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
        query ($account: String!) {
          user(account: $account) {
            transfers(
              first: #{variables.first},
              filter: {
                direction: { direction: SENDING },
                date: "#{today_date}"
              }) {
              count
            }
          }
        }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "user" => %{
            "transfers" => %{
              "count" => user1_today_outgoing_transfers_count
            }
          }
        }
      } = json_response(res, 200)

      assert user1_today_outgoing_transfers_count == 2
    end

    test "receiving transfers for the date from user2 to user1", %{
      users: _users,
      variables: variables
    } do
      today_date = Date.utc_today() |> Date.to_string()

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      query = """
        query ($account: String!) {
          user(account: $account) {
            transfers(
              first: #{variables.first},
              filter: {
                direction: {direction: RECEIVING, otherAccount: "user2"},
                date: "#{today_date}"
              }
            ) {
              count
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
              "count" => transfers_from_user2_to_user1_for_today_count,
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
        query ($account: String!) {
          user(account: $account) {
            transfers(
              first: #{variables.first},
              filter: {
                direction: {direction: SENDING, otherAccount: "user2"},
                date: "#{today_date}"
              }
            ) {
              count
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
              "count" => transfers_from_user1_to_user2_for_today_count,
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

      query = """
      query ($account: String!) {
        user(account: $account) {
          getPayersByAccount(account: "#{user2.account}") {
            account
            name
            avatar
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

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

    test "get phrase to be signed" do
      user = insert(:user)
      conn = build_conn()

      query = """
      mutation{
        genAuth(account: "#{user.account}"){
          phrase
        }
      }
      """

      res = conn |> post("/api/graph", query: query)

      %{
        "data" => %{
          "genAuth" => %{
            "phrase" => _
          }
        }
      } = json_response(res, 200)

      request = Repo.get_by(Request, user_id: user.account)

      assert user.account == request.user_id
    end

    test "Sign in with signed phrase" do
      community = insert(:community)
      user = insert(:user)
      insert(:network, community: community, user: user)
      insert(:request, user: user)

      conn =
        build_conn()
        |> put_req_header("community-domain", "https://" <> community.subdomain.name)
        |> put_req_header("user-agent", "Mozilla")

      query = """
      mutation{
        signIn(
          account: "#{user.account}",
          password: "SGI_KI_TEST"
          ){
          token
        }
      }
      """

      res = conn |> post("/api/graph", query: query)

      %{
        "data" => %{
          "signIn" => %{
            "token" => _
          }
        }
      } = json_response(res, 200)

      session = Repo.get_by(Session, user_id: user.account)

      assert user.account == session.user_id
    end

    test "search members" do
      community = insert(:community)

      # Create 3 users, only modifying the name between them
      user_1 = insert(:user, name: "Lorem ipsum")
      user_2 = insert(:user, name: "PlAcEhOlDeR tExT")
      user_3 = insert(:user, name: "never matches")

      insert(:network, community: community, user: user_1)
      insert(:network, community: community, user: user_2)
      insert(:network, community: community, user: user_3)

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      query = fn name ->
        """
        {
          search(communityId:"#{community.symbol}") {
            members(query: "#{name}") {
              name,
              account
            }
          }
        }
        """
      end

      response_1 = conn |> post("/api/graph", query: query.(user_1.name)) |> json_response(200)

      response_2 = conn |> post("/api/graph", query: query.(user_2.name)) |> json_response(200)

      response_3 =
        conn
        |> post("/api/graph", query: query.("Name not meant to match"))
        |> json_response(200)

      assert %{
               "data" => %{
                 "search" => %{
                   "members" => [
                     %{
                       "name" => user_1.name,
                       "account" => user_1.account
                     }
                   ]
                 }
               }
             } == response_1

      assert %{
               "data" => %{
                 "search" => %{
                   "members" => [
                     %{
                       "name" => user_2.name,
                       "account" => user_2.account
                     }
                   ]
                 }
               }
             } == response_2

      assert %{"data" => %{"search" => %{"members" => []}}} = response_3
    end

    test "list and sort users" do
      community = insert(:community)

      user_1 =
        insert(:user,
          name: "a",
          account: "aaaaaaaaaaaa",
          created_at: DateTime.add(DateTime.now!("Etc/UTC"), -3600)
        )

      user_2 =
        insert(:user,
          name: "b",
          account: "bbbbbbbbbbbb",
          created_at: DateTime.add(DateTime.now!("Etc/UTC"), -1800)
        )

      user_3 =
        insert(:user,
          name: "c",
          account: "cccccccccccc",
          created_at: DateTime.add(DateTime.now!("Etc/UTC"), -600)
        )

      insert(:network, community: community, user: user_1)
      insert(:network, community: community, user: user_2)
      insert(:network, community: community, user: user_3)

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      query = fn order_by, order_direction ->
        """
        {
          search(communityId:"#{community.symbol}") {
            members(query: "", order_by: #{order_by}, order_direction: #{order_direction}) {
              account
            }
          }
        }
        """
      end

      response_1 = conn |> post("/api/graph", query: query.("name", "ASC")) |> json_response(200)

      response_2 =
        conn |> post("/api/graph", query: query.("account", "DESC")) |> json_response(200)

      response_3 =
        conn |> post("/api/graph", query: query.("created_at", "DESC")) |> json_response(200)

      assert %{
               "data" => %{
                 "search" => %{
                   "members" => [
                     %{
                       "account" => user_1.account
                     },
                     %{
                       "account" => user_2.account
                     },
                     %{
                       "account" => user_3.account
                     }
                   ]
                 }
               }
             } == response_1

      assert %{
               "data" => %{
                 "search" => %{
                   "members" => [
                     %{
                       "account" => user_3.account
                     },
                     %{
                       "account" => user_2.account
                     },
                     %{
                       "account" => user_1.account
                     }
                   ]
                 }
               }
             } == response_2

      assert %{
               "data" => %{
                 "search" => %{
                   "members" => [
                     %{
                       "account" => user_3.account
                     },
                     %{
                       "account" => user_2.account
                     },
                     %{
                       "account" => user_1.account
                     }
                   ]
                 }
               }
             } == response_3
    end
  end
end
