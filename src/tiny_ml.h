/***  File Header  ************************************************************/
/**
* tiny_ml.h
*
* system setting - used throughout the system
* @author	   Shozo Fukuda
* @date	create Sun Feb 13 15:17:40 JST 2022
* System	   MINGW64/Windows 10<br>
*
*******************************************************************************/
#ifndef _TINY_ML_H
#define _TINY_ML_H

#include <iostream>
#include <string>
#include <vector>

#include "nlohmann/json.hpp"
using json = nlohmann::json;

#include "tensorflow/lite/interpreter.h"
#include "tensorflow/lite/model.h"

/**************************************************************************}}}**
* system information
***************************************************************************{{{*/
struct SysInfo {
    std::string     mExe;       // path of this executable
    std::string     mModelPath; // path of Tflite Model
    std::string     mLabelPath; // path of Class Labels
    bool           mTiny;       // Yolo V3 tiny model
    unsigned long mDiag;       // diagnosis mode
    int            mNumThread;  // number of thread

    std::unique_ptr<tflite::Interpreter> mInterpreter;
    std::unique_ptr<tflite::FlatBufferModel> mModel;

    std::vector<std::string> mLabel;
    unsigned int mNumClass;

/*
    steady_clock::time_point mWatchStart;
    milliseconds    mLap1;      //
    milliseconds    mLap2;      //
    milliseconds    mLap3;      //
*/

    // i/o method
    ssize_t (*mRcv)(std::string& cmd_line);
    ssize_t (*mSnd)(std::string result);

    std::string label(int id) {
        return (id < mLabel.size()) ? mLabel[id] : std::to_string(id);
    }
};

extern SysInfo gSys;

/**************************************************************************}}}**
* i/o functions
***************************************************************************{{{*/
ssize_t rcv_packet_port(std::string& cmd_line);
ssize_t snd_packet_port(std::string result);

/**************************************************************************}}}**
* service call functions
***************************************************************************{{{*/
void init_interp(SysInfo& sys, std::string& model);

typedef std::string (TMLFunc)(SysInfo& sys, const std::string& args);
TMLFunc info;
TMLFunc set_input_tensor;
TMLFunc invoke;
TMLFunc get_output_tensor;

#endif /* _TINY_ML_H */
