/***  File Header  ************************************************************/
/**
* tfl_nonmaxsuppression.cc
*
* Elixir/Erlang Port ext. of tensor flow lite: post processing
* @author	   Shozo Fukuda
* @date	create Tue Jul 13 14:25:06 JST 2021
* System	   MINGW64/Windows 10<br>
*
**/
/**************************************************************************{{{*/

#include <queue>
using namespace std;

#include "tfl_postprocess.h"

/***  Class Header  *******************************************************}}}*/
/**
* bounding box
* @par DESCRIPTION
*   it holds bbox and score needed for NMS and provides IOU function.
**/
/**************************************************************************{{{*/
class Box {
//LIFECYCLE:
public:
    Box(const float box[4], const float score) {
        mBBox[0] = box[0] - box[2]/2.0;
        mBBox[1] = box[1] - box[3]/2.0;
        mBBox[2] = box[0] + box[2]/2.0;
        mBBox[3] = box[1] + box[3]/2.0;
        mArea = box[2]*box[3];
        
        mScore = score;
    }

//ACTION:
public:
    // calc Intersection over Union
    float iou(const Box& x) const {
        float x1 = max(mBBox[0], x.mBBox[0]);
        float y1 = max(mBBox[1], x.mBBox[1]);
        float x2 = min(mBBox[2], x.mBBox[2]);
        float y2 = min(mBBox[3], x.mBBox[3]);
        
        if (x1 < x2 && y1 < y2) {
            float v_intersection = (x2 - x1)*(y2 - y1);
            float v_union        = mArea + x.mArea - v_intersection;
            return v_intersection/v_union;
        }
        else {
            return 0.0;
        }
    }

    // put out the scaled BBox in JSON formatting
    json to_json() const {
        auto result = json::array();
        result.push_back(mScore);
        result.push_back(mBBox[0]);
        result.push_back(mBBox[1]);
        result.push_back(mBBox[2]);
        result.push_back(mBBox[3]);
        return result;
    }

//ACCESSOR:
public:
    void set_score(float score) {
        mScore = score;
    }
    
    float get_score() {
        return mScore;
    }

//ACCESSOR:
public:
    float score() {
        return mScore;
    }

//ATTRIBUTE:
protected:
    float         mBBox[4];
    float         mArea;
    float         mScore;
};

/***  Module Header  ******************************************************}}}*/
/**
* Non Maximum Suppression for Multi Class
* @par DESCRIPTION
*   run non-maximum on every class
*
* @retval json
**/
/**************************************************************************{{{*/
string
non_max_suppression_multi_class(const string& args)
{
    json res;

    struct Prms {
        unsigned char  cmd;
        unsigned char  idx_boxes;
        unsigned char  idx_scores;
        float           iou_threshold;
        float           score_threshold;
        float           sigma;
    } __attribute__((packed));
    const Prms*  prms = reinterpret_cast<const Prms*>(args.data());

    TfLiteTensor* ts_boxes  = gSys.mInterpreter->output_tensor(prms->idx_boxes);
    TfLiteTensor* ts_scores = gSys.mInterpreter->output_tensor(prms->idx_scores);

    const int num_class = gSys.mNumClass;
    const int num_boxes = ts_boxes->dims->data[1];

    // run nms over each classification class.
    for (int class_id = 0; class_id < num_class; class_id++) {
        auto cmp = [](Box& a, Box& b){ return a.score() < b.score(); };
        priority_queue<Box, deque<Box>, decltype(cmp)> candidates(cmp);

        // pick up candidates for focus class
        const float* boxes  = ts_boxes->data.f;
        const float* scores = ts_scores->data.f;
        for (int i = 0; i < num_boxes; i++, boxes += 4, scores += num_class) {
            if (scores[class_id] > prms->score_threshold) {
                candidates.emplace(boxes, scores[class_id]);
            }
        }
        if (candidates.empty()) continue;

        // perform iou filtering
        string class_name = gSys.mLabel[class_id];
        do {
            Box selected = candidates.top();  candidates.pop();

            res[class_name].push_back(selected.to_json());

            while (!candidates.empty()) {
                float iou = selected.iou(candidates.top());
                if (iou < prms->iou_threshold) { break; }

                if (prms->sigma > 0.0) {
                    Box next = candidates.top(); candidates.pop();
                    float soft_nms_score = next.get_score()*exp(-(iou*iou)/prms->sigma);
                    if (soft_nms_score > prms->score_threshold) {
                        next.set_score(soft_nms_score);
                        candidates.push(next);
                    }
                }
                else {
                    candidates.pop();
                }
            }
        } while (!candidates.empty());
    }

    return res.dump();
}

/*** tfl_nonmaxsuppression.cc *********************************************}}}*/
