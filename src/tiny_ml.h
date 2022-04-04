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

#include <chrono>
namespace chrono = std::chrono;

#include "nlohmann/json.hpp"
using json = nlohmann::json;

#include "tensorflow/lite/interpreter.h"
#include "tensorflow/lite/model.h"

/**************************************************************************}}}**
* system information
***************************************************************************{{{*/
#define NUM_LAP	10

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

	chrono::steady_clock::time_point mWatchStart;
	chrono::milliseconds mLap[NUM_LAP];

    // i/o method
    ssize_t (*mRcv)(std::string& cmd_line);
    ssize_t (*mSnd)(std::string result);

    std::string label(int id) {
        return (id < mLabel.size()) ? mLabel[id] : std::to_string(id);
    }
    
    void reset_lap() {
    	for (int i = 0; i < NUM_LAP; i++) { mLap[i] = chrono::milliseconds(0); }
    }
    void start_watch() {
    	reset_lap();
    	mWatchStart = chrono::steady_clock::now();
    }
    void lap(int index) {
    	chrono::steady_clock::time_point now = chrono::steady_clock::now();
    	mLap[index] = chrono::duration_cast<chrono::milliseconds>(now - mWatchStart);
    	mWatchStart = now;
    }
};

#define LAP_INPUT()		lap(0)
#define LAP_EXEC()		lap(1)
#define LAP_OUTPUT()	lap(2)

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

typedef std::string (TMLFunc)(SysInfo& sys, const void* args);
TMLFunc info;
TMLFunc set_input_tensor;
TMLFunc invoke;
TMLFunc get_output_tensor;
TMLFunc run;

#endif /* _TINY_ML_H */
