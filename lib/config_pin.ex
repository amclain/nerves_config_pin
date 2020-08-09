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
end
