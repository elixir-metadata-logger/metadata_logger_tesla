defmodule TeslaMetadataLogger do
  @behaviour Tesla.Middleware

  require Logger

  def call(env, next, _opts) do
    common_metadata = [
      http_client_req_id: generate_request_id()
    ]

    req_metadata = [
      http_client_method: env.method |> to_string() |> String.upcase(),
      http_client_url: env.url
    ]

    req_debug_metadata = [
      http_client_req_headers: normalize_headers(env.headers),
      http_client_req_body: normalize_body(env.body)
    ]

    Logger.debug("started", common_metadata ++ req_metadata ++ req_debug_metadata)

    start = System.monotonic_time()
    result = Tesla.run(env, next)
    stop = System.monotonic_time()

    case result do
      {:ok, env} ->
        resp_metadata = [
          http_client_duration_ms: System.convert_time_unit(stop - start, :native, :millisecond),
          http_client_status: env.status
        ]

        resp_debug_metadata = [
          http_client_resp_headers: normalize_headers(env.headers),
          http_client_resp_body: normalize_body(env.body)
        ]

        resp_info_metadata = [
          http_client_resp_body_bytes: body_size(env.body)
        ]

        Logger.debug("completed", common_metadata ++ resp_metadata ++ resp_debug_metadata)

        Logger.info(
          "completd",
          common_metadata ++ req_metadata ++ resp_metadata ++ resp_info_metadata
        )

      {:error, error} ->
        Logger.error("failed", error: inspect(error))
    end

    result
  end

  defp normalize_headers(%{} = headers),
    do: headers |> Enum.map(fn {k, v} -> {k, [v]} end) |> Enum.into(%{})

  defp normalize_headers(headers) when is_list(headers),
    do: headers |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)

  defp normalize_headers(headers), do: inspect(headers)

  defp normalize_body(body), do: to_string(body)

  defp body_size(nil), do: 0
  defp body_size(body), do: IO.iodata_length(body)

  # from Plug.RequestId
  defp generate_request_id do
    binary = <<
      System.system_time(:nanoseconds)::64,
      :erlang.phash2({node(), self()}, 16_777_216)::24,
      :erlang.unique_integer()::32
    >>

    Base.hex_encode32(binary, case: :lower)
  end
end
