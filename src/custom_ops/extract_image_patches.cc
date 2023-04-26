/***  File Header  ************************************************************/
/**
* @file extract_image_patches.cc
*
* Tensorflow lite cutom operaton: ExtractImagePatches
* @author	Shozo Fukuda
* @date	    create Fri Apr 21 20:46:59 2023
* @date	    modify Fri Apr 21 20:46:59 2023
* System	Linux,Windows <br>
*
**/
/**************************************************************************{{{*/

#include "extract_image_patches.h"

#include "flatbuffers/flexbuffers.h"  // from @flatbuffers
#include "tensorflow/lite/kernels/internal/tensor.h"
#include "tensorflow/lite/kernels/padding.h"

namespace custom_operations {
namespace {

struct ExPatchParams {
    int filter_height;
    int filter_width;
    int stride_height;
    int stride_width;
    int rate_width;
    int rate_height;
    tflite::PaddingValues padding_values;
};

template <typename T>
inline void ExtractImagePatches(
const ExPatchParams& params,
const ::tflite::RuntimeShape& input_shape,
const ::tflite::RuntimeShape& output_shape,
const T* input_data,
T* output_data)
{
    TFLITE_DCHECK_EQ(input_shape.DimensionsCount(), 4);
    TFLITE_DCHECK_EQ(output_shape.DimensionsCount(), 4);

    const int32_t batches = MatchingDim(input_shape, 0, output_shape, 0);
    const int32_t input_height = input_shape.Dims(1);
    const int32_t input_width = input_shape.Dims(2);
    const int32_t input_depth = input_shape.Dims(3);
    const int32_t output_height = output_shape.Dims(1);
    const int32_t output_width = output_shape.Dims(2);
    const int32_t stride_height = params.stride_height;
    const int32_t stride_width = params.stride_width;

    for (int32_t batch = 0; batch < batches; batch++) {
    for (int32_t out_y = 0; out_y < output_height; out_y++) {
    for (int32_t out_x = 0; out_x < output_width; out_x++) {
        const int32_t in_x_origin = (out_x * stride_width) - params.padding_values.width;
        const int32_t in_y_origin = (out_y * stride_height) - params.padding_values.height;

        T* patch = output_data + Offset(output_shape, batch, out_y, out_x, 0);

        for (int32_t filter_y = 0; filter_y < params.filter_height; ++filter_y) {
        for (int32_t filter_x = 0; filter_x < params.filter_width; ++filter_x) {
            const int32_t in_x = in_x_origin + filter_x*params.rate_width;
            const int32_t in_y = in_y_origin + filter_y*params.rate_height;
            if ((0 <= in_x && in_x < input_width) && (0 <= in_y && in_y < input_height)) {
                for (int32_t channel = 0; channel < input_depth; ++channel) {
                    *patch++ = input_data[Offset(input_shape, batch, in_y, in_x, channel)];
                }
            }
            else {
                for (int32_t channel = 0; channel < input_depth; ++channel) {
                    *patch++ = 0;
                }
            }
        }}
    }}}
}


constexpr int kDataInputTensor = 0;
constexpr int kDataOutputTensor = 0;

constexpr const char kSizesStr[] = "ksizes";
constexpr const char kStridesStr[] = "strides";
constexpr const char kRatesStr[] = "rates";
constexpr const char kPaddingStr[] = "padding";
constexpr const char kPaddingSameStr[] = "SAME";
constexpr const char kPaddingValidStr[] = "VALID";

struct OpData {
    int k_height;
    int k_width;
    int stride_height;
    int stride_width;
    int rate_height;
    int rate_width;
    TfLitePadding padding;
    struct {
        TfLitePaddingValues padding;
    } computed;
};

/***  Module Header  ******************************************************}}}*/
/**
* <タイトル記入>
* @par description
   <<解説記入>>
**/
/**************************************************************************{{{*/
void* Init(TfLiteContext* context, const char* buffer, size_t length)
{
    const flexbuffers::Map& m =
        flexbuffers::GetRoot(reinterpret_cast<const uint8_t*>(buffer), length)
        .AsMap();

    OpData* op_data = new OpData;

    // The first and last element of sizes are always 1.
    const auto sizes = m[kSizesStr].AsTypedVector();
    TFLITE_CHECK_EQ(sizes.size(), 4);
    TFLITE_CHECK_EQ(sizes[0].AsInt32(), 1);
    TFLITE_CHECK_EQ(sizes[3].AsInt32(), 1);
    op_data->k_height = sizes[1].AsInt32();
    op_data->k_width = sizes[2].AsInt32();

    // The first and last element of strides are always 1.
    const auto strides = m[kStridesStr].AsTypedVector();
    TFLITE_CHECK_EQ(strides.size(), 4);
    TFLITE_CHECK_EQ(strides[0].AsInt32(), 1);
    TFLITE_CHECK_EQ(strides[3].AsInt32(), 1);
    op_data->stride_height = strides[1].AsInt32();
    op_data->stride_width = strides[2].AsInt32();

    // The first and last element of rates are always 1.
    const auto rates = m[kRatesStr].AsTypedVector();
    TFLITE_CHECK_EQ(rates.size(), 4);
    TFLITE_CHECK_EQ(rates[0].AsInt32(), 1);
    TFLITE_CHECK_EQ(rates[3].AsInt32(), 1);
    op_data->rate_height = rates[1].AsInt32();
    op_data->rate_width = rates[2].AsInt32();

    const std::string padding = m[kPaddingStr].AsString().str();
    if (padding == kPaddingValidStr) {
        op_data->padding = kTfLitePaddingValid;
    }
    else if (padding == kPaddingSameStr) {
        op_data->padding = kTfLitePaddingSame;
    }
    else {
        op_data->padding = kTfLitePaddingUnknown;
    }

    return op_data;
}

/***  Module Header  ******************************************************}}}*/
/**
* <タイトル記入>
* @par description
   <<解説記入>>
**/
/**************************************************************************{{{*/
void Free(TfLiteContext* context, void* buffer)
{
    delete reinterpret_cast<OpData*>(buffer);
}

/***  Module Header  ******************************************************}}}*/
/**
* <タイトル記入>
* @par description
   <<解説記入>>
**/
/**************************************************************************{{{*/
TfLiteStatus Prepare(TfLiteContext* context, TfLiteNode* node)
{
    OpData* op_data = reinterpret_cast<OpData*>(node->user_data);

    TF_LITE_ENSURE_EQ(context, ::tflite::NumInputs(node), 1);
    TF_LITE_ENSURE_EQ(context, ::tflite::NumOutputs(node), 1);
    TfLiteTensor* output =
        ::tflite::GetOutput(context, node, kDataOutputTensor);
    const TfLiteTensor* input =
        ::tflite::GetInput(context, node, kDataInputTensor);
    TF_LITE_ENSURE_EQ(context, ::tflite::NumDimensions(input), 4);
    TF_LITE_ENSURE_EQ(context, input->type, kTfLiteFloat32);
    TF_LITE_ENSURE_EQ(context, output->type, kTfLiteFloat32);

    int batches = input->dims->data[0];
    int height = input->dims->data[1];
    int width = input->dims->data[2];
    int channels_out = input->dims->data[3];

    int out_height, out_width;
    op_data->computed.padding = ::tflite::ComputePaddingHeightWidth(
        op_data->stride_height, op_data->stride_width,
        op_data->rate_height, op_data->rate_width,
        height, width,
        op_data->k_height, op_data->k_width,
        op_data->padding, 
        &out_height, &out_width);

    TfLiteIntArray* output_size = TfLiteIntArrayCreate(4);
    output_size->data[0] = batches;
    output_size->data[1] = out_height;
    output_size->data[2] = out_width;
    output_size->data[3] = channels_out * op_data->k_height * op_data->k_width;

    return context->ResizeTensor(context, output, output_size);
}

/***  Module Header  ******************************************************}}}*/
/**
* <タイトル記入>
* @par description
*   <<解説記入>>
**/
/**************************************************************************{{{*/
TfLiteStatus Eval(TfLiteContext* context, TfLiteNode* node)
{
    OpData* op_data = reinterpret_cast<OpData*>(node->user_data);

    ExPatchParams op_params;
    op_params.filter_height = op_data->k_height;
    op_params.filter_width = op_data->k_width;
    op_params.stride_height = op_data->stride_height;
    op_params.stride_width = op_data->stride_width;
    op_params.rate_height = op_data->rate_height;
    op_params.rate_width = op_data->rate_width;
    op_params.padding_values.height = op_data->computed.padding.height;
    op_params.padding_values.width = op_data->computed.padding.width;

    TfLiteTensor* output =
        ::tflite::GetOutput(context, node, kDataOutputTensor);
    const TfLiteTensor* input =
        ::tflite::GetInput(context, node, kDataInputTensor);

    switch (input->type) {
    case kTfLiteFloat32:
        ExtractImagePatches<float>(op_params, ::tflite::GetTensorShape(input), ::tflite::GetTensorShape(output),
            ::tflite::GetTensorData<float>(input), ::tflite::GetTensorData<float>(output));
        break;
    default:
        TF_LITE_KERNEL_LOG(context, "Type %s not currently supported.", TfLiteTypeGetName(input->type));
        return kTfLiteError;
    }
    return kTfLiteOk;
}

}  // namespace

TfLiteRegistration* RegisterExtractImagePatches() {
    static TfLiteRegistration reg = { Init, Free, Prepare, Eval };
    return &reg;
}

}  // namespace custom_operations

/*** extract_image_patches.cc *********************************************}}}*/
