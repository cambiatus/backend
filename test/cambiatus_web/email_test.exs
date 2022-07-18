defmodule CambiatusWeb.EmailTest do
  use Cambiatus.DataCase

  import Swoosh.TestAssertions

  test "send transfer email" do
    user = insert(:user, language: :"pt-BR")
    community = insert(:community)
    transfer = insert(:transfer, %{to: user, community: community})

    CambiatusWeb.Email.transfer(transfer)

    {:messages, messages} = :erlang.process_info(self(), :messages)

    [email: sent_email] = messages

    one_click_unsub_link =
      sent_email.headers
      |> Map.get("List-Unsubscribe")
      |> String.split("/")
      |> List.last()
      |> String.replace(">", "")
      |> one_click_unsub(community, "transfer_notification")

    assert_email_sent(
      from: {"#{community.name} - Cambiatus", "no-reply@cambiatus.com"},
      to: user.email,
      subject: "Você recebeu uma nova transferência em" <> " #{community.name}",
      headers: %{
        "List-Unsubscribe" => one_click_unsub_link,
        "List-Unsubscribe-Post" => "One-Click"
      }
    )
  end

  test "send claim email" do
    user = insert(:user, language: :"es-ES")
    community = insert(:community)

    claim =
      insert(:claim, %{
        claimer: user,
        action: insert(:action, objective: insert(:objective, community: community))
      })

    CambiatusWeb.Email.claim(claim)

    {:messages, messages} = :erlang.process_info(self(), :messages)

    [email: sent_email] = messages

    one_click_unsub_link =
      sent_email.headers
      |> Map.get("List-Unsubscribe")
      |> String.split("/")
      |> List.last()
      |> String.replace(">", "")
      |> one_click_unsub(community, "claim_notification")

    assert_email_sent(
      from: {"#{community.name} - Cambiatus", "no-reply@cambiatus.com"},
      to: user.email,
      subject: "¡Su reclamo fue aprobado!",
      headers: %{
        "List-Unsubscribe" => one_click_unsub_link,
        "List-Unsubscribe-Post" => "One-Click"
      }
    )
  end

  test "send digest email" do
    user = insert(:user, language: :"amh-ETH")
    community = insert(:community)
    insert(:network, %{user: user, community: community})

    community
    |> Repo.preload([:members, :news])
    |> CambiatusWeb.Email.monthly_digest()

    {:messages, messages} = :erlang.process_info(self(), :messages)

    [email: sent_email] = messages

    one_click_unsub_link =
      sent_email.headers
      |> Map.get("List-Unsubscribe")
      |> String.split("/")
      |> List.last()
      |> String.replace(">", "")
      |> one_click_unsub(community, "digest")

    assert_email_sent(
      from: {"#{community.name} - Cambiatus", "no-reply@cambiatus.com"},
      to: user.email,
      subject: "የማህበረሰብ ዜና",
      headers: %{
        "List-Unsubscribe" => one_click_unsub_link,
        "List-Unsubscribe-Post" => "One-Click"
      }
    )
  end

  defp one_click_unsub(token, community, subject) do
    "<https://#{community.subdomain.name}/api/unsubscribe/#{subject}/#{token}>"
  end
end
