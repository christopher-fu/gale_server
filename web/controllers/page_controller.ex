defmodule GaleServer.PageController do
  use GaleServer.Web, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
