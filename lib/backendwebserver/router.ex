defmodule Backendwebserver.Router do
  require Logger
  use Plug.Router

  plug Corsica, origins: "*"
  plug :match
  plug :dispatch

  options "/generate",
    do: Corsica.send_preflight_resp(conn, origins: "*")

  get "/generate" do
    github_raw_url = "https://raw.githubusercontent.com/HarryZ10/api.resumes.guide/main/static/resume.g"

    case HTTPoison.get(github_raw_url) do
      {:ok, %HTTPoison.Response{status_code: 200, body: file_content}} ->
        rtg = RandomTextGenerator.new(file_content)
        generated_text = RandomTextGenerator.run(rtg)

        send_resp(conn, 200, Jason.encode!(%{
          "message" => generated_text,
          "status" => "OK"
        }))

      {:ok, %HTTPoison.Response{status_code: status_code}} ->
        send_resp(conn, status_code, Jason.encode!(%{
          "message" => "Failed to fetch file from GitHub",
          "status" => "Error"
        }))

      {:error, %HTTPoison.Error{reason: reason}} ->
        send_resp(conn, 500, Jason.encode!(%{
          "message" => "Error fetching file from GitHub: #{inspect(reason)}",
          "status" => "Error"
        }))
    end
  end

  match _ do # default for errors
    send_resp(conn, 400, Jason.encode!(%{
      message: "No resource found!",
      status: 400
    }))
  end

end
