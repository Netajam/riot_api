defmodule RiotApi.Crypto.Encryptor do
  @callback encrypt(data :: map()) :: map()
  @callback decrypt(data :: map()) :: {:ok, map()} | {:error, any()}
end
