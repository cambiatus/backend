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
    Commune.Action,
    Shop.Product,
    Commune.Community,
    Commune.Claim,
    Commune.Objective,
    Commune.Transfer,
    Commune.Validator
  }

  @num 3
  describe "Commune Resolver" do
    test "updates an objective to be completed" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)
      community = insert(:community, %{creator: user.account})

      objective = insert(:objective, %{community: community})

      input = %{
        "input" => %{
          "objective_id" => objective.id
        }
      }

      query = """
      mutation ($input: CompleteObjectiveInput) {
        completeObjective(input: $input) {
          description
          isCompleted
          completedAt
        }
      }
      """

      res = post(conn, "/api/graph", query: query, variables: input)

      response = json_response(res, 200)

      assert response["data"]["completeObjective"]["description"] == objective.description
      assert response["data"]["completeObjective"]["isCompleted"] == true
    end

    test "collects claimable actions with their validators" do
      assert(Repo.aggregate(Community, :count, :symbol) == 0)
      comm = insert(:community)

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

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

    test "collects all actions from a specific creator" do
      assert Repo.aggregate(User, :count, :account) == 0
      assert Repo.aggregate(Community, :count, :symbol) == 0
      assert Repo.aggregate(Objective, :count, :id) == 0
      assert Repo.aggregate(Action, :count, :id) == 0

      user1 = insert(:user)
      user2 = insert(:user)

      conn = build_conn() |> auth_user(user1)

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

    test "collects all actions from a specific validator" do
      assert Repo.aggregate(User, :count, :account) == 0
      assert Repo.aggregate(Community, :count, :symbol) == 0
      assert Repo.aggregate(Objective, :count, :id) == 0
      assert Repo.aggregate(Action, :count, :id) == 0

      user1 = insert(:user)
      user2 = insert(:user)

      conn = build_conn() |> auth_user(user1)

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

    test "collects all uncompleted actions" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

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

    test "collects all automatic actions" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

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

    test "collects all claimable actions" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

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

    test "collects a single transfer" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

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

    test "collects a community with its objectives and their actions" do
      assert(Repo.aggregate(Community, :count, :symbol) == 0)
      comm = insert(:community)

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

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

    test "collects all objectives in a community sorted by date" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      assert(Repo.aggregate(Community, :count, :symbol) == 0)
      cmm = insert(:community)

      _objectives = insert_list(@num, :objective, %{community: cmm})

      assert Repo.aggregate(Objective, :count, :id) == @num

      query = """
      query {
        community(symbol: "#{cmm.symbol}") {
          objectives {
            isCompleted
            completedAt
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

    test "collects all communities" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

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

    test "collect a single community" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

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

    test "collects all products" do
      assert Repo.aggregate(Product, :count, :id) == 0
      latest = NaiveDateTime.add(NaiveDateTime.utc_now(), 3_600_000, :millisecond)

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      community = insert(:community)

      insert_list(@num, :product, %{community: community, creator: user})
      insert_list(2, :product, %{community: community})
      %{title: f_title} = insert(:product, %{community: community, created_at: latest})

      variables = %{
        "communityId" => community.symbol
      }

      query = """
      query($communityId: String!) {
        products(communityId: $communityId) {
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
          "products" => all_sales
        }
      } = json_response(res, 200)

      %{"title" => t} = hd(all_sales)
      assert t == f_title
      assert Enum.count(all_sales) == @num + 3
    end

    test "collects all products from a community" do
      assert Repo.aggregate(Product, :count, :id) == 0

      latest = NaiveDateTime.add(NaiveDateTime.utc_now(), 3_600_000, :millisecond)

      c1 = insert(:community)
      c2 = insert(:community)
      user = insert(:user)

      conn = build_conn() |> auth_user(user)

      insert_list(@num, :product, %{units: 0, community: c1})
      insert_list(@num, :product, %{community: c1})

      insert(:network, %{community: c1, account: user})
      insert(:network, %{community: c2, account: user})

      insert(:product, %{community: c2})
      insert(:product, %{creator: user, community: c2})
      %{title: f_title} = insert(:product, %{created_at: latest, community: c1})

      variables = %{
        "communityId" => c1.symbol
      }

      query = """
      query($communityId: String!) {
        products(communityId: $communityId) {
          id
          title
          description
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "products" => community_sales
        }
      } = json_response(res, 200)

      assert %{"title" => ^f_title} = hd(community_sales)
      assert Repo.aggregate(Product, :count, :id) == @num * 3
      assert Enum.count(community_sales) == @num * 3 - 2
    end

    test "collects a user's products" do
      assert Repo.aggregate(Product, :count, :id) == 0

      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      community = insert(:community)
      latest = NaiveDateTime.add(NaiveDateTime.utc_now(), 3_600_000, :millisecond)

      %{title: first_title} =
        insert(:product, %{creator: user, created_at: latest, community: community})

      insert_list(@num, :product, %{creator: user, community: community})

      variables = %{
        "communityId" => community.symbol,
        "filters" => %{
          "account" => user.account
        }
      }

      query = """
      query($communityId: String!, $filters: ProductsFilterInput){
        products(communityId: $communityId, filters: $filters) {
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
          "products" => user_sales
        }
      } = json_response(res, 200)

      acc = user.account

      assert %{"creator" => %{"account" => ^acc}, "title" => ^first_title} = hd(user_sales)
      # account for the additional sort product
      assert Enum.count(user_sales) == @num + 1
    end

    test "collects a single product" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      product = insert(:product)

      variables = %{
        "id" => product.id
      }

      query = """
      query($id: Int!) {
        product(id: $id) {
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
          "product" => saved_sale
        }
      } = json_response(res, 200)

      assert Repo.aggregate(Product, :count, :id) == 1
      assert saved_sale["id"] == product.id
    end

    test "collect only sales not deleted" do
      assert Repo.aggregate(Product, :count, :id) == 0

      user = insert(:user)
      conn = build_conn() |> auth_user(user)
      community = insert(:community)

      insert_list(@num, :product, %{community: community, is_deleted: true, creator: user})
      %{title: title} = insert(:product, %{community: community, creator: user})

      variables = %{
        "communityId" => community.symbol
      }

      query = """
      query($communityId: String!) {
        products(communityId: $communityId) {
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
          "products" => all_sales
        }
      } = json_response(res, 200)

      # total of 4 sales, being:
      # - 3 deleted
      # - 1 not deleted
      assert Enum.count(all_sales) == 1
      assert %{"title" => ^title} = hd(all_sales)
    end

    test "collects a user's transfers" do
      assert Repo.aggregate(Transfer, :count, :id) == 0
      user = insert(:user)

      conn = build_conn() |> auth_user(user)

      user1 = insert(:user)
      insert_list(@num, :transfer, %{from: user1})
      insert_list(@num, :transfer, %{from: user})
      insert_list(@num, :transfer, %{to: user})

      fetch = 3

      variables = %{
        "account" => user.account,
        "first" => fetch
      }

      query = """
      query($account: String!, $first: Int!) {
        user(account: $account) {
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
          "user" => %{
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

    test "collects a community s features" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      community = insert(:community)

      variables = %{
        "symbol" => community.symbol
      }

      query = """
      query($symbol: String!) {
        community(symbol: $symbol) {
          has_objectives,
          has_shop,
          has_kyc
        }
      }
      """

      res = conn |> get("/api/graph", query: query, variables: variables)

      %{
        "data" => %{
          "community" => %{
            "has_objectives" => actions,
            "has_shop" => shop,
            "has_kyc" => kyc
          }
        }
      } = json_response(res, 200)

      assert actions == true
      assert shop == true
      assert kyc == false
    end

    test "collects a community's transfers" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

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

    test "collect's a single claim" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      assert Repo.aggregate(Claim, :count, :id) == 0

      claim = insert(:claim)

      query = """
      query {
        claim(input:{id: #{claim.id}}) {
          id
          createdAt
        }
      }

      """

      res = conn |> get("/api/graph", query: query)

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

      conn = build_conn() |> auth_user(verifier3)

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
        "communityId" => community.symbol,
        "first" => @num
      }

      query_analysis = """
      query($first: Int!, $communityId: String!) {
        claimsAnalysis(first: $first, communityId: $communityId) {
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

      res = conn |> get("/api/graph", query: query_analysis, variables: params)
      %{"data" => %{"claimsAnalysis" => cs}} = json_response(res, 200)
      claim_action_ids = cs["edges"] |> Enum.map(& &1["node"]) |> Enum.map(& &1["action"]["id"])

      # Make sure pending is only one
      assert Enum.count(claim_action_ids) == 1

      query_history = """
      query($first: Int!, $communityId: String!) {
        claimsAnalysisHistory(first: $first, communityId: $communityId) {
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

      res = conn |> get("/api/graph", query: query_history, variables: params)
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
