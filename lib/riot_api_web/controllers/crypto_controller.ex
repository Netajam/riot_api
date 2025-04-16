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
    Logger.error("Invalid payload format for sign action: Expected a JSON object (map), received: #{inspect(params)}")
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid payload format. Expected a JSON object."})
  end
  # endregion

  #region Verify
  # Clause 1: Handles valid input structure
  def verify(conn, %{"signature" => signature_string, "data" => data}) when is_map(data) do
    case Crypto.verify(data, signature_string) do
      true ->
        # Signature is valid (and config was ok)
        send_resp(conn, :no_content, "") # 204 No Content
      false ->
        # Signature is invalid OR there was a config error during verification
        conn
        |> put_status(:bad_request)
        |> json(%{error: "Invalid signature"}) # 400 Bad Request
    end
  end

  # Clause 2: Handles data not being a map
  def verify(conn, %{"signature" => _signature, "data" => not_a_map}) do
     Logger.warning("Received verify request where 'data' is not a map: #{inspect(not_a_map)}")
     conn
     |> put_status(:bad_request)
     |> json(%{error: "Invalid payload: 'data' must be an object"})
  end

  # Clause 3: Handles missing keys
  def verify(conn, _params) do
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid payload: requires 'signature' and 'data' keys"})
  end
  # --- endregion ---


  # region Encrypt
  def encrypt(conn, params) when is_map(params) do
    encrypted_data = Crypto.encrypt(params)
    json(conn, encrypted_data)
 end

 def encrypt(conn, params) do
    Logger.error("Invalid payload format for encrypt action: Expected a JSON object (map), received: #{inspect(params)}")
    conn
    |> put_status(:bad_request)
    |> json(%{error: "Invalid payload format. Expected a JSON object."})
 end
 # endregion

 # region Decrypt
 def decrypt(conn, params) when is_map(params) do
   case Crypto.decrypt(params) do
     {:ok, decrypted_data} ->
       json(conn, decrypted_data)
     {:error, reason} ->
       # Log the specific reason from the crypto module
       Logger.error("Decryption failed: #{inspect(reason)}")
       conn
       |> put_status(:bad_request) # 400 is appropriate for bad input data
       |> json(%{error: "Decryption failed or invalid data provided"})
   end
 end

 def decrypt(conn, params) do
   Logger.error("Invalid payload format for decrypt action: Expected a JSON object (map), received: #{inspect(params)}")
   conn
   |> put_status(:bad_request)
   |> json(%{error: "Invalid payload format. Expected a JSON object."})
 end
 # endregion

end
