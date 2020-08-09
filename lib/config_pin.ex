defmodule ConfigPin do
  @moduledoc """
  A wrapper for the BeagleBone [`config-pin`](https://github.com/beagleboard/bb.org-overlays/tree/master/tools/beaglebone-universal-io#usage)
  utility.
  """

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
  Set the mode for a pin.

  `header` - The number of the header the pin belongs to.
    For example, the BeagleBone Black header `P9` would be `9`.

  `pin` - The physical number of the pin to configure.
    For example, BBB `GPIO_30` is on pin `11`.

  `mode` - The mode to set the pin to.

  Returns `:ok` on success, or passes through the error message and exit code
  from `config-pin` on failure.
  """
  @spec set(header :: non_neg_integer, pin :: non_neg_integer, mode :: term) ::
    :ok
    | {:error, {message :: String.t, exit_code :: non_neg_integer}}
  def set(header, pin, mode) do
    pin_string = "P#{header}_#{pin}"
    mode_string = to_string(mode)

    case ConfigPin.cmd([pin_string, mode_string]) do
      {_, 0} ->
        :ok

      {message, exit_code} ->
        {:error, {String.trim(message), exit_code}}
    end
  end
end
