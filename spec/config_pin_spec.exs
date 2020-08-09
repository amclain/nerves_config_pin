defmodule ConfigPin.Spec do
  use ESpec

  before do
    allow ConfigPin |> to(accept :cmd, fn args ->
      expect args |> to(eq cmd_expected_args())
      cmd_return()
    end)
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
end
