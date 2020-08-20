# nerves_config_pin

[![Hex.pm](https://img.shields.io/hexpm/v/nerves_config_pin)](https://hex.pm/packages/nerves_config_pin)
[![API Documentation](http://img.shields.io/badge/docs-api-blue.svg)](https://hexdocs.pm/nerves_config_pin)
[![MIT License](https://img.shields.io/badge/license-MIT-yellowgreen.svg)](https://github.com/amclain/nerves_config_pin/blob/master/LICENSE)

A BeagleBone [`config-pin`](https://github.com/beagleboard/bb.org-overlays/tree/master/tools/beaglebone-universal-io#usage)
wrapper for use in Elixir [Nerves](https://hexdocs.pm/nerves) projects.

## Usage

### Overlays

The BeagleBone cape manager is not available in a Nerves system. Instead, the
overlays are specified by setting U-Boot environment variables. Configuration of
capes/overlays is out of the scope of this library.
Utilize [`Nerves.Runtime.KV`](https://hexdocs.pm/nerves_runtime/Nerves.Runtime.KV.html)
or [`provisioning.conf`](https://github.com/nerves-project/nerves_system_bbb/blob/main/fwup_include/provisioning.conf)
to configure overlays.

### Example Commands

The following functions accept the number of the header followed by the number
of the pin on that header. See the [system reference manual](https://github.com/beagleboard/beaglebone-black/wiki/System-Reference-Manual#70-connectors)
for the pin mux table.

**Set** header 9, pin 12 to gpio pull-up:

```ex
iex> ConfigPin.set(9, 12, :gpio_pu)
:ok
```

**Query** the pin configuration for header 9, pin 12:

```ex
iex> ConfigPin.query(9, 12)       
{:ok, %{direction: :in, header: 9, mode: :default, pin: 12, value: 1}}
```

**List** the valid pin mux modes for header 9, pin 12:

```ex
iex> ConfigPin.list_modes(9, 12)
{:ok, [:default, :gpio, :gpio_pu, :gpio_pd, :gpio_input]}
```


Print **info** for header 9, pin 12:

```ex
iex> ConfigPin.info(9, 12) 
# Pin name: P9_12
# Function if no cape loaded: gpio
# Function if cape loaded: default gpio gpio_pu gpio_pd gpio_input
# Function information: gpio1_28 default gpio1_28 gpio1_28 gpio1_28 gpio1_28
# Kernel GPIO id: 60
# PRU GPIO id: 92

:ok
```

## Set Configuration From A File

A list of pin configurations can be defined in a text file. The format is
`<header>_<pin> <mode>\n`. Comments and white-space are allowed. Each
configuration must end with a line terminator.

***The file is passed directly to `config-pin` and is not processed
by this library.***

Example file:

```text
# <header>_<pin> <mode>
P9_11 gpio_pu
P9_12 gpio_pd
```

Setting the configuration:

```ex
iex> ConfigPin.set_from_file("/root/pinmux")
:ok
```
