defmodule DemoStyleGAN2ADA do
  def generate(n \\ 1) do
    Enum.each(1..n, fn i ->
      StyleGAN2ADA.Mapping.dlatants()
      |> StyleGAN2ADA.Synthesis.image()
      |> CImg.save("result_#{i}.jpg")
    end)
  end
  
  def morph() do
    a = StyleGAN2ADA.Mapping.dlatants()
    b = StyleGAN2ADA.Mapping.dlatants()
    delta = Nx.subtract(b, a) |> Nx.divide(6)
    
    Enum.each(0..5, fn i ->
      Nx.add(a, Nx.multiply(delta, i))
      |> StyleGAN2ADA.Synthesis.image()
      |> CImg.save("morph_#{i}.jpg")
    end)
  end
end
