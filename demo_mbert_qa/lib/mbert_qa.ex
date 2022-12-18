defmodule MBertQA do
  @moduledoc """
  Documentation for `MBertQA`.
  """
  use TflInterp,
    model: "./model/lite-model_mobilebert_1_metadata_1.tflite",
    url: "https://github.com/shoz-f/tfl_interp/releases/download/0.0.1/lite-model_mobilebert_1_metadata_1.tflite"
  
  alias MBertQA.Feature
  
  @max_ans 32
  @predict_num 5

  def setup() do
    Feature.load_dic("./model/vocab.txt")
  end

  def apply_mbert_qa(query, context, predict_num \\ @predict_num) do
    # pre-processing
    {feature, context} = Feature.convert(query, context)

    mod = __MODULE__
      |> TflInterp.set_input_tensor(0, Nx.to_binary(feature[0]))
      |> TflInterp.set_input_tensor(1, Nx.to_binary(feature[1]))
      |> TflInterp.set_input_tensor(2, Nx.to_binary(feature[2]))
      |> TflInterp.invoke()

    [end_logits, beg_logits] = Enum.map(0..1, fn x ->
      TflInterp.get_output_tensor(mod, x)
      |> Nx.from_binary({:f, 32})
    end)

    # post-processing
    [beg_index, end_index] = Enum.map([beg_logits, end_logits], fn t ->
      Nx.argsort(t, direction: :desc)
      |> Nx.slice_along_axis(0, predict_num)
      |> Nx.to_flat_list()
      |> Enum.filter(&(feature[3][&1] >= 0))
    end)

    for b <- beg_index, e <- end_index, b <= e, e - b + 1 < @max_ans do
      {b, e, Nx.to_number(Nx.add(beg_logits[b], end_logits[e]))}
    end
    |> Enum.sort(&(elem(&1, 2) >= elem(&2, 2)))
    |> Enum.take(predict_num)
    |> Enum.map(fn {b, e, score} ->
         b = Nx.to_number(feature[3][b])
         e = Nx.to_number(feature[3][e])
         {
           Enum.slice(context, b..e) |> Enum.join(" "),
           score
         }
       end)
  end
end
