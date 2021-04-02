defmodule Cambiatus.Auth.Ecdsa do
  @moduledoc """
  This module is a wrapper for eosjs-ecc utilizing NIF
  """

  def verify_signature(account, signature, phrase) do
    {"app", :publicKeyPoints}
    |> NodeJS.call([signature, phrase])
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
    {"app", :accountToPublicKey}
    |> NodeJS.call([account])
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
end
