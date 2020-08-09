defmodule ConfigPin do
  @moduledoc """
  A wrapper for the BeagleBone [`config-pin`](https://github.com/beagleboard/bb.org-overlays/tree/master/tools/beaglebone-universal-io#usage)
  utility.
  """

  @typedoc """
  The error message and exit code are passed through from `config-pin`.
  """
  @type config_pin_error ::
    {:error, {message :: String.t, exit_code :: non_neg_integer}}

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
  @spec cmd(args :: [String.t]) ::
    {response :: String.t, exit_status :: non_neg_integer}
  def cmd(args) do
    System.cmd("config-pin", args, stderr_to_stdout: true)
  end

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

    {result, _} = ConfigPin.cmd(["-i", pin_string])
    IO.puts result
  end

  @doc """
  Set the mode for a pin.

  `header` - The number of the header the pin belongs to.
    For example, the BeagleBone Black header `P9` would be `9`.

  `pin` - The physical number of the pin to configure.
    For example, BBB `GPIO_30` is on pin `11`.

  `mode` - The mode to set the pin to. Valid modes can be discovered with
    `valid_modes/2`, or by viewing the [`config-pin` source](https://github.com/beagleboard/bb.org-overlays/blob/master/tools/beaglebone-universal-io/config-pin#L65).

  Returns `:ok` on success, or passes through the error message and exit code
  from `config-pin` on failure.
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
        format_config_pin_error(error)
    end
  end

  @doc """
  Returns a list of valid modes for a pin.

  `header` - The number of the header the pin belongs to.
    For example, the BeagleBone Black header `P9` would be `9`.

  `pin` - The physical number of the pin to configure.
    For example, BBB `GPIO_30` is on pin `11`.

  This function passes through the error message and exit code from `config-pin`
  on failure.
  """
  @spec valid_modes(header :: non_neg_integer, pin :: non_neg_integer) ::
    :ok | config_pin_error
  def valid_modes(header, pin) do
    pin_string = make_pin_string(header, pin)

    case ConfigPin.cmd(["-l", pin_string]) do
      {result, 0} ->
        list =
          result
          |> String.trim
          |> String.split

        {:ok, list}

      error ->
        format_config_pin_error(error)
    end
  end

  defp make_pin_string(header, pin) do
    "P#{header}_#{pin}"
  end

  defp format_config_pin_error({message, exit_code}) do
    {:error, {String.trim(message), exit_code}}
  end
end
