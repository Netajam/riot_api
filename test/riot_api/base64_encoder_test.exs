defmodule RiotApi.Crypto.Base64EncoderTest do
  use ExUnit.Case, async: true

  alias RiotApi.Crypto.Base64Encoder
  alias Jason
  import ExUnit.CaptureLog
  # --- Test Data ---
  @original_basic %{
    "string" => "hello",
    "integer" => 123,
    "float" => 45.6,
    "boolean_true" => true,
    "boolean_false" => false,
    "atom_nil" => nil,
    "list" => [1, "two", true]
  }
  @encrypted_basic %{
    "string" => Base.encode64(Jason.encode!("hello")),
    "integer" => Base.encode64(Jason.encode!(123)),
    "float" => Base.encode64(Jason.encode!(45.6)),
    "boolean_true" => Base.encode64(Jason.encode!(true)),
    "boolean_false" => Base.encode64(Jason.encode!(false)),
    "atom_nil" => Base.encode64(Jason.encode!(nil)),
    "list" => Base.encode64(Jason.encode!([1, "two", true]))
  }

  @original_nested %{"user" => %{"name" => "Lucho", "id" => 789}}
  @encrypted_nested %{ "user" => Base.encode64(Jason.encode!(@original_nested["user"])) }

#region Encrypt Tests
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
  # endregion 
  # region Decrypt Tests
  describe "decrypt/1" do
    test "returns {:ok, %{}} for an empty map" do
      assert Base64Encoder.decrypt(%{}) == {:ok, %{}}
    end

    test "decrypts basic JSON-serializable types correctly" do
      # Use the pre-calculated encrypted data as input
      assert Base64Encoder.decrypt(@encrypted_basic) == {:ok, @original_basic}
    end

    test "decrypts nested maps correctly" do
      # Use the pre-calculated encrypted nested data as input
      assert Base64Encoder.decrypt(@encrypted_nested) == {:ok, @original_nested}
    end

    test "leaves non-string values unchanged" do
      input = %{"age" => 30, "active" => true, "score" => 12.5}
      # Expected output is identical to input
      assert Base64Encoder.decrypt(input) == {:ok, input}
    end

    test "leaves non-Base64 strings unchanged" do
      input = %{"name" => "Alice", "id" => "xyz-123", "invalid_b64" => "!!Not Base64!!"}
      # Expected output is identical to input
      assert Base64Encoder.decrypt(input) == {:ok, input}
    end

    test "returns decoded binary for Base64 strings that are not valid JSON" do
      # Base64.encode64("Just a plain string") -> "SnVzdCBhIHBsYWluIHN0cmluZw=="
      input = %{"message" => "SnVzdCBhIHBsYWluIHN0cmluZw=="}
      expected_output = %{"message" => "Just a plain string"}
      assert Base64Encoder.decrypt(input) == {:ok, expected_output}
    end

    test "handles map with mixed encrypted and plain values" do
      # Mix some values from @encrypted_basic with plain values
      input = %{
        "string" => @encrypted_basic["string"], # Encrypted string
        "integer" => 12345, # Plain integer
        "boolean_true" => @encrypted_basic["boolean_true"], # Encrypted boolean
        "extra" => "Keep Me" # Plain string (not valid Base64)
      }

      expected_output = %{
        "string" => @original_basic["string"], # Decrypted string
        "integer" => 12345, # Plain integer untouched
        "boolean_true" => @original_basic["boolean_true"], # Decrypted boolean
        "extra" => "Keep Me" # Plain string untouched
      }

      assert Base64Encoder.decrypt(input) == {:ok, expected_output}
    end

    test "preserves original map key types during decryption" do
       # Create encrypted input with mixed key types
       input = %{
         :key1 => Base.encode64(Jason.encode!("value1")),
         :key2 => "plain string",
         "key3" => Base.encode64(Jason.encode!(%{ "nested" => true }))
       }

       expected_output = %{
         :key1 => "value1",
         :key2 => "plain string", # Untouched because it's not valid Base64
         "key3" => %{ "nested" => true }
       }

       assert Base64Encoder.decrypt(input) == {:ok, expected_output}
       # Verify keys exist with correct types in the result tuple's map
       assert Map.has_key?(elem(Base64Encoder.decrypt(input), 1), :key1)
       assert Map.has_key?(elem(Base64Encoder.decrypt(input), 1), :key2)
       assert Map.has_key?(elem(Base64Encoder.decrypt(input), 1), "key3")
    end
  end
  # endregion
end
