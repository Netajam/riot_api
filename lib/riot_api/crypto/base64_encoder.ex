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
end
