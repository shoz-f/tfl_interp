/***  File Header  ************************************************************/
/**
* tfl_interp.h
*
* system setting - used throughout the system
* @author	   Shozo Fukuda
* @date	create Thu Nov 12 17:55:58 JST 2020
* System	   MINGW64/Windows 10<br>
*
*******************************************************************************/
#ifndef _TFL_INTERP_H
#define _TFL_INTERP_H

#include <string>
#include <vector>
#include <memory>
using namespace std;

#include "nlohmann/json.hpp"
using json = nlohmann::json;

#include "tensorflow/lite/interpreter.h"
#include "tensorflow/lite/kernels/register.h"
#include "tensorflow/lite/model.h"
using namespace tflite;

/**************************************************************************}}}**
* system information
***************************************************************************{{{*/
struct SysInfo {
    string        mExe;       // path of this executable
    string        mTflModel;  // path of Tflite Model
    string        mTflLabel;  // path of Class Labels
    bool          mTiny;      // Yolo V3 tiny model
    unsigned long mDiag;      // diagnosis mode
    int           mNumThread; // number of thread

    unique_ptr<Interpreter> mInterpreter;
    vector<string>          mLabel;
    unsigned int          mNumClass;

/*
    steady_clock::time_point mWatchStart;
    milliseconds    mLap1;      //
    milliseconds    mLap2;      //
    milliseconds    mLap3;      //
*/

    // i/o method
    ssize_t (*mRcv)(string& cmd_line);
    ssize_t (*mSnd)(string  result);
    
    string label(int id) {
        if (id < mLabel.size()) {
            return mLabel[id];
        }
        else {
            return to_string(id);
        }
    }
};
extern SysInfo gSys;

/**************************************************************************}}}**
* i/o functions
***************************************************************************{{{*/
ssize_t rcv_packet_port(string& cmd_line);
ssize_t snd_packet_port(string result);

#endif /* _TFL_INTERP_H */
