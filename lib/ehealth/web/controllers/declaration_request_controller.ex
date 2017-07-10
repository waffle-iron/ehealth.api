defmodule EHealth.Web.DeclarationRequestController do
  @moduledoc false

  use EHealth.Web, :controller
  alias EHealth.DeclarationRequest.API, as: DeclarationRequestAPI

  action_fallback EHealth.Web.FallbackController

  def index(conn, params) do
    declaration_requests = DeclarationRequestAPI.list_declaration_requests(params)
    with {declaration_requests, %Ecto.Paging{} = paging} <- declaration_requests do
      render(conn, "index.json", declaration_requests: declaration_requests, paging: paging)
    end
  end

  def show(conn, %{"declaration_request_id" => id} = params) do
    legal_entity_id = Map.get(params, "legal_entity_id")
    declaration_request = DeclarationRequestAPI.get_declaration_request_by_id!(id, params)
    render(conn, "show.json", declaration_request: declaration_request)
  end

  def create(conn, %{"declaration_request" => declaration_request}) do
    user_id = get_consumer_id(conn.req_headers)
    client_id = get_client_id(conn.req_headers)

    with {:ok, %{finalize: result}} <- DeclarationRequestAPI.create(declaration_request, user_id, client_id) do
      render(conn, "declaration_request.json", declaration_request: result)
    end
  end

  def approve(conn, %{"id" => id} = params) do
    user_id = get_consumer_id(conn.req_headers)

    with {:ok, %{declaration_request: declaration_request}} <-
        DeclarationRequestAPI.approve(id, params["verification_code"], user_id) do
      render(conn, "status.json", declaration_request: declaration_request)
    end
  end
end
