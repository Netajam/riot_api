defmodule RiotApiWeb.CryptoController do
  use RiotApiWeb, :controller
  require Logger
  alias RiotApi.Crypto

  def sign(conn, params) do
    secret_key = Application.get_env(:riot_api, :hmac_secret)
    unless secret_key do
      Logger.error("HMAC Secret Key is not configured!")
      send_resp(conn, :internal_server_error, "{\"error\": \"Server configuration error\"}")
    else
      signature = Crypto.sign(params, secret_key)
      json(conn, %{signature: signature})
    end
  end
end
