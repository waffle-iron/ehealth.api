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
    declaration_request = DeclarationRequestAPI.get_declaration_request_by_id!(id, params)
    render(conn, "declaration_request.json", declaration_request: declaration_request)
  end

  def create(conn, %{"declaration_request" => declaration_request}) do
    user_id = get_consumer_id(conn.req_headers)
    client_id = get_client_id(conn.req_headers)

    creation_result = DeclarationRequestAPI.create(declaration_request, user_id, client_id)

    with {:ok, %{urgent_data: urgent_data, finalize: result}} <- creation_result do
      conn
      |> assign(:urgent, urgent_data)
      |> render("declaration_request.json", declaration_request: result)
    end
  end

  def approve(conn, %{"id" => id} = params) do
    user_id = get_consumer_id(conn.req_headers)

    with {:ok, %{declaration_request: declaration_request}} <-
        DeclarationRequestAPI.approve(id, params["verification_code"], user_id) do
      render(conn, "declaration_request.json", declaration_request: declaration_request)
    end
  end

  def sign(conn, params) do
    with {:ok, declaration} <- DeclarationRequestAPI.sign(params, conn.req_headers) do
      render(conn, "declaration.json", declaration: declaration)
    end
  end

  def resend_otp(conn, params) do
    with {:ok, otp} <- DeclarationRequestAPI.resend_otp(params, conn.req_headers) do
      render(conn, "otp.json", otp: otp)
    end
  end

  def reject(conn, %{"id" => id}) do
    user_id = get_consumer_id(conn.req_headers)

    with {:ok, declaration_request} <- DeclarationRequestAPI.reject(id, user_id) do
      render(conn, "declaration_request.json", declaration_request: declaration_request)
    else
      {:error, _changeset} ->
        conn
        |> put_status(:conflict)
        |> render(EView.Views.Error, :"409")
      _ ->
        nil
    end
  end

  def images(conn, %{"id" => id}) do
    with {:ok, images} <- DeclarationRequestAPI.images(id) do
      render(conn, "images.json", images: images)
    end
  end
end
