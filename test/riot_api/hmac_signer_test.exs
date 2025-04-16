defmodule RiotApi.Crypto.HmacSignerTest do
  use ExUnit.Case, async: true
  alias RiotApi.Crypto.HmacSigner

  @test_secret_hex "0ae5e796b8ed60750af2fa49a6ab6d2a74fa425a792cf0a8ab11cba7550de86a"
  @test_secret_binary Base.decode16!(@test_secret_hex, case: :lower)

  # Data
  @test_data_simple %{"message" => "hello", "id" => 123}
  @test_data_map1 %{"a" => 1, "b" => 2}
  @test_data_map2 %{"b" => 2, "a" => 1}
  @nested_data1 %{ "user" => %{ "name" => "Ciboulette", "id" => 101 }, "settings" => %{ "theme" => "dark", "notifications" => true }, "status" => "active" }
  @nested_data2 %{ "status" => "active", "settings" => %{ "notifications" => true, "theme" => "dark" }, "user" => %{ "id" => 101, "name" => "Ciboulette" } }

  describe "sign/2" do
    test "generates a predictable base64 signature for known data" do
      expected_signature = "iUIbZzUqZVfaq/ZGXjAGecVWGlwCiTzaFcvAj04p1tE="
      assert HmacSigner.sign(@test_data_simple, @test_secret_binary) == expected_signature
    end

    test "generates the same signature for maps with different key order" do
      signature1 = HmacSigner.sign(@test_data_map1, @test_secret_binary)
      signature2 = HmacSigner.sign(@test_data_map2, @test_secret_binary)
      assert signature1 == signature2
    end

    test "generates consistent signature for nested maps with different key order" do
      signature1 = HmacSigner.sign(@nested_data1, @test_secret_binary)
      signature2 = HmacSigner.sign(@nested_data2, @test_secret_binary)

      assert signature1 == signature2
      assert is_binary(signature1) and String.length(signature1) > 0
    end
  end
end
