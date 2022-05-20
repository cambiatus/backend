defmodule CambiatusWeb.QueryActionsTest do
  use Cambiatus.DataCase
  use CambiatusWeb.ConnCase

  alias Cambiatus.Auth.SignIn
  alias CambiatusWeb.AuthToken
  alias Cambiatus.Repo

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end

  describe "querying" do
    setup do
      creator = insert(:user)

      community =
        :community
        |> insert(%{creator: creator.account})
        |> Repo.preload(:subdomain)

      user = insert(:user)
      _placeholder = insert(:request, user: user)
      {:ok, user} = SignIn.sign_in(user.account, "pass", domain: community.subdomain.name)

      {:ok, %{user: user}}
    end

    test "get request",
         %{conn: conn, user: user} do
      # Use signed user to generate an authentication token
      auth_token = AuthToken.sign(user)

      # Create objective that is common for all actions tested
      objective = insert(:objective)
      community_symbol = objective.community.symbol

      # Parameters to ensure that the created actions are validated
      valid_action_params = %{
        is_completed: false,
        verification_type: "claimable",
        deadline: DateTime.add(DateTime.now!("Etc/UTC"), 3600),
        usages: 0,
        usages_left: 4,
        objective: objective
      }

      # Create 3 actions, only modifying the descrpition between them
      action_to_match1 =
        insert(:action, Map.put(valid_action_params, :description, "Lorem ipsem"))

      action_to_match2 =
        insert(:action, Map.put(valid_action_params, :description, "PlAcEhOlDeR tExT"))

      _action_to_match3 =
        insert(:action, Map.put(valid_action_params, :description, "never matches"))

      # Make 3 queries searching for different descriptions
      query1 =
        generate_query(community_symbol, "Lorem ipsem")
        |> make_query_request(conn, auth_token)

      query2 =
        generate_query(community_symbol, "holder")
        |> make_query_request(conn, auth_token)

      query3 =
        generate_query(community_symbol, "nothing at all")
        |> make_query_request(conn, auth_token)

      # Check if the first query matched only the first action
      assert [action_to_match1.id] == get_query_ids(query1)
      # Check if the second query matched only the second action
      assert [action_to_match2.id] == get_query_ids(query2)
      # Check if the third query matched none of the actions
      assert [] == get_query_ids(query3)
    end
  end

  defp make_query_request(query, conn, auth_token) do
    conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("content-type", "application/json")
    |> put_req_header("authorization", "Bearer #{auth_token}")
    |> get("/api/graph", query: query)
  end

  defp generate_query(community_symbol, description) do
    """
      {
      search(communityId:"#{community_symbol}") {
        actions(query: "#{description}") {
          description,
          id
        }
      }
    }
    """
  end

  defp get_query_ids(conn) do
    response =
      conn.resp_body
      |> Poison.Parser.parse!(%{keys: :atoms!})

    Enum.map(response.data.search.actions, fn x -> x.id end)
  end
end
