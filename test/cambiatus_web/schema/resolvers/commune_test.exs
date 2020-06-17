defmodule CambiatusWeb.Schema.Resolvers.CommuneTest do
  @moduledoc """
  This module holds integration tests for resolvers used when interacting with the
  Commune context, use it to ensure that the the context acts as expected
  """
  use Cambiatus.ApiCase

  alias Cambiatus.{
    Accounts.User,
    Auth.Invitation,
    Auth.InvitationId,
    Commune,
    Commune.Action,
    Commune.AvailableSale,
    Commune.Community,
    Commune.Claim,
    Commune.Objective,
    Commune.Transfer,
    Commune.Validator
  }

  @num 3
  describe "Commune Resolver" do
    test "collects claimable actions with their validators", %{conn: conn} do
      assert(Repo.aggregate(Community, :count, :symbol) == 0)
      comm = insert(:community)

      objectives = insert_list(@num, :objective, %{community: comm})

      Enum.map(objectives, fn obj ->
        action = insert(:action, %{objective: obj, verification_type: "claimable"})

        _validators = insert_list(@num, :validator, %{action: action})
      end)

      assert Repo.aggregate(Community, :count, :symbol) == 1
      assert Repo.aggregate(Objective, :count, :id) == @num
      assert Repo.aggregate(Action, :count, :created_at) == @num

      query = """
      query {
        community(symbol: "#{comm.symbol}") {
          symbol
          objectives {
            actions {
              validators {
                avatar
              }
            }
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "community" => %{"objectives" => objs}
        }
      } = json_response(res, 200)

      Enum.map(objs, fn o ->
        Enum.map(o["actions"], fn a ->
          assert Enum.count(a["validators"]) == @num
        end)
      end)
    end

    test "collects all actions from a specific creator", %{conn: conn} do
      assert Repo.aggregate(User, :count, :account) == 0
      assert Repo.aggregate(Community, :count, :symbol) == 0
      assert Repo.aggregate(Objective, :count, :id) == 0
      assert Repo.aggregate(Action, :count, :id) == 0

      user1 = insert(:user)
      user2 = insert(:user)

      comm = insert(:community)

      objective = insert(:objective, %{community: comm, creator: user1})

      insert(:action, %{creator: user1, objective: objective})
      insert_list(@num, :action, %{creator: user1, objective: objective})
      insert_list(@num, :action, %{creator: user2, objective: objective})

      assert Repo.aggregate(User, :count, :account) == 2
      assert Repo.aggregate(Community, :count, :symbol) == 1
      assert Repo.aggregate(Objective, :count, :id) == 1
      assert Repo.aggregate(Action, :count, :id) == 1 + @num + @num

      query = """
      query {
        community(symbol: "#{comm.symbol}") {
          symbol
          objectives {
            actions(input: {creator: "#{user1.account}"}) {
              createdAt
            }
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "community" => %{"objectives" => objectives}
        }
      } = json_response(res, 200)

      assert 1 == Enum.count(objectives)

      assert 1 + @num ==
               Enum.reduce(objectives, 0, fn obj, acc ->
                 Enum.count(obj["actions"]) + acc
               end)
    end

    test "collects all actions from a specific validator", %{conn: conn} do
      assert Repo.aggregate(User, :count, :account) == 0
      assert Repo.aggregate(Community, :count, :symbol) == 0
      assert Repo.aggregate(Objective, :count, :id) == 0
      assert Repo.aggregate(Action, :count, :id) == 0

      user1 = insert(:user)
      user2 = insert(:user)

      comm = insert(:community)

      objective = insert(:objective, %{community: comm, creator: user1})

      actions1 = insert_list(@num + 1, :action, %{creator: user1, objective: objective})
      actions2 = insert_list(@num, :action, %{creator: user1, objective: objective})

      Enum.map(actions1, fn act ->
        insert(:validator, %{action: act, validator: user1})
      end)

      Enum.map(actions2, fn act ->
        insert(:validator, %{action: act, validator: user2})
      end)

      assert Repo.aggregate(User, :count, :account) == 2
      assert Repo.aggregate(Community, :count, :symbol) == 1
      assert Repo.aggregate(Objective, :count, :id) == 1
      assert Repo.aggregate(Action, :count, :id) == 1 + @num + @num

      query = """
      query {
        community(symbol: "#{comm.symbol}") {
          symbol
          objectives {
            actions(input: {validator: "#{user1.account}"}) {
              createdAt
            }
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "community" => %{"objectives" => objectives}
        }
      } = json_response(res, 200)

      assert 1 == Enum.count(objectives)

      assert 1 + @num ==
               Enum.reduce(objectives, 0, fn obj, acc ->
                 Enum.count(obj["actions"]) + acc
               end)
    end

    test "collects all uncompleted actions", %{conn: conn} do
      assert Repo.aggregate(Community, :count, :symbol) == 0
      assert Repo.aggregate(Objective, :count, :id) == 0
      assert Repo.aggregate(Action, :count, :id) == 0

      comm = insert(:community)

      objective = insert(:objective, %{community: comm})

      insert_list(@num + 1, :action, %{is_completed: false, objective: objective})
      insert_list(@num, :action, %{is_completed: true, objective: objective})

      assert Repo.aggregate(Community, :count, :symbol) == 1
      assert Repo.aggregate(Objective, :count, :id) == 1
      assert Repo.aggregate(Action, :count, :id) == 1 + @num + @num

      query = """
      query {
        community(symbol: "#{comm.symbol}") {
          symbol
          objectives {
            actions(input: {isCompleted: false}) {
              createdAt
            }
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "community" => %{"objectives" => objectives}
        }
      } = json_response(res, 200)

      assert 1 == Enum.count(objectives)

      assert 1 + @num ==
               Enum.reduce(objectives, 0, fn obj, acc ->
                 Enum.count(obj["actions"]) + acc
               end)
    end

    test "collects all automatic actions", %{conn: conn} do
      assert Repo.aggregate(Community, :count, :symbol) == 0
      assert Repo.aggregate(Objective, :count, :id) == 0
      assert Repo.aggregate(Action, :count, :id) == 0

      comm = insert(:community)

      objective = insert(:objective, %{community: comm})

      insert_list(@num + 1, :action, %{verification_type: "automatic", objective: objective})
      insert_list(@num, :action, %{verification_type: "claimable", objective: objective})

      assert Repo.aggregate(Community, :count, :symbol) == 1
      assert Repo.aggregate(Objective, :count, :id) == 1
      assert Repo.aggregate(Action, :count, :id) == 1 + @num + @num

      query = """
      query {
        community(symbol: "#{comm.symbol}") {
          symbol
          objectives {
            actions(input: {verificationType: AUTOMATIC}) {
              createdAt
            }
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "community" => %{"objectives" => objectives}
        }
      } = json_response(res, 200)

      assert 1 == Enum.count(objectives)

      assert 1 + @num ==
               Enum.reduce(objectives, 0, fn obj, acc ->
                 Enum.count(obj["actions"]) + acc
               end)
    end

    test "collects all claimable actions", %{conn: conn} do
      assert Repo.aggregate(Community, :count, :symbol) == 0
      assert Repo.aggregate(Objective, :count, :id) == 0
      assert Repo.aggregate(Action, :count, :id) == 0

      comm = insert(:community)

      objective = insert(:objective, %{community: comm})

      insert_list(@num + 1, :action, %{verification_type: "claimable", objective: objective})
      insert_list(@num, :action, %{verification_type: "automatic", objective: objective})

      assert Repo.aggregate(Community, :count, :symbol) == 1

      assert Repo.aggregate(Objective, :count, :id) == 1

      assert Repo.aggregate(Action, :count, :id) == 1 + @num + @num

      query = """
      query {
        community(symbol: "#{comm.symbol}") {
          symbol
          objectives {
            actions(input: {verificationType: CLAIMABLE}) {
              createdAt
            }
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "community" => %{"objectives" => objectives}
        }
      } = json_response(res, 200)

      assert 1 == Enum.count(objectives)

      assert 1 + @num ==
               Enum.reduce(objectives, 0, fn obj, acc ->
                 Enum.count(obj["actions"]) + acc
               end)
    end

    test "collects a single transfer", %{conn: conn} do
      assert(Repo.aggregate(Transfer, :count, :id) == 0)

      transfer = insert(:transfer)

      assert(Repo.aggregate(Transfer, :count, :id) == 1)

      variables = %{
        "input" => %{
          "id" => transfer.id
        }
      }

      query = """
      query($input: TransferInput!){
        transfer(input: $input) {
          id
          from {
            account
          }
          to {
            account
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "transfer" => collected_transfer
        }
      } = json_response(res, 200)

      assert collected_transfer["id"] == transfer.id
      assert collected_transfer["from"]["account"] == transfer.from.account
      assert collected_transfer["to"]["account"] == transfer.to.account
    end

    test "collects a community with its objectives and their actions", %{conn: conn} do
      assert(Repo.aggregate(Community, :count, :symbol) == 0)
      comm = insert(:community)

      objectives = insert_list(@num, :objective, %{community: comm})

      Enum.map(objectives, fn obj ->
        insert_list(@num, :action, %{objective: obj})
      end)

      assert Repo.aggregate(Community, :count, :symbol) == 1
      assert Repo.aggregate(Objective, :count, :id) == @num
      assert Repo.aggregate(Action, :count, :id) == @num * @num

      query = """
      query {
        community(symbol: "#{comm.symbol}") {
          symbol
          objectives {
            actions {
              createdAt
            }
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "community" => %{"objectives" => objectives}
        }
      } = json_response(res, 200)

      assert @num == Enum.count(objectives)

      # 3 objectives with 3 actions each
      assert @num * @num ==
               Enum.reduce(objectives, 0, fn obj, acc ->
                 Enum.count(obj["actions"]) + acc
               end)
    end

    test "collects all objectives in a community sorted by date", %{conn: conn} do
      assert(Repo.aggregate(Community, :count, :symbol) == 0)
      cmm = insert(:community)

      _objectives = insert_list(@num, :objective, %{community: cmm})

      assert Repo.aggregate(Objective, :count, :id) == @num

      query = """
      query {
        community(symbol: "#{cmm.symbol}") {
          objectives {
            createdAt
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{
          "community" => %{"objectives" => objectives}
        }
      } = json_response(res, 200)

      assert List.first(objectives)["createdAt"] > List.last(objectives)["createdAt"]
    end

    test "collects all communities", %{conn: conn} do
      assert(Repo.aggregate(Community, :count, :symbol) == 0)
      insert(:community)

      query = """
      query {
        communities {
          symbol
          name
          description
        }
      }
      """

      res = conn |> get("/api/graph", query: query)

      %{
        "data" => %{"communities" => all_communities}
      } = json_response(res, 200)

      assert Enum.count(all_communities) == 1
    end

    test "collect a single community", %{conn: conn} do
      assert(Repo.aggregate(Community, :count, :symbol) == 0)
      community = insert(:community)
      community1 = insert(:community)

      query = """
      query {
        community(symbol: "#{community.symbol}") {
          name
        }
      }
      """

      res = conn |> get("/api/graph", query: query)
      %{"data" => %{"community" => found_community}} = json_response(res, 200)

      assert(community.name == found_community["name"])
      assert(community1.name != found_community["name"])
    end

    test "collects all sales", %{conn: conn} do
      assert Repo.aggregate(AvailableSale, :count, :id) == 0
      latest = NaiveDateTime.add(NaiveDateTime.utc_now(), 3_600_000, :millisecond)

      usr = insert(:user)
      community = insert(:community)

      insert_list(@num, :sale, %{community: community, creator: usr})
      insert_list(2, :sale, %{community: community})
      %{title: f_title} = insert(:sale, %{community: community, created_at: latest})

      variables = %{
        "input" => %{
          "all" => usr.account,
          "community_id" => community.symbol
        }
      }

      query = """
      query($input: SalesInput!){
        sales(input: $input) {
          id
          title
          description
          creator {
            account
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "sales" => all_sales
        }
      } = json_response(res, 200)

      %{"title" => t} = hd(all_sales)
      assert t == f_title
      assert Enum.count(all_sales) == @num
    end

    test "collects all sales from a user's communities", %{conn: conn} do
      assert Repo.aggregate(AvailableSale, :count, :id) == 0

      latest = NaiveDateTime.add(NaiveDateTime.utc_now(), 3_600_000, :millisecond)

      c1 = insert(:community)
      c2 = insert(:community)
      usr = insert(:user)

      insert_list(@num, :sale, %{units: 0, community: c1})
      insert_list(@num, :sale, %{community: c1})

      insert(:network, %{community: c1, account: usr})
      insert(:network, %{community: c2, account: usr})

      insert(:sale, %{community: c2})
      insert(:sale, %{creator: usr, community: c2})
      %{title: f_title} = insert(:sale, %{created_at: latest, community: c2})

      variables = %{
        "input" => %{
          "communities" => usr.account
        }
      }

      query = """
      query($input: SalesInput!){
        sales(input: $input) {
          id
          title
          description
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "sales" => community_sales
        }
      } = json_response(res, 200)

      assert %{"title" => ^f_title} = hd(community_sales)
      assert Repo.aggregate(AvailableSale, :count, :id) == @num * 3
      # Assert that the collected items are the total less the
      # 1 sale belonging to the user
      assert Enum.count(community_sales) == @num * 3 - 1
    end

    test "collects a user's sales", %{conn: conn} do
      assert Repo.aggregate(AvailableSale, :count, :id) == 0
      user = insert(:user)
      latest = NaiveDateTime.add(NaiveDateTime.utc_now(), 3_600_000, :millisecond)

      %{title: first_title} = insert(:sale, %{creator: user, created_at: latest})
      insert_list(@num, :sale, %{creator: user})

      variables = %{
        "input" => %{
          "account" => user.account
        }
      }

      query = """
      query($input: SalesInput!){
        sales(input: $input) {
          id
          title
          description
          createdAt
          creator {
            account
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "sales" => user_sales
        }
      } = json_response(res, 200)

      acc = user.account

      assert %{"creator" => %{"account" => ^acc}, "title" => ^first_title} = hd(user_sales)
      # account for the additional sort sale
      assert Enum.count(user_sales) == @num + 1
    end

    test "collects a single sale", %{conn: conn} do
      sale = insert(:sale)

      variables = %{
        "input" => %{
          "id" => sale.id
        }
      }

      query = """
      query($input: SaleInput!) {
        sale(input: $input) {
          id
          title
          description
          createdAt
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "sale" => saved_sale
        }
      } = json_response(res, 200)

      assert Repo.aggregate(AvailableSale, :count, :id) == 1
      assert saved_sale["id"] == sale.id
    end

    test "collect only sales not deleted", %{conn: conn} do
      assert Repo.aggregate(AvailableSale, :count, :id) == 0

      usr = insert(:user)
      community = insert(:community)

      insert_list(@num, :sale, %{community: community, is_deleted: true})
      %{title: title} = insert(:sale, %{community: community})

      variables = %{
        "input" => %{
          "all" => usr.account,
          "community_id" => community.symbol
        }
      }

      query = """
      query($input: SalesInput!){
        sales(input: $input) {
          id
          title
          description
          creator {
            account
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "sales" => all_sales
        }
      } = json_response(res, 200)

      # total of 4 sales, being:
      # - 3 deleted
      # - 1 not deleted
      assert Enum.count(all_sales) == 1
      assert %{"title" => ^title} = hd(all_sales)
    end

    test "collects a user's transfers", %{conn: conn} do
      assert Repo.aggregate(Transfer, :count, :id) == 0
      usr = insert(:user)

      usr1 = insert(:user)
      insert_list(@num, :transfer, %{from: usr1})
      insert_list(@num, :transfer, %{from: usr})
      insert_list(@num, :transfer, %{to: usr})

      fetch = 3

      variables = %{
        "input" => %{
          "account" => usr.account
        },
        "first" => fetch
      }

      query = """
      query($input: ProfileInput!, $first: Int!) {
        profile(input: $input) {
          transfers(first: $first) {
            totalCount
            fetchedCount
            edges {
              node {
                from_id
                to_id
                amount
                memo
              }
            }
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "profile" => %{
            "transfers" => %{
              "totalCount" => total_count,
              "fetchedCount" => fetched_count
            }
          }
        }
      } = json_response(res, 200)

      assert total_count == @num * 2
      assert fetched_count == fetch
      assert Repo.aggregate(Transfer, :count, :id) == @num * 3
    end

    test "collects a community s features", %{conn: conn} do
      community = insert(:community)

      variables = %{
        "symbol" => community.symbol
      }

      query = """
      query($symbol: String!) {
        community(symbol: $symbol) {
          has_actions,
          has_shop
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "community" => %{
            "has_actions" => actions,
            "has_shop" => shop
          }
        }
      } = json_response(res, 200)

      assert actions == true
      assert shop == true
    end

    test "collects a community's transfers", %{conn: conn} do
      assert Repo.aggregate(Transfer, :count, :id) == 0
      community = insert(:community)
      comm = insert(:community)

      insert_list(@num, :transfer, %{community: comm})
      insert_list(@num, :transfer, %{community: community})

      fetch = 2

      variables = %{
        "symbol" => community.symbol,
        "first" => fetch
      }

      query = """
      query($symbol: String!, $first: Int!) {
        community(symbol: $symbol) {
          transfers(first: $first) {
            totalCount
            fetchedCount
            edges {
              node {
                from_id
                to_id
                amount
                memo
              }
            }
          }
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "community" => %{
            "transfers" => %{
              "totalCount" => total_count,
              "fetchedCount" => fetched_count
            }
          }
        }
      } = json_response(res, 200)

      assert total_count == @num
      assert fetched_count == fetch
      assert Repo.aggregate(Transfer, :count, :id) == @num * 2
    end

    test "collect's a single claim", %{conn: conn} do
      assert Repo.aggregate(Claim, :count, :id) == 0

      claim = insert(:claim)

      variables = %{
        "input" => %{
          "id" => claim.id
        }
      }

      query = """
      query ($input: ClaimInput!) {
        claim (input: $input) {
          id
          createdAt
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "claim" => fetched_claim
        }
      } = json_response(res, 200)

      assert fetched_claim["id"] == claim.id
    end

    test "claims analysis pages" do
      assert Repo.aggregate(Claim, :count, :id) == 0
      assert Repo.aggregate(Action, :count, :id) == 0
      assert Repo.aggregate(Validator, :count, :created_tx) == 0

      creator = insert(:user)
      community = insert(:community)
      objective = insert(:objective, %{community: community, creator: creator})

      # Create related users
      claimer = insert(:user)
      verifier1 = insert(:user)
      verifier2 = insert(:user)
      verifier3 = insert(:user)

      # Create action
      action1 = insert(:action, %{verification_type: "claimable", objective: objective})
      insert(:validator, %{action: action1, validator: verifier1})
      insert(:validator, %{action: action1, validator: verifier2})
      insert(:validator, %{action: action1, validator: verifier3})

      action2 = insert(:action, %{verification_type: "claimable", objective: objective})
      insert(:validator, %{action: action2, validator: verifier1})
      insert(:validator, %{action: action2, validator: verifier2})
      insert(:validator, %{action: action2, validator: verifier3})

      # Claim 1 with two validations
      claim1 = insert(:claim, %{claimer: claimer, action: action1, status: "approved"})
      insert(:check, %{claim: claim1, validator: verifier1, is_verified: true})
      insert(:check, %{claim: claim1, validator: verifier2, is_verified: true})

      # Claim 2 with no validations
      _claim2 = insert(:claim, %{claimer: claimer, action: action1})

      # Collect all validator's claims for analysis
      params = %{
        "input" => %{
          "account" => verifier1.account,
          "symbol" => community.symbol
        },
        "first" => @num
      }

      query_analysis = """
      query($first: Int!, $input: ClaimsAnalysisInput) {
        claimsAnalysis(first: $first, input: $input) {
          edges {
            node {
              id
              action {
                id
              }
            }
          }
        }
      }
      """

      res = build_conn() |> get("/api/graph", query: query_analysis, variables: params)
      %{"data" => %{"claimsAnalysis" => cs}} = json_response(res, 200)
      claim_action_ids = cs["edges"] |> Enum.map(& &1["node"]) |> Enum.map(& &1["action"]["id"])

      # Make sure pending is only one
      assert Enum.count(claim_action_ids) == 1

      query_history = """
      query($first: Int!, $input: ClaimsAnalysisInput) {
        claimsAnalysisHistory(first: $first, input: $input) {
          edges {
            node {
              id
              action {
                id
              }
            }
          }
        }
      }
      """

      res = conn() |> get("/api/graph", query: query_history, variables: params)
      %{"data" => %{"claimsAnalysisHistory" => ch}} = json_response(res, 200)
      claim_history_ids = ch["edges"] |> Enum.map(& &1["node"]) |> Enum.map(& &1["action"]["id"])

      # but we should have both claims on the history
      assert Enum.count(claim_history_ids) == 2
    end

    test "collect a single invitation", %{conn: conn} do
      assert(Repo.aggregate(Invitation, :count, :id) == 0)
      invite = insert(:invitation)
      invite_id = InvitationId.encode(invite.id)

      query = """
        query {
          invite(input: {id: "#{invite_id}"}) {
            creator {
              account
            }
            community {
              symbol
            }
          }
        }
      """

      res = conn |> get("/api/graph", query: query)
      %{"data" => %{"invite" => found_invite}} = json_response(res, 200)

      assert(invite.creator_id == found_invite["creator"]["account"])
      assert(invite.community_id == found_invite["community"]["symbol"])
    end
  end
end
