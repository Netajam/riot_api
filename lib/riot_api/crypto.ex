defmodule RiotApi.Crypto do
  @signer RiotApi.Crypto.HmacSigner

  defdelegate sign(data, secret), to: @signer
end
