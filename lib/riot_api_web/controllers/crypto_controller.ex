defmodule RiotApiWeb.CryptoController do
  use RiotApiWeb, :controller
  require Logger
  alias RiotApi.Crypto
  plug :accepts, ["json"] #check already performed in router.ex but in case router accept other types in the future
  # region Sign function
  def sign(conn, params) when is_map(params) do
    case Crypto.sign(params) do
      {:ok, actual_signature_string} ->
        json(conn, %{signature: actual_signature_string})
      {:error, :config_error} ->
        send_resp(conn, :internal_server_error, "{\"error\": \"Server configuration error\"}")
    end
  end

  # Case where we don't receive a map from our Parser
  def sign(conn, params) do
    IO.inspect(params, label: "SIGN_CLAUSE_2_PARAMS") # Add this line

    Logger.error("Invalid payload format for sign action: Expected a JSON object (map), received: #{inspect(params)}")
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid payload format. Expected a JSON object."})
  end
  # endregion
end
