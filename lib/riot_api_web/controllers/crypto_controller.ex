defmodule RiotApiWeb.CryptoController do
  use RiotApiWeb, :controller
  require Logger
  alias RiotApi.Crypto
  
  def sign(conn, params) do
    secret_key = "TEMPORARY_SECRET"
    signature = Crypto.sign(params, secret_key)
    json(conn, %{signature: signature})  end
end
