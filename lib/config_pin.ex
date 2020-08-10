defmodule ConfigPin do
  @moduledoc """
  A wrapper for the BeagleBone [`config-pin`](https://github.com/beagleboard/bb.org-overlays/tree/master/tools/beaglebone-universal-io#usage)
  utility.
  """

  @typedoc """
  Potential errors that can be returned by `config-pin`. Since new versions
  of `config-pin` may be released, any unknown errors are passed through with
  the message and exit code returned by `config-pin`.

  *If you encounter an `:unknown` error, please file an issue or PR with this
  repository, as we would like to support all `config-pin` errors idiomatically.*
  """
  @type config_pin_error ::
    {:error, :invalid_mode}
    | {:error, :invalid_pin}
    | {:error, :pinmux_file_not_found}
    | {:error, :pin_not_exported}
    | {:error, {:pin_not_modifiable, function :: String.t}}
    | {:error, {:file_unwritable, :gpio_direction | :pinmux, file_path :: String.t}}
    | {:error, {:file_unreadable, :pinmux, file_path :: String.t}}
    | {:error, {:unknown, message :: String.t, exit_code :: non_neg_integer}}

  @valid_modes [
    :default,
    :gpio,
    :gpio_pu,
    :gpio_pd,
    :gpio_input,
    :pruout,
    :pruin,
    :spi_cs,
    :i2c,
    :pwm,
    :pru_uart,
    :spi_sclk,
    :uart,
    :spi,
    :can,
    :qep,
    :pru_ecap,
    :timer,
    :pwm2,
  ]

  @doc """
  Send a command to the `config-pin` utility.

  ***This is a low-level function and is designed to be used by higher level
  functions with a more idiomatic interface, or for troubleshooting.***

  `args` - See the [`config-pin` docs](https://github.com/beagleboard/bb.org-overlays/tree/master/tools/beaglebone-universal-io#usage)
    or print the `config-pin` help from the console for the list of arguments.

  Returns a tuple containing the response from stdout and the command's
  exit status. stderr is redirected to stdout, so failure messages will show up
  in the response.
  """
  # coveralls-ignore-start
  # This function is intended to be so simple that it can be excluded from
  # code coverage. It is designed to be the function that can be mocked when
  # testing this library, since it is the boundary to the `config-pin` utility.
  @spec cmd(args :: [String.t]) ::
    {response :: String.t, exit_status :: non_neg_integer}
  def cmd(args) do
    System.cmd("config-pin", args, stderr_to_stdout: true)
  end
  # coveralls-ignore-stop

  @doc """
  Print the information about a pin to the console.

  `header` - The number of the header the pin belongs to.
    For example, the BeagleBone Black header `P9` would be `9`.

  `pin` - The physical number of the pin to configure.
    For example, BBB `GPIO_30` is on pin `11`.
  """
  @spec info(header :: non_neg_integer, pin :: non_neg_integer) :: :ok
  def info(header, pin) do
    pin_string = make_pin_string(header, pin)

    {response, _} = ConfigPin.cmd(["-i", pin_string])
    IO.puts response
  end

  @doc """
  Returns a list of valid modes for a pin.

  `header` - The number of the header the pin belongs to.
    For example, the BeagleBone Black header `P9` would be `9`.

  `pin` - The physical number of the pin to configure.
    For example, BBB `GPIO_30` is on pin `11`.
  """
  @spec list_modes(header :: non_neg_integer, pin :: non_neg_integer) ::
    :ok | config_pin_error
  def list_modes(header, pin) do
    pin_string = make_pin_string(header, pin)

    case ConfigPin.cmd(["-l", pin_string]) do
      {response, 0} ->
        list =
          response
          |> String.trim
          |> String.split

        {:ok, list}

      error ->
        parse_error(error)
    end
  end

  @doc """
  Query the pin configuration details.

  `header` - The number of the header the pin belongs to.
    For example, the BeagleBone Black header `P9` would be `9`.

  `pin` - The physical number of the pin to configure.
    For example, BBB `GPIO_30` is on pin `11`.

  Returns a map of the configuration on success.
  """
  @spec query(header :: non_neg_integer, pin :: non_neg_integer) ::
    {:ok, map} | config_pin_error
  def query(header, pin) do
    pin_string = make_pin_string(header, pin)

    case ConfigPin.cmd(["-q", pin_string]) do
      {response, 0} ->
        [header_and_pin | params] = split_query_params_from_string(response)

        {header, pin} = parse_header_and_pin(header_and_pin)

        result =
          %{
            header: header,
            pin: pin,
          }
          |> Map.merge(parse_query_params_list(params))

        {:ok, result}

      error ->
        parse_error(error)
    end
  end

  @doc """
  Set the mode for a pin.

  `header` - The number of the header the pin belongs to.
    For example, the BeagleBone Black header `P9` would be `9`.

  `pin` - The physical number of the pin to configure.
    For example, BBB `GPIO_30` is on pin `11`.

  `mode` - The mode to set the pin to. Valid modes can be discovered with
    `valid_modes/2`, or by viewing the [`config-pin` source](https://github.com/beagleboard/bb.org-overlays/blob/master/tools/beaglebone-universal-io/config-pin#L65).

  Returns `:ok` on success.
  """
  @spec set(header :: non_neg_integer, pin :: non_neg_integer, mode :: term) ::
    :ok | config_pin_error
  def set(header, pin, mode) do
    pin_string = make_pin_string(header, pin)
    mode_string = to_string(mode)

    case ConfigPin.cmd([pin_string, mode_string]) do
      {_, 0} ->
        :ok

      error ->
        parse_error(error)
    end
  end

  defp make_pin_string(header, pin) do
    "P#{header}_#{pin}"
  end

  defp parse_error({<<"Invalid mode:", _::binary>>, 1}) do
    {:error, :invalid_mode}
  end

  defp parse_error({<<"Invalid pin:", _::binary>>, 1}) do
    {:error, :invalid_pin}
  end

  defp parse_error({<<"WARNING: GPIO pin not exported", _::binary>>, 1}) do
    {:error, :pin_not_exported}
  end

  defp parse_error({<<"Cannot write gpio direction file:", path::binary>>, 1}) do
    {:error, {:file_unwritable, :gpio_direction, String.trim(path)}}
  end

  defp parse_error({<<"Cannot read pinmux file:", path::binary>>, 1}) do
    {:error, {:file_unreadable, :pinmux, String.trim(path)}}
  end

  defp parse_error({<<"Cannot write pinmux file:", path::binary>>, 1}) do
    {:error, {:file_unwritable, :pinmux, String.trim(path)}}
  end

  defp parse_error({<<"Pin is not modifiable:", description::binary>>, 1}) do
    function =
      description
      |> String.trim
      |> String.split
      |> List.last

    {:error, {:pin_not_modifiable, function}}
  end

  defp parse_error({message, exit_code}) do
    cond do
      message =~ "pinmux file not found" ->
        {:error, :pinmux_file_not_found}

      true ->
        {:error, {:unknown, String.trim(message), exit_code}}
    end
  end

  defp parse_header_and_pin(header_and_pin_string) do
    # Example: "P9_11" => {9, 11}

    header_and_pin_string
    |> String.trim_leading("P")
    |> String.split("_")
    |> Enum.map(&String.to_integer/1)
    |> List.to_tuple
  end

  defp split_query_params_from_string(params_string) do
    params_string
    |> String.trim_trailing
    |> String.replace(~r/\s+([A-Z])/, "\n\\1")
    |> String.split("\n")
  end

  defp parse_query_params_list(params) do
    params
    |> Enum.map(fn param ->
      param
      |> String.downcase
      |> String.split(": ")
      |> List.to_tuple
    end)
    |> Enum.map(&cast/1)
    |> Enum.reject(& &1 == nil)
    |> Enum.into(%{})
  end

  defp cast({"direction", direction}) do
    case direction do
      "in" -> {:direction, :in}
      "out" -> {:direction, :out}
      _ -> nil
    end
  end

  defp cast({"mode", mode}) do
    valid_modes = Enum.map(@valid_modes, &to_string/1)

    if mode in valid_modes do
      {:mode, String.to_atom(mode)}
    else
      nil
    end
  end

  defp cast({"value", value}) do
    {:value, String.to_integer(value)}
  end

  defp cast(_) do
    nil
  end
end
