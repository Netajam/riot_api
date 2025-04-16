defmodule RiotApi.Crypto.HmacSignerTest do
  use ExUnit.Case, async: true
  alias RiotApi.Crypto.HmacSigner

  @test_secret_hex "0ae5e796b8ed60750af2fa49a6ab6d2a74fa425a792cf0a8ab11cba7550de86a"
  @test_secret_binary Base.decode16!(@test_secret_hex, case: :lower)
  @wrong_secret_binary Base.decode16!("1111111111111111111111111111111111111111111111111111111111111111", case: :lower)

  # Data
  @test_data_simple %{"message" => "hello", "id" => 123}
  @test_data_map1 %{"a" => 1, "b" => 2}
  @test_data_map2 %{"b" => 2, "a" => 1}
  @nested_data1 %{ "user" => %{ "name" => "Ciboulette", "id" => 101 }, "settings" => %{ "theme" => "dark", "notifications" => true }, "status" => "active" }
  @nested_data2 %{ "status" => "active", "settings" => %{ "notifications" => true, "theme" => "dark" }, "user" => %{ "id" => 101, "name" => "Ciboulette" } }
  @empty_data %{}

  # region Sign Tests
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
  # endregion
  # region Verify Tests
    describe "verify/3" do
      # Setup block to generate valid signatures needed by the tests
      setup do
        valid_signature_simple = HmacSigner.sign(@test_data_simple, @test_secret_binary)
        valid_signature_nested = HmacSigner.sign(@nested_data1, @test_secret_binary)
        valid_signature_empty = HmacSigner.sign(@empty_data, @test_secret_binary)

        %{
          valid_signature_simple: valid_signature_simple,
          valid_signature_nested: valid_signature_nested,
          valid_signature_empty: valid_signature_empty
        }
      end

      test "returns true for valid data, signature, and secret", %{valid_signature_simple: sig} do
        assert HmacSigner.verify(@test_data_simple, sig, @test_secret_binary) == true
      end

      test "returns true for valid nested data, signature, and secret", %{valid_signature_nested: sig} do
         assert HmacSigner.verify(@nested_data1, sig, @test_secret_binary) == true
      end

       test "returns true for valid empty data, signature, and secret", %{valid_signature_empty: sig} do
         assert HmacSigner.verify(@empty_data, sig, @test_secret_binary) == true
       end

      test "returns true for valid signature when data key order differs", %{valid_signature_simple: sig} do
        reordered_simple_data = %{"id" => 123, "message" => "hello"}
        assert HmacSigner.verify(reordered_simple_data, sig, @test_secret_binary) == true
      end

       test "returns true for valid signature when nested data key order differs", %{valid_signature_nested: sig} do
         assert HmacSigner.verify(@nested_data2, sig, @test_secret_binary) == true
       end

      test "returns false for tampered data", %{valid_signature_simple: sig} do
        tampered_data = Map.put(@test_data_simple, "message", "goodbye")
        assert HmacSigner.verify(tampered_data, sig, @test_secret_binary) == false
      end

      test "returns false for incorrect signature", %{valid_signature_simple: _sig} do
         incorrect_signature = Base.encode64("completelywrong")
         assert HmacSigner.verify(@test_data_simple, incorrect_signature, @test_secret_binary) == false
      end

      test "returns false for invalid signature encoding (not Base64)", %{valid_signature_simple: _sig} do
         invalid_encoding = "!!! Definitely Not Base64 !!!"
         assert HmacSigner.verify(@test_data_simple, invalid_encoding, @test_secret_binary) == false
      end

      test "returns false for incorrect secret", %{valid_signature_simple: sig} do
        assert HmacSigner.verify(@test_data_simple, sig, @wrong_secret_binary) == false
      end
    end
  # endregion
end
