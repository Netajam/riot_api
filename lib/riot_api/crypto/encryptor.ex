defmodule RiotApi.Crypto.Encryptor do
  @callback encrypt(data :: map()) :: map()
end
