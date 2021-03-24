defmodule Cambiatus.Auth do
  @moduledoc "Cambiatus Account Authentication and Signup Manager"

  import Ecto.Query

  alias Cambiatus.{
    Accounts,
    Accounts.User,
    Auth,
    Auth.Invitation,
    Auth.InvitationId,
    Commune.Network,
    Repo
  }

  @contract Application.get_env(:cambiatus, :contract)
  # @doc """
  # Login logic for Cambiatus.

  # We check our demux/postgres database to see if have a entry for this user.
  # """
  def sign_in(account, password) do
    account
    |> Accounts.get_user()
    |> case do
      nil ->
        {:error, :not_found}

      user ->
        if Accounts.verify_pass(account, password) do
          {:ok, user}
        else
          {:error, :invalid_password}
        end
    end
  end

  def sign_in_v2(account, signature, phrase) do
    account
    |> verify_signature(signature, phrase)
    |> case do
      true ->
        account
        |> Accounts.get_user()
        |> case do
          nil ->
            {:error, :not_found}

          user ->
            if Accounts.verify_pass(account, signature) do
              {:ok, user}
            else
              {:error, :invalid_password}
            end
        end

      false ->
        {:error, "Invalid signature"}
    end
  end

  def verify_signature(account, signature, phrase) do
    {:ok, phrase} = Jason.encode(phrase)

    # TODO implement using task
    NodeJS.call({"app", :publicKeyPoints}, [signature, phrase])
    |> case do
      {:ok, %{"publicKey" => pub_points, "signature" => signature_points}} ->
        public_key = %EllipticCurve.PublicKey.Data{
          curve: %EllipticCurve.Curve.Data{
            A: 0,
            B: 7,
            G: %EllipticCurve.Utils.Point{
              x:
                55_066_263_022_277_343_669_578_718_895_168_534_326_250_603_453_777_594_175_500_187_360_389_116_729_240,
              y:
                32_670_510_020_758_816_978_083_085_130_507_043_184_471_273_380_659_243_275_938_904_335_757_337_482_424,
              z: 1
            },
            N:
              115_792_089_237_316_195_423_570_985_008_687_907_852_837_564_279_074_904_382_605_163_141_518_161_494_337,
            P:
              115_792_089_237_316_195_423_570_985_008_687_907_853_269_984_665_640_564_039_457_584_007_908_834_671_663,
            name: :secp256k1,
            oid: [1, 3, 132, 0, 10]
          },
          point: %EllipticCurve.Utils.Point{
            x: String.to_integer(pub_points["x"]),
            y: String.to_integer(pub_points["y"]),
            z: 1
          }
        }

        signature_elixir = %EllipticCurve.Signature.Data{
          r: String.to_integer(signature_points["r"]),
          s: String.to_integer(signature_points["s"])
        }

        EllipticCurve.Ecdsa.verify?(phrase, signature_elixir, public_key) &&
          compare_public_keys(pub_points["string"], account)

      {:error, _} ->
        false
    end
  end

  @doc """
  Verify public key associated to the signature private key and the public key for the account
  """
  defp compare_public_keys(public_key_a, account) do
    NodeJS.call({"app", :accountToPublicKey}, [account])
    |> case do
      {:ok, %{"ok" => account_info}} ->
        public_key_b =
          account_info
          |> get_in(["permissions", Access.at(0), "required_auth", "keys", Access.at(0), "key"])

        public_key_a == public_key_b

      {:ok, %{"error" => _}} ->
        false
    end
  end

  @doc """
  Login logic for Cambiatus when signing in with an invitationId
  """
  def sign_in(account, password, invitation_id) do
    account
    |> sign_in(password)
    |> netlink(invitation_id)
  end

  def netlink({:ok, user}, invitation_id) do
    with {:ok, invitation} <- Auth.get_invitation(invitation_id),
         {:ok, %{transaction_id: _}} <-
           @contract.netlink(user.account, invitation.creator_id, invitation.community_id) do
      {:ok, user}
    end
  end

  def netlink({:error, _} = error, _), do: error

  @doc """
  Returns the list of invitations.

  ## Examples

      iex> list_invitations()
      [%Invitation{}, ...]

  """
  def list_invitations do
    Invitation |> Repo.all() |> Repo.preload(:community) |> Repo.preload(:creator)
  end

  @doc """
  Gets a single invitation.

  Raises `Ecto.NoResultsError` if the Invitation does not exist.

  ## Examples

      iex> get_invitation!(123)
      %Invitation{}

      iex> get_invitation!(456)
      ** (Ecto.NoResultsError)
  """
  def get_invitation!(code) do
    {:ok, id} = InvitationId.decode(code)

    Invitation
    |> Repo.get!(id)
    |> Repo.preload(:community)
    |> Repo.preload(:creator)
  end

  def get_invitation(code) do
    case InvitationId.decode(code) do
      {:ok, id} ->
        invite =
          Invitation
          |> Repo.get(id)
          |> Repo.preload(:community)
          |> Repo.preload(:creator)

        if invite do
          {:ok, invite}
        else
          {:error, "Invitation not found"}
        end

      {:error, _} ->
        {:error, "Invitation not found"}
    end
  end

  @doc """
  Finds a single invitation. You need to send an invitation code

  Returns `{:error, :invitation_not_found}` if the Invitation does not exist.

  ## Examples

  iex> find_invitation("aALJc")
  {:ok, %Invitation{}}

  iex> find_invitation("aa")
  {:error, :invitation_not_found}

  iex> find_invitation("not valid invitation code")
  {:error, :decode_failed}
  """
  @spec find_invitation(binary) ::
          {:ok, %Invitation{}} | {:error, :invitation_not_found} | {:error, :decode_failed}
  def find_invitation(code) do
    case InvitationId.decode(code) do
      {:ok, id} ->
        Invitation
        |> Repo.get(id)
        |> Repo.preload(:community)
        |> Repo.preload(:creator)
        |> case do
          %Invitation{} = invitation ->
            {:ok, invitation}

          nil ->
            {:error, :invitation_not_found}
        end

      _ ->
        {:error, :decode_failed}
    end
  end

  def user_invitations(%User{account: account}) do
    Repo.all(from(i in Invitation, where: i.creator_id == ^account))
  end

  @doc """
  Creates a invitation.

  ## Examples

      iex> create_invitation(%{field: value})
      {:ok, %Invitation{}}

      iex> create_invitation(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def create_invitation(attrs \\ %{})

  def create_invitation(%{"community_id" => cmm_id, "creator_id" => c_id} = attrs) do
    # Check if creator belongs to the community
    if Repo.get_by(Network, account_id: c_id, community_id: cmm_id) == nil do
      {:error, "User don't belong to the community"}
    else
      # Check if there are existing invitations already
      with %Invitation{} = invitation <-
             Repo.get_by(Invitation, community_id: cmm_id, creator_id: c_id) do
        {:ok, invitation}
      else
        nil ->
          %Invitation{}
          |> Invitation.changeset(attrs)
          |> Repo.insert()
      end
    end
  end

  def create_invitation(_attrs) do
    {:error, "Can't parse arguments"}
  end

  @doc """
  Returns an `%Ecto.Changeset{}` for tracking invitation changes.

  ## Examples

      iex> change_invitation(invitation)
      %Ecto.Changeset{source: %Invitation{}}

  """
  def change_invitation(%Invitation{} = invitation) do
    Invitation.changeset(invitation, %{})
  end
end
