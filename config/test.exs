import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :riot_api, RiotApiWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "epbuqoq0ItWYU8caHLooRS9YUy7vN/u5Y7BdS7MtVhqu8EY6IiMHn64MhKFmSnrb",
  server: false

# In test we don't send emails
config :riot_api, RiotApi.Mailer, adapter: Swoosh.Adapters.Test

# Disable swoosh api client as it is only required for production adapters
config :swoosh, :api_client, false

# Print only warnings and errors during test
config :logger, level: :warning

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
