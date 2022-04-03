/***  File Header  ************************************************************/
/**
* tfl_interp.cc
*
* Elixir/Erlang Port ext. of tensor flow lite
* @author	   Shozo Fukuda
* @date	create Sat Sep 26 06:26:30 JST 2020
* System	   MINGW64/Windows 10<br>
*
**/
/**************************************************************************{{{*/

#include <stdio.h>

#include "tiny_ml.h"

#include "tensorflow/lite/kernels/register.h"

#define TFLITE_EXPERIMENTAL 1

/***  Module Header  ******************************************************}}}*/
/**
* initialize interpreter
* @par DESCRIPTION
*
*
* @retval
**/
/**************************************************************************{{{*/
void init_interp(SysInfo& sys, std::string& tfl_model)
{
    // load tensor flow lite model
    sys.mModel = tflite::FlatBufferModel::BuildFromFile(tfl_model.c_str());

    tflite::ops::builtin::BuiltinOpResolver resolver;
    tflite::InterpreterBuilder builder(*sys.mModel, resolver);
    builder.SetNumThreads(sys.mNumThread);
    builder(&sys.mInterpreter);

    if (sys.mInterpreter->AllocateTensors() != kTfLiteOk) {
        std::cerr << "error: AllocateTensors()\n";
        exit(1);
    }
}

/***  Module Header  ******************************************************}}}*/
/**
* query dimension of input tensor
* @par DESCRIPTION
*
*
* @retval
**/
/**************************************************************************{{{*/
std::string
info(SysInfo& sys, const void*)
{
    json res;

    res["exe"  ]  = sys.mExe;
    res["model"]  = sys.mModelPath;
    res["label"]  = sys.mLabelPath;
    res["class"]  = sys.mNumClass;
    res["thread"] = sys.mNumThread;

    for (int index = 0; index < sys.mInterpreter->inputs().size(); index++) {
        TfLiteTensor* itensor = sys.mInterpreter->input_tensor(index);

        json tf_lite_tensor;
        tf_lite_tensor["name"] = std::string(itensor->name);
        tf_lite_tensor["type"] = std::string(TfLiteTypeGetName(itensor->type));
        for (int i = 0; i < itensor->dims->size; i++) {
            tf_lite_tensor["dims"].push_back(itensor->dims->data[i]);
        }

        res["inputs"].push_back(tf_lite_tensor);
    }

    for (int index = 0; index < sys.mInterpreter->outputs().size(); index++) {
        TfLiteTensor* itensor = sys.mInterpreter->output_tensor(index);

        json tf_lite_tensor;
        tf_lite_tensor["name"] = std::string(itensor->name);
        tf_lite_tensor["type"] = std::string(TfLiteTypeGetName(itensor->type));
        for (int i = 0; i < itensor->dims->size; i++) {
            tf_lite_tensor["dims"].push_back(itensor->dims->data[i]);
        }

        res["outputs"].push_back(tf_lite_tensor);
    }

#if TFLITE_EXPERIMENTAL
    int first_node_id = sys.mInterpreter->execution_plan()[0];
    const auto& first_node_reg =
        sys.mInterpreter->node_and_registration(first_node_id)->second;
    res["XNNPack"] = (tflite::GetOpNameByRegistration(first_node_reg) == "DELEGATE TfLiteXNNPackDelegate");
#endif

	for (int index = 0; index < sys.mUsedLap; index++) {
		res["times"].push_back(sys.mLap[index].count());
	}

    return res.dump();
}

/***  Module Header  ******************************************************}}}*/
/**
* set input tensor
* @par DESCRIPTION
*
*
* @retval
**/
/**************************************************************************{{{*/
static int
set_itensor(SysInfo& sys, const void* args)
{
    struct Prms {
        unsigned int size;
        unsigned int index;
        unsigned int dtype;
        float         min;
        float         max;
        uint8_t        data[0];
    } __attribute__((packed));
    const Prms*  prms = reinterpret_cast<const Prms*>(args);
    const size_t prms_size = sizeof(prms->size) + prms->size;
    const size_t data_size = prms_size - sizeof(Prms);

    if (prms->index >= sys.mInterpreter->inputs().size()) {
        return -1;
    }

    TfLiteTensor* itensor = sys.mInterpreter->input_tensor(prms->index);


    switch (prms->dtype) {
    case 0:
		if (data_size != itensor->bytes) {
			return -2;
		}

        memcpy(itensor->data.raw, prms->data, data_size);
        break;

    case 1:
    	{
			if (data_size != itensor->bytes/sizeof(float)) {
				return -2;
			}

			double a = (prms->max - prms->min)/255.0;
			double b = prms->min;
	
			float* dst = itensor->data.f;
			const uint8_t* src = prms->data;
			for (int i = 0; i < data_size; i++) {
				*dst = a*(*src) + b;
				dst++;
				src++;
			}
        }
        break;

    default:
    	return -3;
    }

    return prms_size;
}

std::string
set_input_tensor(SysInfo& sys, const void* args)
{
    json res;

    sys.start_watch();

    int status = set_itensor(sys, args);
    res["status"] = (status >= 0) ? 0 : status;

    sys.lap();

    return res.dump();
}

/***  Module Header  ******************************************************}}}*/
/**
* execute inference
* @par DESCRIPTION
*
*
* @retval
**/
/**************************************************************************{{{*/
std::string
invoke(SysInfo& sys, const void*)
{
    json res;

    sys.start_watch();

    res["status"] = sys.mInterpreter->Invoke();
    
    sys.lap();

    return res.dump();
}

/***  Module Header  ******************************************************}}}*/
/**
* get result tensor
* @par DESCRIPTION
*
*
* @retval
**/
/**************************************************************************{{{*/
std::string
get_output_tensor(SysInfo& sys, const void* args)
{
	std::string res;

    struct Prms {
        unsigned int index;
    } __attribute__((packed));
    const Prms*  prms = reinterpret_cast<const Prms*>(args);

    if (prms->index >= sys.mInterpreter->outputs().size()) {
        return std::string("");
    }

    sys.start_watch();

    TfLiteTensor* otensor = sys.mInterpreter->output_tensor(prms->index);

    res.assign(otensor->data.raw, otensor->bytes);

    sys.lap();

    return res;
}

/***  Module Header  ******************************************************}}}*/
/**
* execute inference in session mode
* @par DESCRIPTION
*
*
* @retval
**/
/**************************************************************************{{{*/
std::string
run(SysInfo& sys, const void* args)
{
    // set input tensors
    struct Prms {
        unsigned int  count;
        unsigned char data[0];
    } __attribute__((packed));
    const Prms* prms = reinterpret_cast<const Prms*>(args);

    sys.start_watch();
    
    const unsigned char* ptr = prms->data;
    for (int i = 0; i < prms->count; i++) {
    	int next = set_itensor(sys, ptr);
    	if (next < 0) {
    		// error about input tensors: error_code {-1..-3}
    		return std::string(reinterpret_cast<char*>(&next), sizeof(next));
    	}
        
        ptr += next;
    }
    
    sys.lap();

    // invoke
    int status = sys.mInterpreter->Invoke();
    if (status != kTfLiteOk) {
		// error about invoke: error_code {-11..}
		status = -(10 + status);
		return std::string(reinterpret_cast<char*>(&status), sizeof(status));
    }

    sys.lap();

   	// get output tensors  <<count::little-integer-32, size::little-integer-32, bin::binary-size(size), ..>>
    int count = sys.mInterpreter->outputs().size();
    std::string output(reinterpret_cast<char*>(&count), sizeof(count));

   	for (int index = 0; index < count; index++) {
        TfLiteTensor* otensor = sys.mInterpreter->output_tensor(index);
        int size = otensor->bytes;
        output += std::string(reinterpret_cast<char*>(&size), sizeof(size))
               +  std::string(otensor->data.raw, otensor->bytes);
    }

    sys.lap();

    return output;
}

/*** tfl_interp.cc ********************************************************}}}*/
