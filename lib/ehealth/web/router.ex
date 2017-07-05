defmodule Ehealth.Web.Router do
  @moduledoc """
  Attention! Ehealth namespace is not a typo! This name because of Plug module name transformation

  The router provides a set of macros for generating routes
  that dispatch to specific controllers and actions.
  Those macros are named after HTTP verbs.

  More info at: https://hexdocs.pm/phoenix/Phoenix.Router.html
  """
  use EHealth.Web, :router

  pipeline :api do
    plug :accepts, ["json"]
    plug :put_secure_browser_headers

    # Uncomment to enable versioning of your API
    # plug Multiverse, gates: [
    #   "2016-07-31": EHealth.Web.InitialGate
    # ]

    # You can allow JSONP requests by uncommenting this line:
    # plug :allow_jsonp
  end

  pipeline :api_client_id do
    plug :header_required, "x-consumer-metadata"
    plug :client_id_exists
  end

  scope "/api", EHealth.Web do
    pipe_through :api

    # Legal Entities
    put "/legal_entities", LegalEntityController, :create_or_update

    get "/dictionaries", DictionaryController, :index
    patch "/dictionaries/:name", DictionaryController, :update

    get "/employee_requests/:id", EmployeeRequestController, :show
    post "/employee_requests/:id/user", EmployeeRequestController, :create_user
  end

  scope "/api", EHealth.Web do
    pipe_through [:api, :api_client_id]

    # Legal Entities
    get "/legal_entities", LegalEntityController, :index
    get "/legal_entities/:id", LegalEntityController, :show
    patch "/legal_entities/:id/actions/nhs_verify", LegalEntityController, :nhs_verify

    # Employees
    get "/employees", EmployeesController, :index
    get "/employees/:id", EmployeesController, :show
    patch "/employees/:id/actions/deactivate", EmployeesController, :deactivate

    # Employee requests
    get "/employee_requests", EmployeeRequestController, :index
    post "/employee_requests", EmployeeRequestController, :create
    post "/employee_requests/:id/approve", EmployeeRequestController, :approve
    post "/employee_requests/:id/reject", EmployeeRequestController, :reject

    # Divisions
    resources "/divisions", DivisionController, except: [:new, :edit, :delete]
    patch "/divisions/:id/actions/activate", DivisionController, :activate
    patch "/divisions/:id/actions/deactivate", DivisionController, :deactivate

    # Declaration requests
    post "/declaration_requests", DeclarationRequestController, :create
    patch "/declaration_requests/:id/approve", DeclarationRequestController, :approve
  end
end
