defmodule Cambiatus.ObjectivesTest do
  use Cambiatus.DataCase

  alias Cambiatus.Objectives
  alias Cambiatus.Objectives.{Action, Objective}

  describe "objectives" do
    test "update_objective/2 with valid data updates the objective" do
      objective = insert(:objective)
      change = %{is_completed: true}
      assert {:ok, %Objective{} = objective} = Objectives.update_objective(objective, change)
      {:ok, found_objective} = Objectives.get_objective(objective.id)
      assert objective.id == found_objective.id
      assert objective.is_completed == found_objective.is_completed
    end
  end

  describe "actions" do
    @action_id 1
    test "get_action/1 collects errors out if action doesn't exist" do
      assert Repo.aggregate(Action, :count, :id) == 0

      assert {:error, "Action with id: #{@action_id} not found"} ==
               Objectives.get_action(@action_id)
    end

    test "get_action/1 collects an action with a valid id" do
      assert Repo.aggregate(Action, :count, :id) == 0

      action = insert(:action)

      assert Repo.aggregate(Action, :count, :id) == 1

      assert {:ok, _} = Objectives.get_action(action.id)
    end

    test "fuzzy search" do
      objective = insert(:objective)
      base = %{objective: objective, verification_type: "claimable", description: ""}
      _action1 = insert(:action, %{base | description: "asdf QUERY asdf"})
      _action2 = insert(:action, %{base | description: "asdfQUERYasdf"})
      _action3 = insert(:action, %{base | description: "QUERYasdf"})
      _action4 = insert(:action, %{base | description: "asdfQUERY"})
      _action5 = insert(:action, %{base | description: "asdf"})
      _action6 = insert(:action, %{base | description: "asdfquery"})

      results = Action |> Objectives.query(%{query: "QUERY"}) |> Repo.all()
      assert(Enum.count(results) == 5)
    end
  end
end
