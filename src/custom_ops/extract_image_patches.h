/***  File Header  ************************************************************/
/**
* @file extract_image_patches.h
*
* Tensorflow lite cutom operaton: ExtractImagePatches
* @author	Shozo Fukuda
* @date	    create Fri Apr 21 20:46:59 2023
* @date	    modify Fri Apr 21 20:46:59 2023
* System	Linux,Windows <br>
*
**/
/**************************************************************************{{{*/

#ifndef EXTRACT_IMAGE_PATCHES_H
#define EXTRACT_IMATE_PATCHES_H

#include "tensorflow/lite/kernels/internal/types.h"
#include "tensorflow/lite/kernels/kernel_util.h"

namespace custom_operations {

	TfLiteRegistration* RegisterExtractImagePatches();

}  // namespace custom_operations
#endif

/*** extract_image_patches.h **********************************************}}}*/
