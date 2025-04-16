defmodule RiotApi.Crypto.HmacSignerTest do
  use ExUnit.Case, async: true

  alias RiotApi.Crypto.HmacSigner

  @test_secret "0ae5e796b8ed60750af2fa49a6ab6d2a74fa425a792cf0a8ab11cba7550de86a"

  describe "sign function" do
    test "generates a predictable base64 signature for known data" do
      data = %{"message" => "hello", "id" => 123}
      expected_signature = "7zbw+80Id0pWu1uuVPnE1ppEWdHiwAk3JmE2Ib2mwEw="
      assert HmacSigner.sign(data, @test_secret) == expected_signature
    end

    test "generates the same signature for maps with different key order" do
      data1 = %{"a" => 1, "b" => 2}
      data2 = %{"b" => 2, "a" => 1}
      assert HmacSigner.sign(data1, @test_secret) == HmacSigner.sign(data2, @test_secret)
    end
    test "generates consistent signature for nested maps with different key order" do
      # Data structure 1
      nested_data1 = %{
        "user" => %{
          "name" => "Ciboulette",
          "id" => 101
        },
        "settings" => %{
          "theme" => "dark",
          "notifications" => true
        },
        "status" => "active"
      }

      # Data structure 2 - Same data, different key order at top and nested levels
      nested_data2 = %{
        "status" => "active",
        "settings" => %{
          "notifications" => true,
          "theme" => "dark"
        },
        "user" => %{
          "id" => 101,
          "name" => "Ciboulette"
        }
      }

      # Sign both versions
      signature1 = HmacSigner.sign(nested_data1, @test_secret)
      signature2 = HmacSigner.sign(nested_data2, @test_secret)

      # Assert the signatures are identical
      assert signature1 == signature2

      # Optional: check it's not nil/empty and looks like Base64
      assert is_binary(signature1) and String.length(signature1) > 0
      assert signature1 =~ ~r/^[A-Za-z0-9+\/=]+$/
    end
  end

end
