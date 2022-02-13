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

#include "tiny_ml.h"

#include "tensorflow/lite/kernels/register.h"
#include "tensorflow/lite/model.h"

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
void init_interp(std::string& tfl_model)
{
    // load tensor flow lite model
    std::unique_ptr<tflite::FlatBufferModel> model =
        tflite::FlatBufferModel::BuildFromFile(tfl_model.c_str());

    tflite::ops::builtin::BuiltinOpResolver resolver;
    tflite::InterpreterBuilder builder(*model, resolver);
    builder.SetNumThreads(gSys.mNumThread);
    builder(&gSys.mInterpreter);

    if (gSys.mInterpreter->AllocateTensors() != kTfLiteOk) {
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
info(const std::string&)
{
    json res;

    res["exe"  ]  = gSys.mExe;
    res["model"]  = gSys.mModelPath;
    res["label"]  = gSys.mLabelPath;
    res["class"]  = gSys.mNumClass;
    res["thread"] = gSys.mNumThread;
    
    for (int index = 0; index < gSys.mInterpreter->inputs().size(); index++) {
        TfLiteTensor* itensor = gSys.mInterpreter->input_tensor(index);

        json tf_lite_tensor;
        tf_lite_tensor["name"] = std::string(itensor->name);
        tf_lite_tensor["type"] = std::string(TfLiteTypeGetName(itensor->type));
        for (int i = 0; i < itensor->dims->size; i++) {
            tf_lite_tensor["dims"].push_back(itensor->dims->data[i]);
        }

        res["inputs"].push_back(tf_lite_tensor);
    }

    for (int index = 0; index < gSys.mInterpreter->outputs().size(); index++) {
        TfLiteTensor* itensor = gSys.mInterpreter->output_tensor(index);

        json tf_lite_tensor;
        tf_lite_tensor["name"] = std::string(itensor->name);
        tf_lite_tensor["type"] = std::string(TfLiteTypeGetName(itensor->type));
        for (int i = 0; i < itensor->dims->size; i++) {
            tf_lite_tensor["dims"].push_back(itensor->dims->data[i]);
        }

        res["outputs"].push_back(tf_lite_tensor);
    }

#if TFLITE_EXPERIMENTAL
    int first_node_id = gSys.mInterpreter->execution_plan()[0];
    const auto& first_node_reg = 
        gSys.mInterpreter->node_and_registration(first_node_id)->second;
    res["XNNPack"] = (tflite::GetOpNameByRegistration(first_node_reg) == "DELEGATE TfLiteXNNPackDelegate");
#endif
    return res.dump();
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
set_input_tensor(const std::string& args)
{
    json res;

    struct Prms {
        unsigned char cmd;
        unsigned char index;
        unsigned char dtype;
        unsigned char _1;
        float          min;
        float          max;
        uint8_t         data[0];
    } __attribute__((packed));
    const Prms*  prms = reinterpret_cast<const Prms*>(args.data());
    const size_t size = args.size() - sizeof(Prms);

    if (prms->index >= gSys.mInterpreter->inputs().size()) {
        res["status"] = -1;
        return res.dump();
    }
    TfLiteTensor* itensor = gSys.mInterpreter->input_tensor(prms->index);

    res["status"] = 0;
    switch (prms->dtype) {
    case 0:
        if (size == itensor->bytes) {
            memcpy(itensor->data.raw, prms->data, itensor->bytes);
        }
        else {
            res["status"] = -2;
        }
        break;

    case 1:
        if (size == itensor->bytes/sizeof(float)) {
            float rang = (prms->max - prms->min)/255.0;
            float base = prms->min;

            float* dst = itensor->data.f;
            const uint8_t* src = prms->data;
            for (int i = 0; i < (itensor->bytes/sizeof(float)); i++) {
                *dst = (rang * (*src)) - base;
                dst++;
                src++;
            }
        }
        else {
            res["status"] = -2;
        }
        break;

    case 2:
        res["status"] = -3;
        break;
    default:
        res["status"] = -3;
        break;
    }

    return res.dump();
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
invoke(const std::string&)
{
    json res;

    res["status"] = gSys.mInterpreter->Invoke();
    return res.dump();
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
get_output_tensor(const std::string& args)
{
    json res;

    struct Prms {
        unsigned char cmd;
        unsigned char index;
    } __attribute__((packed));
    const Prms*  prms = reinterpret_cast<const Prms*>(args.data());

    if (prms->index >= gSys.mInterpreter->outputs().size()) {
        return std::string("");
    }
    TfLiteTensor* otensor = gSys.mInterpreter->output_tensor(prms->index);

    return std::string(otensor->data.raw, otensor->bytes);
}

/*** tfl_interp.cc ********************************************************}}}*/
