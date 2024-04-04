defmodule Whisper do
  alias TflInterp, as: NNInterp
  use NNInterp,
    model: "./model/whisper-tiny.en.tflite",
    url: "https://github.com/shoz-f/tfl_interp/raw/main/demo_whisper/model/whisper-tiny.en.zip",
    inputs: [f32: {1,80,3000}],
    outputs: [s32: {1,224}],
    memo: &load_vocab/0

  # Whisper vocablary holder.
  defstruct decoder: nil, added_decoder: nil, special_ids: nil

  @doc """
  """
  def apply(feature) do
    # preprocess

    # prediction
    session()
      |> NNInterp.set_input_tensor(0, feature)
      |> NNInterp.invoke()
      |> NNInterp.get_output_tensor(0)
      |> then(fn output -> (for <<id::32-little <- output>>, do: id) end)

    # postprocess
  end

  # basic decoder to convert from ids to string.
  @u0000  Enum.concat([?!..?~, ?¡..?¬, ?®..?ÿ])
  @u2b    Map.new(Enum.map(@u0000, &{<<&1::utf8>>, &1}) ++ Enum.with_index(Enum.reject(0..255, &(&1 in @u0000)), &{<<&2+0x100::utf8>>, &1}))

  def decode(ids, %{decoder: decoder, added_decoder: added_decoder, special_ids: special_ids}) do
    # convert ids to tokens.
    (for id <- ids, id not in special_ids, do: (added_decoder[id] || decoder[id] || ""))
    # convert tokens to string. (unicode2byte)
    |> Enum.flat_map(&String.split(&1, "", trim: true))
    |> Enum.map(&(@u2b[&1]))
    |> List.to_string()
  end

  # load vocablary tables.
  defp load_vocab(), do: %Whisper{
    decoder:       Map.new(Jason.decode!(File.read!("model/vocab.json")), fn {k,v} -> {v,k} end),
    added_decoder: Map.new(Jason.decode!(File.read!("model/added_vocab.json")), fn {k,v} -> {v,k} end),
    special_ids:   Jason.decode!(File.read!("model/special_ids.json"))
  }

  @doc """
  Get tables of Whisper vocablay for decoding ids to tokens.
  """
  def vocab() do
    case NNInterp.get_memo(__MODULE__) do
      %Whisper{}=vocab -> vocab
      _ -> load_vocab()
    end
  end
end
