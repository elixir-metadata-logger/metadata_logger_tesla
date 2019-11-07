defmodule TeslaMetadataLoggerTest do
  use ExUnit.Case
  doctest TeslaMetadataLogger

  import ExUnit.CaptureLog

  defmodule MetadataFormatter do
    def format(_level, _message, _timestamp, metadata) do
      inspect(metadata) <> "\n"
    end
  end

  setup do
    on_exit(fn ->
      :ok =
        Logger.configure_backend(
          :console,
          format: nil,
          device: :user,
          level: nil,
          metadata: :all,
          colors: [enabled: false]
        )
    end)

    Logger.configure_backend(:console, format: {MetadataFormatter, :format}, metadata: :all)

    bypass = Bypass.open()
    {:ok, bypass: bypass}
  end

  test "metadata in logs", %{bypass: bypass} do
    Bypass.expect(bypass, "GET", "/ping", fn conn ->
      Plug.Conn.resp(conn, 200, ~s(pong))
    end)

    client =
      Tesla.client([
        {Tesla.Middleware.BaseUrl, "http://127.0.0.1:#{bypass.port}"},
        TeslaMetadataLogger
      ])

    captured =
      capture_log(fn ->
        {:ok, %{body: "pong"}} = Tesla.get(client, "/ping", query: [foo: :bar])
      end)

    assert captured =~ ~s(http_client_req_id: ")
    assert captured =~ ~s(http_client_method: "GET")
    assert captured =~ ~s(http_client_url: "http://127.0.0.1:#{bypass.port}/ping")
    assert captured =~ ~s(http_client_req_query: "foo=bar")
    assert captured =~ ~s(http_client_req_body: "")
    assert captured =~ ~s(http_client_duration_ms: )
    assert captured =~ ~s(http_client_status: 200)
    assert captured =~ ~s(http_client_resp_headers: %{)
    assert captured =~ ~s(http_client_resp_body: "pong")
    assert captured =~ ~s(http_client_resp_body_bytes: )

    assert Logger.metadata() == []
  end
end
