defmodule Whisper do
  alias TflInterp, as: NNInterp
  use NNInterp,
    model: "./model/whisper-tiny.en.tflite",
    #url: "https://github.com/shoz-f/tinyML_livebook/releases/download/model/yolox_s.tflite",
    inputs: [f32: {1,80,3000}],
    outputs: [s32: {1,224}],
    priv: load_vocab()

  defstruct decoder: nil, added_decoder: nil, special_ids: nil

  def apply(wav) do
    # preprocess
    input0 = wav.data

    # prediction
    output = session()
      |> NNInterp.set_input_tensor(0, input0)
      |> NNInterp.invoke()
      |> NNInterp.get_output_tensor(0)
      |> then(fn output -> (for <<id::32-little <- output>>, do: id) end)

    # postprocess
    decode(output, vocab())
  end

  @u0000  Enum.concat([?!..?~, ?¡..?¬, ?®..?ÿ])
  @u2b    Map.new(Enum.map(@u0000, &{<<&1::utf8>>, &1}) ++ Enum.with_index(Enum.reject(0..255, &(&1 in @u0000)), &{<<&2+0x100::utf8>>, &1}))

  defp decode(ids, %{decoder: decoder, added_decoder: added_decoder, special_ids: special_ids}) do
    # convert ids to tokens.
    (for id <- ids, id not in special_ids, do: (added_decoder[id] || decoder[id] || ""))
    # convert tokens to string. (unicode2byte)
    |> Enum.flat_map(&String.split(&1, "", trim: true))
    |> Enum.map(&(@u2b[&1]))
    |> List.to_string()
  end


  defp load_vocab(), do: %Whisper{
    decoder:       Map.new(Jason.decode!(File.read!("model/vocab.json")), fn {k,v} -> {v,k} end),
    added_decoder: Map.new(Jason.decode!(File.read!("model/added_vocab.json")), fn {k,v} -> {v,k} end),
    special_ids:   Jason.decode!(File.read!("model/special_ids.json"))
  }

  def vocab() do
    case NNInterp.get_priv(__MODULE__) do
      %Whisper{}=vocab -> vocab
      _ -> load_vocab()
    end
  end
end
