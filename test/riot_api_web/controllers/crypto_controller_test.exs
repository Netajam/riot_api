defmodule RiotApiWeb.CryptoControllerTest do
  use ExUnit.Case, async: true
  use RiotApiWeb.ConnCase

  @endpoint RiotApiWeb.Endpoint
  @api_path "/api/v1/sign"

  
  ## region Test Data
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
  ## endregion TestData

  # === /api/v1/sign Tests ===
  describe "POST /api/v1/sign" do

    test "returns 200 and signature for valid JSON object payload", %{conn: conn} do
      conn = post(conn, @api_path, @sign_data)

      assert conn.status == 200
      response = json_response(conn, 200)
      assert Map.has_key?(response, "signature")
      assert is_binary(response["signature"])
    end

    test "generates consistent signature regardless of key order", %{conn: conn} do
      conn1 = post(conn, @api_path, @sign_data)
      signature1 = json_response(conn1, 200)["signature"]

      conn2 = post(conn, @api_path, @sign_data_reordered) # Same data, different key order
      signature2 = json_response(conn2, 200)["signature"]

      assert signature1 == signature2
      assert signature1 != nil
    end


    test "signs an empty JSON object", %{conn: conn} do
      conn = post(conn, @api_path, %{})

      assert conn.status == 200
      response = json_response(conn, 200)
      assert Map.has_key?(response, "signature")
      assert is_binary(response["signature"])
    end
  end
end
