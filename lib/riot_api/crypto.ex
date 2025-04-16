defmodule RiotApi.Crypto do
  @signer RiotApi.Crypto.HmacSigner
  require Logger

  def sign(data) do
    with {:ok, secret_key_binary} <- fetch_and_decode_secret(),
         signature <- @signer.sign(data, secret_key_binary)
    do
       {:ok, signature}
    else
       {:error, :missing_key} ->
          Logger.error("HMAC Secret Key is not configured!")
          {:error, :config_error}
       {:error, :invalid_hex} ->
          Logger.error("HMAC Secret Key in configuration is not valid Hexadecimal!")
          {:error, :config_error}
    end
  end

  defp fetch_and_decode_secret() do
    case Application.get_env(:riot_api, :hmac_secret) do
      nil ->
        {:error, :missing_key}
      secret_key_hex when is_binary(secret_key_hex) ->
         case Base.decode16(secret_key_hex, case: :lower) do
           {:ok, binary_key} -> {:ok, binary_key}
           :error -> {:error, :invalid_hex}
         end
      _other ->
        Logger.error("HMAC Secret Key in configuration is not a string!")
        {:error, :invalid_hex}
    end
  end
end
