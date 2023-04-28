defmodule DemoYoloX do
  @palette CImg.Util.rand_palette("./model/coco.label")

  def run(path) do
    img = CImg.load(path)

    with {:ok, res} <- YoloX.apply(img) do
      Enum.reduce(res, CImg.builder(img), &draw_object(&1, &2))
      |> CImg.save("result.jpg")
    end
  end

  defp draw_object({name, boxes}, canvas) do
    color = @palette[name]
    Enum.reduce(boxes, canvas, fn [_score, x1, y1, x2, y2, _index], canvas ->
      [x1, y1, x2, y2] = PostDNN.clamp([x1,y1,x2,y2], {0.0, 1.0})

      IO.inspect(name)
      CImg.fill_rect(canvas, x1, y1, x2, y2, color, 0.35)
    end)
  end
end
