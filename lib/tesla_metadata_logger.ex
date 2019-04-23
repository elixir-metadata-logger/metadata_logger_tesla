defmodule TeslaMetadataLogger do
  @moduledoc """
  Tesla Middleware to log request and response into in metadata.

  It puts a map into metadata, so logger formatter *MUST* handle it.
  Otherwise it will raise `Protocol.UndefinedError`
  """
  @behaviour Tesla.Middleware

  require Logger

  def call(env, next, _opts) do
    Logger.metadata(http_client_req_id: generate_request_id())

    req_metadata = [
      http_client_method: env.method |> to_string() |> String.upcase(),
      http_client_url: env.url
    ]

    Logger.debug(fn ->
      {"started",
       req_metadata ++
         [
           http_client_req_headers: header_list_to_map(env.headers),
           http_client_req_query: encode_query(env.query),
           http_client_req_body: to_string(env.body)
         ]}
    end)

    start = System.monotonic_time()
    result = Tesla.run(env, next)
    stop = System.monotonic_time()

    case result do
      {:ok, env} ->
        resp_metadata = [
          http_client_duration_ms: System.convert_time_unit(stop - start, :native, :millisecond),
          http_client_status: env.status
        ]

        Logger.debug(fn ->
          {"completed",
           resp_metadata ++
             [
               http_client_resp_headers: header_list_to_map(env.headers),
               http_client_resp_body: to_string(env.body)
             ]}
        end)

        Logger.info(
          "completd",
          req_metadata ++
            resp_metadata ++
            [
              http_client_resp_body_bytes: body_size(env.body)
            ]
        )

      {:error, error} ->
        Logger.error("failed", error: inspect(error))
    end

    Logger.metadata(http_client_req_id: nil)

    result
  end

  defp header_list_to_map(headers),
    do: headers |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)

  defp body_size(nil), do: 0
  defp body_size(body), do: IO.iodata_length(body)

  # from Plug.RequestId
  defp generate_request_id do
    binary = <<
      System.system_time(:nanosecond)::64,
      :erlang.phash2({node(), self()}, 16_777_216)::24,
      :erlang.unique_integer()::32
    >>

    Base.hex_encode32(binary, case: :lower)
  end

  # from Tesla
  defp encode_query(query) do
    query
    |> Enum.flat_map(&Tesla.encode_pair/1)
    |> URI.encode_query()
  end
end
