defmodule CambiatusWeb.QueryActionsTest do
  use Cambiatus.ApiCase

  setup %{conn: conn} do
    user = insert(:user)

    conn =
      conn
      |> put_req_header("accept", "application/json")
      |> auth_user(user)

    {:ok, conn: conn}
  end

  describe "querying" do
    test "get request",
         %{conn: conn} do
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
        objective: objective,
        description: ""
      }

      # Create 3 actions, only modifying the descrpition between them
      action_to_match1 = insert(:action, %{valid_action_params | description: "Lorem ipsum"})

      action_to_match2 = insert(:action, %{valid_action_params | description: "PlAcEhOlDeR tExT"})

      _action_to_match3 = insert(:action, %{valid_action_params | description: "never matches"})

      # Make 3 queries searching for different descriptions
      query1 =
        community_symbol
        |> generate_query("Lorem ipsum")
        |> make_query_request(conn)

      query2 =
        community_symbol
        |> generate_query("holder")
        |> make_query_request(conn)

      query3 =
        community_symbol
        |> generate_query("nothing at all")
        |> make_query_request(conn)

      # Check if the first query matched only the first action
      assert [action_to_match1.id] == get_query_ids(query1)
      # Check if the second query matched only the second action
      assert [action_to_match2.id] == get_query_ids(query2)
      # Check if the third query matched none of the actions
      assert [] == get_query_ids(query3)
    end
  end

  defp make_query_request(query, conn) do
    conn
    |> put_req_header("accept", "application/json")
    |> put_req_header("content-type", "application/json")
    |> post("/api/graph", query: query)
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
      conn
      |> response(200)
      |> Poison.Parser.parse!(%{keys: :atoms!})

    Enum.map(response.data.search.actions, fn x -> x.id end)
  end
end
