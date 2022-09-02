defmodule Cambiatus.Workers.DigestEmailWorkerTest do
  use Cambiatus.DataCase
  use Oban.Testing, repo: Cambiatus.Repo

  alias Cambiatus.Workers.DigestEmailWorker

  import Swoosh.TestAssertions

  describe "perform/1" do
    test "sends email to user" do
      user = insert(:user)
      community = insert(:community)

      assert {:ok, _} =
               perform_job(DigestEmailWorker, %{
                 "community_id" => community.symbol,
                 "account" => user.account
               })

      {:messages, messages} = :erlang.process_info(self(), :messages)

      user_token =
        messages[:email]
        |> Map.get(:headers)
        |> Map.get("List-Unsubscribe")
        |> String.split("token=")
        |> List.last()
        |> String.replace(">", "")

      assert_email_sent(
        to: user.email,
        from: {"#{community.name} - Cambiatus", "no-reply@cambiatus.com"},
        subject: "#{community.name} - Community News",
        headers: %{
          "List-Unsubscribe" =>
            "<https://#{community.subdomain.name}/api/unsubscribe?token=#{user_token}>",
          "List-Unsubscribe-Post" => "List-Unsubscribe=One-Click"
        }
      )

      refute_email_sent()
    end

    test "will only this month news" do
      user = insert(:user)
      community = insert(:community)

      # News created last week
      news1 =
        insert(:news,
          community: community,
          title: "First news",
          updated_at: DateTime.utc_now() |> DateTime.add(-3600 * 24 * 7, :second)
        )

      # News created this month
      news2 =
        insert(:news,
          community: community,
          title: "Second news",
          updated_at: DateTime.utc_now() |> DateTime.add(-3600 * 24 * 28, :second)
        )

      # News created last month
      news3 =
        insert(:news,
          community: community,
          title: "Third news",
          updated_at: DateTime.utc_now() |> DateTime.add(-3600 * 24 * 32, :second)
        )

      assert {:ok, _} =
               perform_job(DigestEmailWorker, %{
                 "community_id" => community.symbol,
                 "account" => user.account
               })

      {:messages, messages} = :erlang.process_info(self(), :messages)

      body = messages[:email] |> Map.get(:html_body)

      assert_email_sent(to: user.email)

      assert String.contains?(body, news1.title)
      assert String.contains?(body, news2.title)
      refute String.contains?(body, news3.title)
    end
  end
end
