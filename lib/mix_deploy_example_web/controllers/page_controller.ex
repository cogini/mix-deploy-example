defmodule MixDeployExampleWeb.PageController do
  use MixDeployExampleWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
