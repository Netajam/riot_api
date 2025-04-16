defmodule RiotApi.Crypto.Base64Encoder do
  @behaviour RiotApi.Crypto.Encryptor

  require Logger
  alias Jason

  @impl RiotApi.Crypto.Encryptor
  def encrypt(data) when is_map(data) do
    Enum.into(data, %{}, fn {key, value} ->
      encoded_value =
        try do
          Jason.encode!(value) |> Base.encode64()
        rescue
          exception ->
            Logger.warning("Could not JSON encode value for key #{inspect(key)} (Reason: #{inspect(exception)}), inspecting and encoding.")
            inspect(value) |> Base.encode64()
        end
      {key, encoded_value}
    end)
  end

  @impl RiotApi.Crypto.Encryptor
  def decrypt(data) when is_map(data) do
    try do
      transformed_list = Enum.map(data, fn {key, value} ->
        decoded_value =
          if is_binary(value) do
            case Base.decode64(value) do
              {:ok, decoded_binary} ->
                case Jason.decode(decoded_binary) do
                  {:ok, json_term} -> json_term
                  {:error, _} -> decoded_binary
                end
              :error ->
                # Not valid Base64, return the original value
                value
            end
          else
            # Not a string, return the original value
            value
          end
        {key, decoded_value}
      end)
      decrypted_map = Map.new(transformed_list)
      {:ok, decrypted_map}
    rescue
      e in Jason.DecodeError ->
        Logger.error("Jason decoding failed during decryption: #{inspect(e)}")
        {:error, {:jason_decode, e}}
      e ->
        Logger.error("Unknown error during decryption: #{inspect(e)}")
        {:error, {:unknown, e}}
    end
  end
end
