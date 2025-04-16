# test/riot_api/crypto/base64_encoder_test.exs
defmodule RiotApi.Crypto.Base64EncoderTest do
  use ExUnit.Case, async: true

  alias RiotApi.Crypto.Base64Encoder
  alias Jason
  import ExUnit.CaptureLog

  describe "encrypt/1" do
    test "returns an empty map when given an empty map" do
      assert Base64Encoder.encrypt(%{}) == %{}
    end

    test "encodes basic JSON-serializable types correctly" do
      input = %{ "string" => "hello", "integer" => 123, "float" => 45.6, "boolean_true" => true, "boolean_false" => false, "atom_nil" => nil, "list" => [1, "two", true] }
      expected = %{ "string" => Base.encode64(Jason.encode!("hello")), "integer" => Base.encode64(Jason.encode!(123)), "float" => Base.encode64(Jason.encode!(45.6)), "boolean_true" => Base.encode64(Jason.encode!(true)), "boolean_false" => Base.encode64(Jason.encode!(false)), "atom_nil" => Base.encode64(Jason.encode!(nil)), "list" => Base.encode64(Jason.encode!([1, "two", true])) }
      assert Base64Encoder.encrypt(input) == expected
    end

    test "encodes nested maps correctly" do
      input = %{"user" => %{"name" => "Lucho", "id" => 789}}
      expected = %{ "user" => Base.encode64(Jason.encode!(%{"name" => "Lucho", "id" => 789})) }
      assert Base64Encoder.encrypt(input) == expected
    end

    test "encodes non-JSON-serializable function using inspect and logs warning" do
      my_fun = fn -> :ok end
      input = %{"function" => my_fun}
      expected_value = Base.encode64(inspect(my_fun))

      log_output = capture_log(fn -> assert Base64Encoder.encrypt(input) == %{"function" => expected_value} end)
      assert log_output =~ "Could not JSON encode value for key \"function\""
      assert log_output =~ "[warning]"
    end

    test "encodes non-JSON-serializable PID using inspect and logs warning" do
      pid = self()
      input = %{"process_id" => pid}
      expected_value = Base.encode64(inspect(pid))

      log_output = capture_log(fn -> assert Base64Encoder.encrypt(input) == %{"process_id" => expected_value} end)
      assert log_output =~ "Could not JSON encode value for key \"process_id\""
      assert log_output =~ "[warning]"
    end

     test "encodes non-JSON-serializable tuple using inspect and logs warning" do
       tuple = {:a, 1}
       input = %{"tuple_data" => tuple}
       expected_value = Base.encode64(inspect(tuple))

       log_output = capture_log(fn -> assert Base64Encoder.encrypt(input) == %{"tuple_data" => expected_value} end)
       assert log_output =~ "Could not JSON encode value for key \"tuple_data\""
       assert log_output =~ "[warning]"
     end

    test "handles map with mixed serializable and non-serializable values" do
      my_fun = fn x -> x * x end
      input = %{ "name" => "Mixed Data", "calculator" => my_fun, "count" => 99 }

      expected = %{
        "name" => Base.encode64(Jason.encode!("Mixed Data")),
        # --- Use inspect/1 for expected value calculation ---
        "calculator" => Base.encode64(inspect(my_fun)),
        "count" => Base.encode64(Jason.encode!(99))
      }

      log_output = capture_log(fn -> assert Base64Encoder.encrypt(input) == expected end)
      assert log_output =~ "Could not JSON encode value for key \"calculator\""
      refute log_output =~ "Could not JSON encode value for key \"name\""
      refute log_output =~ "Could not JSON encode value for key \"count\""
    end

    test "preserves original map key types" do
       # Input map with mixed key types
       input = %{:key1 => "v1", :key2 => "v2", "key3" => "v3"}
       result = Base64Encoder.encrypt(input)

       assert Map.has_key?(result, :key1)
       assert Map.has_key?(result, :key2)
       assert Map.has_key?(result, "key3")
       assert map_size(result) == 3

       # Check values using correct keys
       assert result[:key1] == Base.encode64(Jason.encode!("v1"))
       assert result[:key2] == Base.encode64(Jason.encode!("v2"))
       assert result["key3"] == Base.encode64(Jason.encode!("v3"))
    end
  end
end
