defmodule RiotApi.Crypto.HmacSigner do
  import Plug.Crypto, only: [secure_compare: 2]
  @behaviour RiotApi.Crypto.Signer

  @hmac_alg :sha256
  @signature_encoding :base64


  @impl RiotApi.Crypto.Signer
  def sign(data, secret) when is_map(data) and is_binary(secret) do
    string_keyed_data = ensure_string_keys(data)
    canonical_binary = canonicalize(string_keyed_data)
    hmac_binary = :crypto.mac(:hmac, @hmac_alg, secret, canonical_binary)
    # Encode the binary
    encode_signature(hmac_binary)
  end

  @impl RiotApi.Crypto.Signer
  def verify(data, signature, secret) when is_map(data) and is_binary(signature) and is_binary(secret) do
    case decode_signature(signature) do
      {:ok, provided_hmac_binary} ->
        string_keyed_data = ensure_string_keys(data)
        canonical_binary = canonicalize(string_keyed_data)
        expected_hmac_binary = :crypto.mac(:hmac, @hmac_alg, secret, canonical_binary)
        secure_compare(provided_hmac_binary, expected_hmac_binary)
      :error ->
        false
    end
  rescue
     _ -> false
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
  # Helper function for verify
  defp decode_signature(encoded_binary) do
    case @signature_encoding do
      :base64 -> Base.decode64(encoded_binary)
      :hex -> Base.decode16(encoded_binary, case: :lower)
      _ -> {:ok, encoded_binary}
    end
  end
end
