/*	Copyright: 	© Copyright 2005 Apple Computer, Inc. All rights reserved.

	Disclaimer:	IMPORTANT:  This Apple software is supplied to you by Apple Computer, Inc.
			("Apple") in consideration of your agreement to the following terms, and your
			use, installation, modification or redistribution of this Apple software
			constitutes acceptance of these terms.  If you do not agree with these terms,
			please do not use, install, modify or redistribute this Apple software.

			In consideration of your agreement to abide by the following terms, and subject
			to these terms, Apple grants you a personal, non-exclusive license, under Apple’s
			copyrights in this original Apple software (the "Apple Software"), to use,
			reproduce, modify and redistribute the Apple Software, with or without
			modifications, in source and/or binary forms; provided that if you redistribute
			the Apple Software in its entirety and without modifications, you must retain
			this notice and the following text and disclaimers in all such redistributions of
			the Apple Software.  Neither the name, trademarks, service marks or logos of
			Apple Computer, Inc. may be used to endorse or promote products derived from the
			Apple Software without specific prior written permission from Apple.  Except as
			expressly stated in this notice, no other rights or licenses, express or implied,
			are granted by Apple herein, including but not limited to any patent rights that
			may be infringed by your derivative works or by other works in which the Apple
			Software may be incorporated.

			The Apple Software is provided by Apple on an "AS IS" basis.  APPLE MAKES NO
			WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION THE IMPLIED
			WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS FOR A PARTICULAR
			PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND OPERATION ALONE OR IN
			COMBINATION WITH YOUR PRODUCTS.

			IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL OR
			CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
			GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
			ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION, MODIFICATION AND/OR DISTRIBUTION
			OF THE APPLE SOFTWARE, HOWEVER CAUSED AND WHETHER UNDER THEORY OF CONTRACT, TORT
			(INCLUDING NEGLIGENCE), STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN
			ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#ifndef _DEBUG_MACROS_H_
#define _DEBUG_MACROS_H_

#ifndef DEBUG
	#define DEBUG										1
#endif

#ifndef FUNCTION_IO_LOGGING
    #define FUNCTION_IO_LOGGING                         0
#endif


#if DEBUG
	#include <stdio.h>
	#include <syslog.h>
	#include <string.h>
	
	static const char * rFILE(const char * inStr) { 
		int count = strlen(inStr); 
		while (count && *(inStr + count - 1) != '/')
			count--;
		return inStr + count;
	}
	
	#define d_syslog(...)       syslog(LOG_INFO, __VA_ARGS__)
	
	#define DEBUGMSG(...)       do {	char tempstr[256];                                                                  \
										sprintf(tempstr, __VA_ARGS__);                                                      \
										fprintf(stderr, "%s:%d:%s %s\n", rFILE(__FILE__), __LINE__, __func__, tempstr);     \
								} while (0)
								
	#define BAILERR( x )        do {                                                                                            \
									OSStatus tErr = (x);																		\
									if ( tErr ) {                                                                               \
										fprintf(stderr, "%s:%d:%s ### Err %ld\n", rFILE(__FILE__), __LINE__, __func__, tErr);	\
										goto bail;                                                                              \
									}                                                                                           \
								} while (0)
								
	#define BAILSETERR( x )     do {                                                                                            \
									err = (x);	                                                                             	\
									if ( err ) {                                                                                \
										fprintf(stderr, "%s:%d:%s ### Err %ld\n", rFILE(__FILE__), __LINE__, __func__, err);  	\
										goto bail;                                                                              \
									}                                                                                           \
								} while (0)
								
	#define BAILIFTRUE( x, errCode )    do {																			\
											if ( (x) ) {                                                                \
												err = errCode;  														\
												if (err != noErr)                                                   	\
													fprintf(stderr, "%s:%d:%s ### Err %ld\n",                           \
														rFILE(__FILE__), __LINE__, __func__, err);             			\
												goto bail;                                              				\
											}                                                                           \
										} while (0)
								
	#define DEBUGERR( x )       do { 																							\
									OSStatus tErr = (x);                                                                    	\
									if ( tErr )                                                                             	\
										fprintf(stderr, "%s:%d:%s ### Err %ld\n", rFILE(__FILE__), __LINE__, __func__, tErr);	\
								} while (0)
								
	#define DEBUGSTR(...)       do {    char tempstr[256];                  \
										sprintf(tempstr, __VA_ARGS__);      \
										fprintf(stderr, "%s\n", tempstr);   \
								} while (0)
	
	#define MSG_ON_ERROR(...)   do { if (err) fprintf(stderr, __VA_ARGS__); } while (0)

	#include <assert.h>
	
	#define ASSERT(x)	assert(x)

	#define TRESPASS()                                                                      			\
			do																							\
			{																							\
				fprintf(stderr,"should not be here (%s:%d:%s)\n", rFILE(__FILE__), __LINE__, __func__);	\
				assert(0);																				\
			}																							\
			while (0)

	#define DEBUG_ONLY(x)	x
#else
    #define d_syslog(...)
    #define DEBUGMSG(...)
    #define BAILERR(x)                  do { OSStatus tErr = (x); if (tErr) goto bail; } while (0)
    #define BAILSETERR(x)               do { err = (x); if (err) { goto bail; } } while (0)
    #define BAILIFTRUE(x, errCode)      do { err = (x); if (err) { err = errCode; goto bail; } } while (0)
    #define DEBUGERR( x ) 
    #define DEBUGSTR(...)
    #define ASSERT(x)
    #define TRESPASS()
    #define MSG_ON_ERROR(...)
    #define DEBUG_ONLY(x)
#endif

#define SILENTBAILSETERR(x)             do { err = (x); if (err) { goto bail; } } while (0)

#if FUNCTION_IO_LOGGING
    #define FUNC_ENTRY()                DEBUGSTR("->%s", __func__)
    #define FUNC_EXIT()                 DEBUGSTR("<-%s", __func__)
#else
    #define FUNC_ENTRY()
    #define FUNC_EXIT()
#endif

#endif	/* _DEBUG_MACROS_H_ */

