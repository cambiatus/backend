import Config

# Configuration for runtime environment
# This file is evaluated at runtime and supports dynamic configuration
# It replaces the old config/releases.exs approach

if System.get_env("PHX_SERVER") do
  config :phoenix, :serve_endpoints, true
end

if config_env() == :prod do
  # Database configuration
  database_url =
    System.get_env("DATABASE_URL") ||
      raise """
      environment variable DATABASE_URL is missing.
      For example: ecto://USER:PASS@HOST/DATABASE
      """

  maybe_ipv6 = if System.get_env("ECTO_IPV6") in ~w(true 1), do: [:inet6], else: []

  config :cambiatus, Cambiatus.Repo,
    url: database_url,
    pool_size: String.to_integer(System.get_env("POOL_SIZE") || "10"),
    socket_options: maybe_ipv6

  # Endpoint configuration
  secret_key_base =
    System.get_env("SECRET_KEY_BASE") ||
      raise """
      environment variable SECRET_KEY_BASE is missing.
      You can generate one by calling: mix phx.gen.secret
      """

  host = System.get_env("PHX_HOST") || "localhost"
  port = String.to_integer(System.get_env("PORT") || "4000")

  config :cambiatus, CambiatusWeb.Endpoint,
    url: [host: host, port: 443, scheme: "https"],
    http: [
      ip: {0, 0, 0, 0, 0, 0, 0, 0},
      port: port
    ],
    secret_key_base: secret_key_base,
    server: true

  # EOS/Blockchain configuration
  config :cambiatus, Cambiatus.Eos,
    cambiatus_wallet: System.get_env("EOSIO_WALLET_NAME") || "default",
    cambiatus_wallet_pass: System.get_env("BESPIRAL_WALLET_PASSWORD"),
    cambiatus_account: System.get_env("BESPIRAL_ACCOUNT"),
    mcc_contract: System.get_env("BESPIRAL_CONTRACT"),
    cambiatus_cmm: System.get_env("BESPIRAL_AUTO_INVITE_CMM")

  config :eosrpc, EOSRPC.Wallet, url: System.get_env("EOSIO_WALLET_URL")
  config :eosrpc, EOSRPC.Chain, url: System.get_env("EOSIO_URL")
  config :eosrpc, EOSRPC.Helper, symbol: System.get_env("EOSIO_SYMBOL") || "EOS"

  # Auth secrets
  config :cambiatus, :graphql_secret, System.get_env("GRAPHQL_SECRET")
  config :cambiatus, :auth_salt, System.get_env("USER_SALT")
  config :cambiatus, :auth_salt_email, System.get_env("EMAIL_SALT")

  config :cambiatus, Cambiatus.Auth.InvitationId,
    salt: System.get_env("INVITATION_SALT") || "default-salt"

  # Email configuration
  config :cambiatus, Cambiatus.Mailer,
    adapter: Swoosh.Adapters.AmazonSES,
    region: System.get_env("AWS_SES_REGION"),
    access_key: System.get_env("AWS_SES_ACCESS_KEY"),
    secret: System.get_env("AWS_SES_SECRET_ACCESS_KEY")

  # Sentry configuration
  config :sentry,
    dsn: System.get_env("SENTRY_DSN"),
    environment_name: :prod,
    enable_source_code_context: true,
    root_source_code_path: File.cwd!(),
    tags: %{
      env: "production",
      url: host
    }

  # Push notifications
  config :web_push_encryption, :vapid_details,
    subject: host,
    public_key: System.get_env("PUSH_PUBLIC_KEY"),
    private_key: System.get_env("PUSH_PRIVATE_KEY")

  # Notifications
  config :cambiatus, Cambiatus.Notifications, adapter: Cambiatus.Notifications.HttpAdapter
end
