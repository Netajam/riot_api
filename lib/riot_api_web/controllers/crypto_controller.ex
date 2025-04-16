defmodule RiotApiWeb.CryptoController do
  use RiotApiWeb, :controller
  require Logger
  alias RiotApi.Crypto
  plug :accepts, ["json"] #check already performed in router.ex but in case router accept other types in the future
  # region Sign function
  def sign(conn, params) when is_map(params) do
    secret_key = Application.get_env(:riot_api, :hmac_secret)
    unless secret_key do
      Logger.error("HMAC Secret Key is not configured!")
      send_resp(conn, :internal_server_error, "{\"error\": \"Server configuration error\"}")
    else
      signature = Crypto.sign(params, secret_key)
      json(conn, %{signature: signature})
    end
  end
  # Case where we don't receive a map from our Parser
  def sign(conn, params) do
    Logger.error("Invalid payload format for sign action: Expected a JSON object (map), received: #{inspect(params)}")
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid payload format. Expected a JSON object."})
  end
  # endregion

end
