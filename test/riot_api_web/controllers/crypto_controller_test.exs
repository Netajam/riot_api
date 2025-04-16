defmodule RiotApiWeb.CryptoControllerTest do
  use ExUnit.Case, async: true
  use RiotApiWeb.ConnCase

  @endpoint RiotApiWeb.Endpoint
  @encrypt_api_path "/api/v1/encrypt"
  @decrypt_api_path "/api/v1/decrypt"
  @sign_api_path "/api/v1/sign"
  @verify_api_path "/api/v1/verify"



  ## region Test Data
  ## region --- Data for /sign ---

  @sign_data %{
    "data" => %{
      "user_name" => "Donatello",
      "message" => "I like Pizza",
      "timestamp" => 1_713_850_560,
      "action" => "post_comment"
    },
    "meta" => %{
      "signature" => "6ed54b6e63e4cfe478552eaed26d0b592f9d9d2352cc92f7a08beb6990231415",
      "algorithm" => "ed25519",
      "version" => "1.0"
    }
  }

  @sign_data_reordered %{
    "meta" => %{
      "version" => "1.0",
      "algorithm" => "ed25519",
      "signature" => "6ed54b6e63e4cfe478552eaed26d0b592f9d9d2352cc92f7a08beb6990231415"
    },
    "data" => %{
      "action" => "post_comment",
      "timestamp" => 1_713_850_560,
      "message" => "I like Pizza",
      "user_name" => "Donatello"
    }
  }
   # endregion
  ## region Data for /encrypt & /decrypt
   @encrypt_data_basic %{
    "string" => "hello world",
    "integer" => 987,
    "boolean" => true,
    "list" => ["a", 1, nil],
    "nothing" => nil
  }

  @expected_encrypted_basic %{
    "string" => Base.encode64(Jason.encode!("hello world")),
    "integer" => Base.encode64(Jason.encode!(987)),
    "boolean" => Base.encode64(Jason.encode!(true)),
    "list" => Base.encode64(Jason.encode!(["a", 1, nil])),
    "nothing" => Base.encode64(Jason.encode!(nil))
  }

  @encrypt_data_nested %{
    "id" => "xyz-789",
    "details" => %{
      "status" => "active",
      "count" => 55
    }
  }

  @expected_encrypted_nested %{
    "id" => Base.encode64(Jason.encode!("xyz-789")),
    "details" => Base.encode64(Jason.encode!(%{ "status" => "active", "count" => 55 }))
  }

  @original_basic %{
    "string" => "hello world",
    "integer" => 987,
    "boolean" => true,
    "list" => ["a", 1, nil],
    "nothing" => nil
  }
  @expected_encrypted_basic %{
    "string" => Base.encode64(Jason.encode!("hello world")),
    "integer" => Base.encode64(Jason.encode!(987)),
    "boolean" => Base.encode64(Jason.encode!(true)),
    "list" => Base.encode64(Jason.encode!(["a", 1, nil])),
    "nothing" => Base.encode64(Jason.encode!(nil))
  }

  @original_nested %{
    "id" => "xyz-789",
    "details" => %{ "status" => "active", "count" => 55 }
  }
  @expected_encrypted_nested %{
    "id" => Base.encode64(Jason.encode!("xyz-789")),
    "details" => Base.encode64(Jason.encode!(%{ "status" => "active", "count" => 55 }))
  }
  @empty_data %{}
  ## endregion
  # region data for /verify
  @verify_data %{ "message" => "Verify this payload", "timestamp" => 1616161616 }
  @verify_data_reordered %{ "timestamp" => 1616161616, "message" => "Verify this payload" }
  ## endregion
  ## endregion TestData

  ## region === /api/v1/sign Tests ===
  describe "POST /api/v1/sign" do

    test "returns 200 and signature for valid JSON object payload", %{conn: conn} do
      conn = post(conn, @sign_api_path, @sign_data)

      assert conn.status == 200
      response = json_response(conn, 200)
      assert Map.has_key?(response, "signature")
      assert is_binary(response["signature"])
    end

    test "generates consistent signature regardless of key order", %{conn: conn} do
      conn1 = post(conn, @sign_api_path, @sign_data)
      signature1 = json_response(conn1, 200)["signature"]

      conn2 = post(conn, @sign_api_path, @sign_data_reordered) # Same data, different key order
      signature2 = json_response(conn2, 200)["signature"]

      assert signature1 == signature2
      assert signature1 != nil
    end


    test "signs an empty JSON object", %{conn: conn} do
      conn = post(conn, @sign_api_path, %{})

      assert conn.status == 200
      response = json_response(conn, 200)
      assert Map.has_key?(response, "signature")
      assert is_binary(response["signature"])
    end
  end
  ## endregion
  ## region === /api/v1/encrypt Tests ===
    describe "POST " <> @encrypt_api_path do
      test "returns 200 and encrypts basic JSON types correctly", %{conn: conn} do
        conn = post(conn, @encrypt_api_path, @encrypt_data_basic)

        assert conn.status == 200
        response = json_response(conn, 200)
        assert response == @expected_encrypted_basic
      end

      test "returns 200 and encrypts nested maps correctly", %{conn: conn} do
        conn = post(conn, @encrypt_api_path, @encrypt_data_nested)

        assert conn.status == 200
        response = json_response(conn, 200)
        assert response == @expected_encrypted_nested
      end

      test "returns 200 and empty map for an empty JSON object payload", %{conn: conn} do
        conn = post(conn, @encrypt_api_path, @empty_data) # Use @empty_data

        assert conn.status == 200
        response = json_response(conn, 200)
        assert response == %{}
      end
  ## endregion
end
# region Decrypt Tests ===
  describe "POST " <> @decrypt_api_path do
    test "returns 200 and decrypts previously encrypted basic types", %{conn: conn} do
      conn = post(conn, @decrypt_api_path, @expected_encrypted_basic)
      assert conn.status == 200
      assert json_response(conn, 200) == @original_basic
    end

    test "returns 200 and decrypts previously encrypted nested maps", %{conn: conn} do
      conn = post(conn, @decrypt_api_path, @expected_encrypted_nested)
      assert conn.status == 200
      assert json_response(conn, 200) == @original_nested
    end

    test "returns 200 and leaves non-encrypted values unchanged", %{conn: conn} do
      mixed_input = %{
        "encrypted_string" => @expected_encrypted_basic["string"],
        "plain_string" => "keep me as is",
        "plain_number" => 12345,
        "encrypted_list" => @expected_encrypted_basic["list"],
        "plain_boolean" => false
      }
      expected_output = %{
        "encrypted_string" => @original_basic["string"],
        "plain_string" => "keep me as is",
        "plain_number" => 12345,
        "encrypted_list" => @original_basic["list"],
        "plain_boolean" => false
      }

      conn = post(conn, @decrypt_api_path, mixed_input)
      assert conn.status == 200
      assert json_response(conn, 200) == expected_output
    end

    test "returns 200 and leaves invalid base64 strings unchanged", %{conn: conn} do
       invalid_b64_input = %{
         "valid_encrypted" => @expected_encrypted_basic["string"],
         "invalid_string" => "!!ThisIsNotBase64!!",
         "another_plain" => "hello"
       }
       expected_output = %{
          "valid_encrypted" => @original_basic["string"], # Use defined original value
          "invalid_string" => "!!ThisIsNotBase64!!",
          "another_plain" => "hello"
       }

       conn = post(conn, @decrypt_api_path, invalid_b64_input)
       assert conn.status == 200
       assert json_response(conn, 200) == expected_output
    end

    test "returns 200 and empty map for an empty JSON object payload", %{conn: conn} do
       conn = post(conn, @decrypt_api_path, @empty_data)
       assert conn.status == 200
       assert json_response(conn, 200) == %{}
     end
  end
  # endregion
    # === /api/v1/verify Tests ===
      describe "POST " <> @verify_api_path do
        setup %{conn: conn} do
          conn_sign_main = post(conn, @sign_api_path, @verify_data)
          valid_sig_main = json_response(conn_sign_main, 200)["signature"]

          # Sign the empty data
          conn_sign_empty = post(conn, @sign_api_path, @empty_data)
          valid_sig_empty = json_response(conn_sign_empty, 200)["signature"]

          # Check if signatures were actually generated
          if is_nil(valid_sig_main) or is_nil(valid_sig_empty) do
            raise "Failed to generate valid signatures in setup block for verify tests. Check /sign endpoint functionality and test secret."
          end

          # Pass signatures into the test context
          %{
            conn: conn,
            valid_sig_main: valid_sig_main,
            valid_sig_empty: valid_sig_empty
          }
        end

        test "returns 204 No Content for valid signature and data", %{conn: conn, valid_sig_main: sig} do
          payload = %{"signature" => sig, "data" => @verify_data}
          conn = post(conn, @verify_api_path, payload)
          assert conn.status == 204
          assert conn.resp_body == ""
        end

        test "returns 204 No Content for valid signature when data key order differs", %{conn: conn, valid_sig_main: sig} do
          payload = %{"signature" => sig, "data" => @verify_data_reordered} # Use same sig, reordered data
          conn = post(conn, @verify_api_path, payload)
          assert conn.status == 204
        end

         test "returns 204 No Content for valid signature and empty data object", %{conn: conn, valid_sig_empty: sig} do
           payload = %{"signature" => sig, "data" => @empty_data}
           conn = post(conn, @verify_api_path, payload)
           assert conn.status == 204
         end

        test "returns 400 Bad Request for invalid signature string", %{conn: conn, valid_sig_main: _sig} do
           payload = %{"signature" => "a" <> Base.encode64("clearlywrong") <> "z", "data" => @verify_data}
           conn = post(conn, @verify_api_path, payload)
           assert conn.status == 400
           assert json_response(conn, 400) == %{"error" => "Invalid signature"}
        end

         test "returns 400 Bad Request for tampered data", %{conn: conn, valid_sig_main: sig} do
           tampered_data = Map.put(@verify_data, "message", "Tampered Message!")
           payload = %{"signature" => sig, "data" => tampered_data}
           conn = post(conn, @verify_api_path, payload)
           assert conn.status == 400
           assert json_response(conn, 400) == %{"error" => "Invalid signature"}
        end

        test "returns 400 Bad Request when signature key is missing", %{conn: conn} do
           payload = %{"data" => @verify_data} # Missing "signature"
           conn = post(conn, @verify_api_path, payload)
           assert conn.status == 400
           assert json_response(conn, 400) == %{"error" => "Invalid payload: requires 'signature' and 'data' keys"}
         end

        test "returns 400 Bad Request when data key is missing", %{conn: conn, valid_sig_main: sig} do
           payload = %{"signature" => sig} # Missing "data"
           conn = post(conn, @verify_api_path, payload)
           assert conn.status == 400
           assert json_response(conn, 400) == %{"error" => "Invalid payload: requires 'signature' and 'data' keys"}
         end

        test "returns 400 Bad Request when data value is not an object", %{conn: conn, valid_sig_main: sig} do
           payload = %{"signature" => sig, "data" => "this is just a string"}
           conn = post(conn, @verify_api_path, payload)
           assert conn.status == 400
           assert json_response(conn, 400) == %{"error" => "Invalid payload: 'data' must be an object"}
         end

         test "returns 400 Bad Request when HMAC secret is not configured", %{conn: conn, valid_sig_main: sig} do
           original_key = Application.get_env(:riot_api, :hmac_secret)
           Application.delete_env(:riot_api, :hmac_secret)
           on_exit(fn -> if original_key, do: Application.put_env(:riot_api, :hmac_secret, original_key) end)
           payload = %{"signature" => sig, "data" => @verify_data}
           conn = post(conn, @verify_api_path, payload)
           assert conn.status == 400
           assert json_response(conn, 400) == %{"error" => "Invalid signature"}
         end

      end
      # endregion
end
