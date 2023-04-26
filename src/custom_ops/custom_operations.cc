/***  File Header  ************************************************************/
/**
* custom_operations.cc
*
* Elixir/Erlang Port ext. of tensor flow lite
* @author	   Shozo Fukuda
* @date	create Sat Apr 15 17:12:44 2023
* System	   VC++ 2019/Windows 10<br>
*
**/
/**************************************************************************{{{*/

#include "tensorflow/lite/kernels/register.h"

#include "max_pool_argmax.h"
#include "max_unpooling.h"
#include "transpose_conv_bias.h"
#include "extract_image_patches.h"

/***  Module Header  ******************************************************}}}*/
/**
* install custom operations
* @par DESCRIPTION
*
*
* @retval
**/
/**************************************************************************{{{*/
void add_custom_operations(tflite::ops::builtin::BuiltinOpResolver& resolver)
{
    resolver.AddCustom("MaxPoolingWithArgmax2D", custom_operations::RegisterMaxPoolingWithArgmax2D());
    resolver.AddCustom("MaxUnpooling2D", custom_operations::RegisterMaxUnpooling2D());
    resolver.AddCustom("Convolution2DTransposeBias", custom_operations::RegisterConvolution2DTransposeBias());
    resolver.AddCustom("ExtractImagePatches", custom_operations::RegisterExtractImagePatches());
}

/*** custom_operations.cc *************************************************}}}*/
