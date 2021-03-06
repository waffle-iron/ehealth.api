defmodule EHealth.Web.PersonView do
  @moduledoc false

  use EHealth.Web, :view

  def render("person_short.json", %{"person" => person}) do
    %{
      "id" => Map.get(person, "id"),
      "first_name" => Map.get(person, "first_name"),
      "last_name" => Map.get(person, "last_name"),
      "second_name" => Map.get(person, "second_name"),
    }
  end
  def render("person_short.json", _), do: %{}
end
