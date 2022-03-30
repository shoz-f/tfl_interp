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
#include "postprocess.h"

#include <fstream>

#ifdef _WIN32
#include <fcntl.h>
#include <io.h>
#endif

#include <getopt.h>

/***  Global **************************************************************}}}*/
/**
* system infomation
**/
/**************************************************************************{{{*/
SysInfo gSys;

/**************************************************************************}}}**
* command dispatch table
***************************************************************************{{{*/
TMLFunc* gCmdTbl[] = {
    info,
    set_input_tensor,
    invoke,
    get_output_tensor,
    run,
    
    POST_PROCESS
};

const int gMaxCmd = sizeof(gCmdTbl)/sizeof(TMLFunc*);

/***  Module Header  ******************************************************}}}*/
/**
* tensor flow lite interpreter
* @par DESCRIPTION
*   
**/
/**************************************************************************{{{*/
#include "tensorflow/lite/kernels/register.h"
#include "tensorflow/lite/model.h"

void
interp(std::string& tfl_model, std::string& tfl_label)
{
#if 0
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
#else
    init_interp(gSys, tfl_model);
#endif

    // load labels
    if (tfl_label != "none") {
        std::string   label;
        std::ifstream lb_file(tfl_label);
        if (lb_file.fail()) {
            std::cerr << "error: Failed to open file\n";
            exit(1);
        }
        while (getline(lb_file, label)) {
            gSys.mLabel.emplace_back(label);
        }
        gSys.mNumClass = gSys.mLabel.size();
    }
    else {
        gSys.mLabel.clear();
        gSys.mNumClass = 0;
    }

    // REPL
    for (;;) {
        // receive command packet
        std::string cmd_line;
        ssize_t n = gSys.mRcv(cmd_line);
        if (n <= 0) {
            break;
        }

        // command branch
        struct Cmd {
            unsigned int cmd;
            uint8_t        args[0];
        } __attribute__((packed));
        const Cmd& call = *reinterpret_cast<const Cmd*>(cmd_line.data());

        std::string result;

        if (call.cmd < gMaxCmd) {
            result = gCmdTbl[call.cmd](gSys, call.args);
        }
        else {
            result = "unknown command";//cmd_line;
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
    std::cout
      << "tfl_interp [opts] <model.tflite> <class.label>\n"
      << "\toption:\n"
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
    const struct option longopts[] = {
        { "tiny",     no_argument,       NULL, 't' },
        { "debug",    required_argument, NULL, 'd' },
        { "parallel", required_argument, NULL, 'j' },
        { 0,          0,                 0,     0  },
    };

    // initialize system environment
    gSys.mTiny      = false;
    gSys.mDiag      = 0;
    gSys.mNumThread = 4;
    gSys.reset_lap();

    for (;;) {
        opt = getopt_long(argc, argv, "d:tj:", longopts, NULL);
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
        case 'j':
            gSys.mNumThread = atoi(optarg);
            break;
        case '?':
        case ':':
            std::cerr << "error: unknown options\n\n";
            usage();
            return 1;
        }
    }
    if ((argc - optind) < 2) {
        // argument error
        std::cerr << "error: expect <model.tflite>\n\n";
        usage();
        return 1;
    }

    // save exe infomations
    gSys.mExe.assign(argv[0]);
    gSys.mModelPath.assign(argv[optind]);
    gSys.mLabelPath.assign(argv[optind+1]);

    // initialize i/o
    std::cin.exceptions(std::ios_base::badbit|std::ios_base::failbit|std::ios_base::eofbit);
    std::cout.exceptions(std::ios_base::badbit|std::ios_base::failbit|std::ios_base::eofbit);

#ifdef _WIN32
	setmode(fileno(stdin),  O_BINARY);
	setmode(fileno(stdout), O_BINARY);
#endif
	gSys.mRcv = rcv_packet_port;
	gSys.mSnd = snd_packet_port;

    // run interpreter
    interp(gSys.mModelPath, gSys.mLabelPath);

    return 0;
}

/*** tfl_interp.cc ********************************************************}}}*/
