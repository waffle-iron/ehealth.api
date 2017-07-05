defmodule EHealth.OAuth.API do
  @moduledoc """
  OAuth service layer
  """

  import EHealth.Utils.Connection, only: [get_consumer_id: 1]

  alias EHealth.API.Mithril

  require Logger

  @doc """
  Creates a new Mithril client for MSP after successfully created a new Legal Entity
  """
  def put_client(entity, redirect_uri, headers) do
    client = %{
      "id" => Map.fetch!(entity, "id"),
      "name" => Map.fetch!(entity, "name"),
      "redirect_uri" => redirect_uri,
      "user_id" => get_consumer_id(headers)
    }
    Mithril.put_client(client)
  end

  def create_user(%Ecto.Changeset{valid?: true, changes: %{password: password}}, email, headers) do
    Mithril.create_user(%{"password" => password, "email" => email}, headers)
  end
  def create_user(err, _email, _headers), do: err

  def get_client(id, headers) do
    id
    |> Mithril.get_client(headers)
    |> fetch_client_credentials(id)
  end

  defp fetch_client_credentials({:ok, %{"data" => data}}, id) when is_list(data) do
    data =
      case length(data) > 0 do
        true -> List.first(data)
        false -> %{}
      end

    fetch_client_credentials({:ok, %{"data" => data}}, id)
  end

  defp fetch_client_credentials({:ok, %{"data" => data}}, _id) do
    %{
      "client_id" => Map.get(data, "id"),
      "client_secret" => Map.get(data, "secret"),
      "redirect_uri" => Map.get(data, "redirect_uri")
    }
  end

  defp fetch_client_credentials({:error, response}, id) do
    Logger.error(fn -> "Cannot create or find Mithril client for Legal Entity #{id} Response: #{inspect response}" end)
    nil
  end

end
