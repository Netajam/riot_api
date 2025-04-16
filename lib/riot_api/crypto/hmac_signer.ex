defmodule RiotApi.Crypto.HmacSigner do
  @behaviour RiotApi.Crypto.Signer

  @hmac_alg :sha256
  @signature_encoding :base64

  @impl RiotApi.Crypto.Signer
  def sign(data, secret) when is_map(data) and is_binary(secret) do
    # check that all keys are strings
    string_keyed_data = ensure_string_keys(data)
    # Ordering the data, initial order of data not affecting the signature anymore
    canonical_binary = canonicalize(string_keyed_data)
    # Depends on @hmac_alg and :crypto module
    hmac_binary = :crypto.mac(:hmac, @hmac_alg, secret, canonical_binary)
    # Encode the binary
    encode_signature(hmac_binary)
  end

  # Helper functions
  defp ensure_string_keys(map) when is_map(map) do
    Map.new(map, fn {k, v} -> {to_string(k), v} end)
  end

  defp ensure_string_keys(other), do: other

  defp canonicalize(term) do
    :erlang.term_to_binary(term, [:deterministic])
  end

  defp encode_signature(binary) do
    case @signature_encoding do
      :base64 -> Base.encode64(binary)
      :hex -> Base.encode16(binary, case: :lower)
      _ -> binary
    end
  end
end
