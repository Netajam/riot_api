# Signer Behaviour
defmodule RiotApi.Crypto.Signer do
  @callback sign(data :: map(), secret :: binary()) :: binary()
 # @callback verify(data :: map(), signature :: binary(), secret :: binary()) :: boolean()
end
