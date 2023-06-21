defmodule DemoStyleGAN2ADA do
  def run(n \\ 1) do
    Enum.each(1..n, fn i ->
      StyleGAN2ADA.apply() |> CImg.save("result_#{i}.jpg")
    end)
  end
end
