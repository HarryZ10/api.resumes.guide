defmodule Backendwebserver.Router do
  require Logger
  use Plug.Router

  plug :match
  plug :dispatch

  get "/" do
    # GET request to locahost:8000
    send_resp(conn, 200, Jason.encode!(%{
      message: "Resume Syntax Generator API",
      status: 200
    }))
  end

  get "/generate" do
    file_path = Path.expand("./static/resume.g")
    rtg = RandomTextGenerator.new(file_path)
    generated_text = RandomTextGenerator.run(rtg)

    send_resp(conn, 200, Jason.encode!(%{
      "text" => generated_text,
      "status" => "OK"
    }))
  end

  match _ do # default for errors
    send_resp(conn, 400, Jason.encode!(%{
      message: "No resource found!",
      status: 400
    }))
  end

end
