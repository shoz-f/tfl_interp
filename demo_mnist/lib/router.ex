defmodule Router do
  use Plug.Router

  plug Plug.Static.IndexHtml, at: "/"
  plug Plug.Static, at: "/", from: :tfl_mnist

  plug :match
  plug Plug.Parsers, parsers: [:urlencoded, :json],
                     pass: ["text/*"],
                     json_decoder: Jason
  plug :dispatch

  post "/mnist" do
    "data:image/jpeg;base64," <> data = conn.params["img"]

    ans = data
      |> Base.decode64!()
      |> TflMnist.apply()

    send_resp(conn, 200, Jason.encode!(%{"ans" => ans}))
  end

  match _ do
    IO.inspect(conn)
    send_resp(conn, 404, "Oops!")
  end
end
