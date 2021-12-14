defmodule CambiatusWeb.Schema.Resolvers.ObjectivesTest do
  use Cambiatus.ApiCase

  alias Cambiatus.Accounts.User
  alias Cambiatus.Commune.{Community}
  alias Cambiatus.Objectives.{Action, Claim, Objective}

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

      Enum.map(actions1, &insert(:validator, %{action: &1, validator: user1}))
      Enum.map(actions2, &insert(:validator, %{action: &1, validator: user2}))

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

    test "collect's a single claim" do
      user = insert(:user)
      conn = build_conn() |> auth_user(user)

      assert Repo.aggregate(Claim, :count, :id) == 0

      claim = insert(:claim)

      query = """
      query {
        claim(id: #{claim.id}) {
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
      _claim2 = insert(:claim, %{claimer: claimer, action: action1, status: "pending"})

      # Collect all validator's claims for analysis
      params = %{
        "communityId" => community.symbol
      }

      query_analysis = """
      query($communityId: String!) {
        pendingClaims(first: #{@num}, communityId: $communityId) {
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
      %{"data" => %{"pendingClaims" => _}} = json_response(res, 200)

      query_history = """
      query($communityId: String!) {
        analyzedClaims(first: #{@num}, communityId: $communityId) {
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
      %{"data" => %{"analyzedClaims" => ch}} = json_response(res, 200)
      claim_history_ids = ch["edges"] |> Enum.map(& &1["node"]) |> Enum.map(& &1["action"]["id"])

      refute Enum.any?(claim_history_ids)
    end
  end
end
