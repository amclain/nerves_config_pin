defmodule ConfigPin.Spec do
  use ESpec

  before do
    allow ConfigPin |> to(accept :cmd, fn args ->
      expect args |> to(eq cmd_expected_args())
      cmd_return()
    end)
  end

  context "info" do
    let :cmd_expected_args, do: ["-i", "P9_12"]
    let :cmd_return, do: {"Pin name: P9_12\nFunction if no cape loaded: gpio\nFunction if cape loaded: default gpio gpio_pu gpio_pd gpio_input uart\nFunction information: gpio0_30 default gpio0_30 gpio0_30 gpio0_30 gpio0_30 uart4_rxd\nKernel GPIO id: 30\nPRU GPIO id: 62\n", 0}

    it "prints the information for a pin to the console" do
      allow IO |> to(accept :puts, fn message ->
        expect message |> to(eq """
        Pin name: P9_12
        Function if no cape loaded: gpio
        Function if cape loaded: default gpio gpio_pu gpio_pd gpio_input uart
        Function information: gpio0_30 default gpio0_30 gpio0_30 gpio0_30 gpio0_30 uart4_rxd
        Kernel GPIO id: 30
        PRU GPIO id: 62
        """)

        :ok
      end)

      expect ConfigPin.info(9, 12)
      |> to(eq :ok)

      expect ConfigPin |> to(accepted :cmd)
      expect IO |> to(accepted :puts)
    end
  end

  context "set" do
    let :cmd_expected_args, do: ["P9_12", "gpio_pu"]
    let :cmd_return, do: {"", 0}

    it "can set a valid pin to a valid mode" do
      expect ConfigPin.set(9, 12, :gpio_pu)
      |> to(eq :ok)

      expect ConfigPin |> to(accepted :cmd)
    end

    let :cmd_expected_args, do: ["P9_12", "bogus"]
    let :cmd_return, do: {"Invalid mode: bogus\n", 1}

    it "passes through the config-pin error on failure" do
      expect ConfigPin.set(9, 12, :bogus)
      |> to(eq {:error, {"Invalid mode: bogus", 1}})

      expect ConfigPin |> to(accepted :cmd)
    end
  end

  context "valid_modes" do
    let :cmd_expected_args, do: ["-l", "P9_12"]
    let :cmd_return, do: {"default gpio gpio_pu gpio_pd gpio_input uart\n", 0}

    it "returns a list of valid modes for a pin" do
      expect ConfigPin.valid_modes(9, 12)
      |> to(eq {
        :ok,
        [
          "default",
          "gpio",
          "gpio_pu",
          "gpio_pd",
          "gpio_input",
          "uart",
        ]
      })

      expect ConfigPin |> to(accepted :cmd)
    end

    let :cmd_expected_args, do: ["-l", "P9_1"]
    let :cmd_return, do: {"Pin is not modifiable: 9.1 GND\n", 1}

    it "passes through the config-pin error on failure" do
      expect ConfigPin.valid_modes(9, 1)
      |> to(eq {:error, {"Pin is not modifiable: 9.1 GND", 1}})

      expect ConfigPin |> to(accepted :cmd)
    end
  end
end
