defmodule EHealth.Employee.UserRoleCreator do
  @moduledoc """
  Creates or updates user roles in Mithril
  """

  alias EHealth.API.PRM
  alias EHealth.API.Mithril

  require Logger

  def create({:ok, %{"data" => employee}} = data, headers) do
    party_id = Map.fetch!(employee, "party_id")
    client_id = Map.fetch!(employee, "legal_entity_id")
    employee_type = Map.fetch!(employee, "employee_type")
    with {:ok, party_users} <- PRM.get_party_users_by_party_id(party_id, headers),
         {:ok, roles} <- Mithril.get_roles_by_name(employee_type, headers),
         role_id <- find_role_id_by_employee_type(roles),
         :ok <- add_oauth_users_role(party_users, role_id, client_id, party_id, headers)
    do
      data
    end
  end
  def create(err, _headers), do: err

  def find_role_id_by_employee_type(%{"data" => []}) do
    {:error, :invalid_role}
  end
  def find_role_id_by_employee_type(%{"data" => roles}) do
    roles
    |> List.first()
    |> Map.fetch!("id")
  end

  def add_oauth_users_role(%{"data" => party_users}, role_id, client_id, _, headers) when length(party_users) > 0 do
    Enum.each(party_users, fn(%{"user_id" => user_id}) ->
      user_id
      |> Mithril.get_user_roles([role_id: role_id], headers)
      |> create_user_role(user_id, role_id, client_id, headers)
    end)
  end
  def add_oauth_users_role(%{"data" => _}, _, _, party_id, _) do
    Logger.error("Empty party users by party_id #{party_id}. Cannot create new roles")
    :ok
  end

  @doc """
  User role doen't exists. Creates new user role
  """
  def create_user_role({:ok, %{"data" => []}}, user_id, role_id, client_id, headers) do
    role = %{
      "role_id" => role_id,
      "client_id" => client_id,
    }
    Mithril.create_user_role(user_id, role, headers)
  end

  @doc """
  User role exists. Skip creation
  """
  def create_user_role({:ok, _}, _user_id, _role_id, _client_id, _headers), do: :ok

  @doc """
  Failed to get User roles from OAuth. Ignored and creates new role for user.
  """
  def create_user_role({:error, reason}, user_id, role_id, client_id, headers) do
    Logger.error(fn ->
      "Cannot get user roles for user #{user_id}. Creates role for user. Response: #{inspect reason}"
    end)
    create_user_role({:ok, %{"data" => []}}, user_id, role_id, client_id, headers)
  end
end
