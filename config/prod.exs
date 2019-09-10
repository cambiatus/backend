use Mix.Config

config :bespiral, BeSpiralWeb.Endpoint,
  http: [port: 8025],
  url: [host: System.get_env("HOSTNAME"), port: 80],
  server: true,
  code_reloader: false

# cache_static_manifest: "priv/static/cache_manifest.json"

# Do not print debug messages in production
config :logger, level: :info

config :bespiral, BeSpiral.Mailer,
  adapter: Bamboo.SendGridAdapter,
  api_key: System.get_env("SENDGRID_KEY")

config :bespiral, BeSpiral.Mailer, adapter: Bamboo.SendGridAdapter

config :bespiral, :ipfs, conn: %{host: System.get_env("IPFS_URL"), port: 5001}

config :bespiral, BeSpiral.Chat.ApiHttp,
  chat_base_url: System.get_env("CHAT_BASE_URL"),
  chat_token: System.get_env("CHAT_TOKEN"),
  chat_user_id: System.get_env("CHAT_USER_ID"),
  chat_user_role: System.get_env("CHAT_USER_ROLE")

config :bespiral, :eosrpc_wallet, EOSRPC.Wallet
config :bespiral, :eosrpc_helper, EOSRPC.Helper
config :bespiral, :contract, BeSpiral.Eos
config :bespiral, :chat_api, BeSpiral.Chat.ApiHttp

config :bespiral, BeSpiral.Eos,
  bespiral_wallet: "default",
  bespiral_wallet_pass: System.get_env("BESPIRAL_WALLET_PASSWORD"),
  bespiral_account: "bespiral",
  mcc_contract: "bespiral",
  bespiral_cmm: "BES"

config :eosrpc, EOSRPC.Wallet, url: System.get_env("EOSIO_WALLET_URL")

config :eosrpc, EOSRPC.Chain, url: System.get_env("EOSIO_URL")

config :sentry,
  dsn: "https://cf10887ac4c346ebb26cbc3522578465@sentry.io/1467632",
  environment_name: :prod,
  enable_source_code_context: true,
  root_source_code_path: File.cwd!(),
  tags: %{
    env: "production",
    url: System.get_env("HOSTNAME")
  },
  included_environments: [:prod]

# ## SSL Support
#
# To get SSL working, you will need to add the `https` key
# to the previous section and set your `:url` port to 443:
#
#     config :bespiral, BeSpiralWeb.Endpoint,
#       ...
#       url: [host: "example.com", port: 443],
#       https: [:inet6,
#               port: 443,
#               keyfile: System.get_env("SOME_APP_SSL_KEY_PATH"),
#               certfile: System.get_env("SOME_APP_SSL_CERT_PATH")]
#
# Where those two env variables return an absolute path to
# the key and cert in disk or a relative path inside priv,
# for example "priv/ssl/server.key".
#
# We also recommend setting `force_ssl`, ensuring no data is
# ever sent via http, always redirecting to https:
#
#     config :bespiral, BeSpiralWeb.Endpoint,
#       force_ssl: [hsts: true]
#
# Check `Plug.SSL` for all available options in `force_ssl`.

# ## Using releases
#
# If you are doing OTP releases, you need to instruct Phoenix
# to start the server for all endpoints:
#
config :phoenix, :serve_endpoints, true
#
# Alternatively, you can configure exactly which server to
# start per endpoint:
#
#     config :bespiral, BeSpiralWeb.Endpoint, server: true
#

# Finally import the config/prod.secret.exs
# which should be versioned separately.
# import_config "prod.secret.exs"
config :bespiral, BeSpiral.Notifications, adapter: BeSpiral.Notifications.HttpAdapter

## configure push notifs
config :web_push_encryption, :vapid_details,
  subject: System.get_env("HOSTNAME"),
  public_key: System.get_env("PUSH_PUBLIC_KEY"),
  private_key: System.get_env("PUSH_PRIVATE_KEY")
