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

#include <iostream>
#include <fstream>
#include <string>
using namespace std;

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif

#include <getopt.h>

#include "tfl_interp.h"
#include "tfl_postprocess.h"

#define TFLITE_EXPERIMENTAL 1

/***  Global **************************************************************}}}*/
/**
* system infomation
**/
/**************************************************************************{{{*/
SysInfo gSys = {
    .mTiny      = false,
    .mDiag      = 0
};

/***  Module Header  ******************************************************}}}*/
/**
* query dimension of input tensor
* @par DESCRIPTION
*   
*
* @retval 
**/
/**************************************************************************{{{*/
string
info(const string&)
{
    json res;

    res["exe"  ] = gSys.mExe;
    res["model"] = gSys.mTflModel;
    res["class"] = gSys.mNumClass;
    
    for (int index = 0; index < gSys.mInterpreter->inputs().size(); index++) {
        TfLiteTensor* itensor = gSys.mInterpreter->input_tensor(index);

        json tf_lite_tensor;
        tf_lite_tensor["name"] = string(itensor->name);
        tf_lite_tensor["type"] = string(TfLiteTypeGetName(itensor->type));
        for (int i = 0; i < itensor->dims->size; i++) {
            tf_lite_tensor["dims"].push_back(itensor->dims->data[i]);
        }

        res["inputs"].push_back(tf_lite_tensor);
    }

    for (int index = 0; index < gSys.mInterpreter->outputs().size(); index++) {
        TfLiteTensor* itensor = gSys.mInterpreter->output_tensor(index);

        json tf_lite_tensor;
        tf_lite_tensor["name"] = string(itensor->name);
        tf_lite_tensor["type"] = string(TfLiteTypeGetName(itensor->type));
        for (int i = 0; i < itensor->dims->size; i++) {
            tf_lite_tensor["dims"].push_back(itensor->dims->data[i]);
        }

        res["outputs"].push_back(tf_lite_tensor);
    }

#if TFLITE_EXPERIMENTAL
    int first_node_id = gSys.mInterpreter->execution_plan()[0];
    const auto& first_node_reg = 
        gSys.mInterpreter->node_and_registration(first_node_id)->second;
    res["XNNPack"] = (GetOpNameByRegistration(first_node_reg) == "DELEGATE TfLiteXNNPackDelegate");
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
string
set_input_tensor(const string& args)
{
    json res;

    struct Prms {
        unsigned char cmd;
        unsigned char index;
        char data[0];
    } __attribute__((packed));
    const Prms*  prms = reinterpret_cast<const Prms*>(args.data());
    const size_t size = args.size() - sizeof(Prms);

    if (prms->index >= gSys.mInterpreter->inputs().size()) {
        res["status"] = -1;
        return res.dump();
    }
    TfLiteTensor* itensor = gSys.mInterpreter->input_tensor(prms->index);

    if (size != itensor->bytes) {
        res["status"] = -2;
        return res.dump();
    }
    
    memcpy(itensor->data.raw, prms->data, itensor->bytes);
    res["status"] = 0;
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
string
invoke(const string&)
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
string
get_output_tensor(const string& args)
{
    json res;

    struct Prms {
        unsigned char cmd;
        unsigned char index;
    } __attribute__((packed));
    const Prms*  prms = reinterpret_cast<const Prms*>(args.data());

    if (prms->index >= gSys.mInterpreter->outputs().size()) {
        return string("");
    }
    TfLiteTensor* otensor = gSys.mInterpreter->output_tensor(prms->index);

    return string(otensor->data.raw, otensor->bytes);
}

/**************************************************************************}}}**
* command dispatch table
***************************************************************************{{{*/
typedef string (*TflFunc)(const string&);

TflFunc gCmdTbl[] = {
    info,
    set_input_tensor,
    invoke,
    get_output_tensor,
    non_max_suppression_multi_class,
};

const int gMaxCmd = sizeof(gCmdTbl)/sizeof(TflFunc);

/***  Module Header  ******************************************************}}}*/
/**
* tensor flow lite interpreter
* @par DESCRIPTION
*   
**/
/**************************************************************************{{{*/
void
interp(string& tfl_model, string& tfl_label)
{
    // load tensor flow lite model
    unique_ptr<tflite::FlatBufferModel> model =
        tflite::FlatBufferModel::BuildFromFile(tfl_model.c_str());

    tflite::ops::builtin::BuiltinOpResolver resolver;
    InterpreterBuilder(*model, resolver)(&gSys.mInterpreter);

    if (gSys.mInterpreter->AllocateTensors() != kTfLiteOk) {
        cerr << "error: AllocateTensors()\n";
        exit(1);
    }

    // load labels
    string   label;
    ifstream lb_file(tfl_label);
    if (lb_file.fail()) {
        cerr << "error: Failed to open file\n";
        exit(1);
    }
    while (getline(lb_file, label)) {
        gSys.mLabel.emplace_back(label);
    }
    gSys.mNumClass = gSys.mLabel.size();

    // REPL
    for (;;) {
        // receive command packet
        string cmd_line;
        ssize_t n = gSys.mRcv(cmd_line);
        if (n <= 0) {
            break;
        }

        // command branch
        string result;

        int cmd = cmd_line.front();
        if (cmd < gMaxCmd) {
            result = gCmdTbl[cmd](cmd_line);
        }
        else {
            result = cmd_line;
        }

        // send the result in JSON string
        n = gSys.mSnd(result);
        if (n <= 0) {
            break;
        }
    }
}

/***  Module Header  ******************************************************}}}*/
/**
* prit usage
* @par DESCRIPTION
*   print usage to terminal
**/
/**************************************************************************{{{*/
void usage()
{
    cout
      << "tfl_interp [opts] <model.tflite> <class.label>\n"
      << "\toption:\n"
      << "\t  -p       : Elixir/Erlang Ports interface\n"
      << "\t  -n       : Normalize BBox predictions by 1.0x1.0\n"
      << "\t  -d <num> : diagnosis mode\n"
      << "\t             1 = save the formed image\n"
      << "\t             2 = save model's input/output tensors\n"
      << "\t             4 = save result of the prediction\n";
}

/***  Module Header  ******************************************************}}}*/
/**
* tensor flow lite for Elixir/Erlang Port ext.
* @par DESCRIPTION
*   Elixir/Erlang Port extension (experimental)
*
* @return exit status
**/
/**************************************************************************{{{*/
int
main(int argc, char* argv[])
{
    int opt, longindex;
    struct option longopts[] = {
        { "tiny",   no_argument,       NULL, 't' },
        { "debug",  required_argument, NULL, 'd' },
        { 0,        0,                 0,     0  },
    };

    for (;;) {
        opt = getopt_long(argc, argv, "d:t", longopts, NULL);
        if (opt == -1) {
            break;
        }
        else switch (opt) {
        case 't':
            gSys.mTiny = true;
            break;
        case 'd':
            gSys.mDiag = atoi(optarg);
            break;
        case '?':
        case ':':
            cerr << "error: unknown options\n\n";
            usage();
            return 1;
        }
    }
    if ((argc - optind) < 1) {
        // argument error
        cerr << "error: expect <model.tflite>\n\n";
        usage();
        return 1;
    }

    // save exe infomations
    gSys.mExe.assign(argv[0]);
    gSys.mTflModel.assign(argv[optind]);
    gSys.mTflLabel.assign(argv[optind+1]);

    // initialize i/o
    cin.exceptions(ios_base::badbit|ios_base::failbit|ios_base::eofbit);
    cout.exceptions(ios_base::badbit|ios_base::failbit|ios_base::eofbit);
    
#ifdef _WIN32
	setmode(fileno(stdin),  O_BINARY);
	setmode(fileno(stdout), O_BINARY);
#endif
	gSys.mRcv = rcv_packet_port;
	gSys.mSnd = snd_packet_port;

    // run interpreter
    interp(gSys.mTflModel, gSys.mTflLabel);

    return 0;
}

/*** tfl_interp.cc ********************************************************}}}*/
