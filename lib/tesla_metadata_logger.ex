defmodule TeslaMetadataLogger do
  @behaviour Tesla.Middleware

  require Logger

  def call(env, next, _opts) do
    req_metadata = [
      http_client_method: env.method |> to_string() |> String.upcase(),
      http_client_url: env.url
    ]

    req_debug_metadata = [
      http_client_req_headers: normalize_headers(env.headers),
      http_client_req_body: normalize_body(env.body)
    ]

    Logger.debug("started", req_metadata ++ req_debug_metadata)

    start = System.monotonic_time()
    env = Tesla.run(env, next)
    stop = System.monotonic_time()

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

    Logger.debug("completed", resp_metadata ++ resp_debug_metadata)

    Logger.info("completd", req_metadata ++ resp_metadata ++ resp_info_metadata)

    env
  rescue
    ex in Tesla.Error ->
      stacktrace = System.stacktrace()
      log_exception(ex)
      reraise ex, stacktrace
  end

  defp normalize_headers(%{} = headers),
    do: headers |> Enum.map(fn {k, v} -> {k, [v]} end) |> Enum.into(%{})

  defp normalize_headers(headers) when is_list(headers),
    do: headers |> Enum.group_by(fn {k, _v} -> k end, fn {_k, v} -> v end)

  defp normalize_headers(headers), do: inspect(headers)

  defp normalize_body(body), do: to_string(body)

  defp body_size(nil), do: 0
  defp body_size(body), do: IO.iodata_length(body)

  defp log_exception(%Tesla.Error{message: message, reason: reason}) do
    Logger.error(message, reason: inspect(reason))
  end
end
