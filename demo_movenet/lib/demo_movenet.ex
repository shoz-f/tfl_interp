defmodule DemoMovenet do
  def run(path) when is_binary(path) do
    img = CImg.load(path)

    with {:ok, res} <- Movenet.apply(img) do
      Enum.reduce(res, CImg.builder(img), &draw_item(&1, &2))
      |> CImg.save("xxx.jpg")
    end
  end
  
  defp draw_item({x1, y1, x2, y2, color}, canvas) do
    CImg.draw_line(canvas, x1, y1, x2, y2, color)
  end
end
