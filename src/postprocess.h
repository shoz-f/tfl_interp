/***  File Header  ************************************************************/
/**
* postprocess.h
*
* system setting - used throughout the system
* @author	   Shozo Fukuda
* @date	create Tue Jul 13 14:32:28 JST 2021
* System	   MINGW64/Windows 10<br>
*
*******************************************************************************/
#ifndef _POSTPROCESS_H
#define _POSTPROCESS_H

/**************************************************************************}}}**
* 
***************************************************************************{{{*/
TMLFunc non_max_suppression_multi_class;

#define POST_PROCESS \
    non_max_suppression_multi_class,

#endif /* _POSTPROCESS_H */
