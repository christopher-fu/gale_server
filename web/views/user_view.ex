defmodule GaleServer.UserView do
  use GaleServer.Web, :view

  def render("ok.json", %{payload: payload}) do
    %{error: false, payload: payload}
  end

  def render("ok.json", _params) do
    %{error: false}
  end

  def render("error.json", %{payload: payload}) do
    %{error: true, payload: payload}
  end

  def render("error.json", _params) do
    %{error: true}
  end
end
