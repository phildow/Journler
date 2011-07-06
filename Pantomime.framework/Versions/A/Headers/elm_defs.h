#ifndef _Pantomime_H_elm_defs
#define _Pantomime_H_elm_defs
/*******************************************************************************
 *  The Elm Mail System  -  $Revision: 1.1.1.1 $   $State: Exp $
 *
 *                      Copyright (c) 1988-1998 USENET Community Trust
 * 			Copyright (c) 1986,1987 Dave Taylor
 *******************************************************************************
 * Bug reports, patches, comments, suggestions should be sent to:
 *
 *      Bill Pemberton, Elm Coordinator
 *      flash@virginia.edu
 *
 *******************************************************************************
 * $Log: elm_defs.h,v $
 * Revision 1.1.1.1  2004/11/27 21:21:11  ludo
 * Pantomime import
 *
 * Revision 1.3  2003/09/06 12:32:21  ludo
 * See ChangeLog
 *
 * Revision 1.2  2003/01/30 21:08:41  ludo
 * see changelog
 *
 * Revision 1.1.1.1  2001/11/21 18:25:36  ludo
 * Imported Sources
 *
 * Revision 1.3  2001/10/12 18:09:58  ludo
 * See ChangeLog
 *
 * Revision 1.2  2001/10/01 15:33:30  ludo
 * See changelog
 *
 * Revision 1.1.1.1  2001/09/28 13:06:56  ludo
 * Import of sources
 *
 * Revision 1.1.1.1  2001/07/28 00:06:35  ludovic
 * Imported Sources
 *
 * Revision 1.7  1999/03/24  14:03:42  wfp5p
 * elm 2.5PL0
 *
 * Revision 1.6  1996/10/28  16:58:03  wfp5p
 * Beta 1
 *
 * Revision 1.4  1996/05/09  15:50:55  wfp5p
 * Alpha 10
 *
 * Revision 1.3  1996/03/14  17:27:21  wfp5p
 * Alpha 9
 *
 * Revision 1.1  1995/09/29  17:40:47  wfp5p
 * Alpha 8 (Chip's big changes)
 *
 * Revision 1.14  1995/09/11  15:18:45  wfp5p
 * Alpha 7
 *
 * Revision 1.13  1995/07/18  18:59:45  wfp5p
 * Alpha 6
 *
 * Revision 1.12  1995/06/30  14:56:17  wfp5p
 * Alpha 5
 *
 * Revision 1.11  1995/06/21  15:26:34  wfp5p
 * editflush and confirmtagsave are new in the elmrc (Keith Neufeld)
 *
 * Revision 1.10  1995/06/14  19:58:07  wfp5p
 * Changes for alpha 3
 *
 * Revision 1.9  1995/06/12  20:32:29  wfp5p
 * Fixed up a couple of multiple declares
 *
 * Revision 1.8  1995/06/09  22:06:53  wfp5p
 * Added the correct date for the alpha 1 release
 *
 * Revision 1.7  1995/06/01  13:13:20  wfp5p
 * Readmsg was fixed to work correctly if called from within elm.  From Chip
 * Rosenthal <chip@unicom.com>
 *
 * Revision 1.6  1995/05/24  15:32:47  wfp5p
 * Added a few changes from Keith Neufeld <neufeld@pvi.org>
 *
 * Revision 1.5  1995/05/10  13:34:27  wfp5p
 * Added mailing list stuff by Paul Close <pdc@sgi.com>
 * And NetBSD stuff.
 *
 * Revision 1.4  1995/04/21  18:05:36  wfp5p
 * Added more options to attribution
 *
 * Revision 1.3  1995/04/21  13:30:21  wfp5p
 * Added a the Ultirx fflush() bug fix.
 *
 * Revision 1.2  1995/04/20  21:01:08  wfp5p
 * Removed filter
 *
 * Revision 1.1.1.1  1995/04/19  20:38:30  wfp5p
 * Initial import of elm 2.4 PL0 as base for elm 2.5.
 *
 ******************************************************************************/


#define HOSTNAME "beer"
#define DEFAULT_DOMAIN ".UUCP"
#define system_hostdom_file   "/usr/local/lib/domain"

/*
 * This header file should be included first thing by all source
 * modules throughout the Elm package (src, lib, and utils).
 */

#define VERSION		"2.5"			/* Version number... */
#define VERS_DATE	"January 11, 2000"		/* for elm -v option */
#define WHAT_STRING	\
	"@(#) Version 2.5, USENET supported version PL3"

#include <sys/types.h>	/* for fundamental types */
#include <stdio.h>	/* Must get the _IOEOF flag for feof() on Convex */
#include <fcntl.h>
#include <errno.h>
#include <signal.h>
/*#include "config.h"*/
/*#include "sysdefs.h"*/	/* system/configurable defines */

/* if not debugging, disable the assert() tests */
#ifndef DEBUG
# define NDEBUG
#endif

#ifndef TRUE
# define TRUE		1
# define FALSE		0
#endif

#define KLICK		32	/* increment for alias and mssg lists	    */

#define TLEN		10	/* super short (tiny) strings		    */
#define WLEN		20	/* small words				    */
#define NLEN		48	/* name length for aliases		    */
#define STRING		128	/* reasonable string length for most..      */
#define SLEN		256	/* long for ensuring no overwrites...	    */
#define LONG_STRING	512	/* even longer string for group expansion   */
#define VERY_LONG_STRING 2560	/* huge string for group alias expansion    */
#define MAX_LINE_LEN	5120	/* even bigger string for "filter" prog..   */

/* FOO - I believe these might belong in sysdefs.h */

#define alias_file		".aliases"
#define group_file		".groups"
#define system_file		".systems"

#define default_folders		"Mail"
#define default_recvdmail	"=received"
#define default_sentmail	"=sent"
#define default_to_chars	" TC*"

#define streq(p, q)		(strcmp((p), (q)) == 0)

/* use these ONLY where "d" is a constant string value */
#define strbegConst(s, d)	(strncmp((s), (d), sizeof(d)-1) == 0)
#define stribegConst(s, d)	(strincmp((s), (d), sizeof(d)-1) == 0)

/*
 * The macros implement speeded up constant string comparisons.
 * They are useful alternatives when a string is subject to
 * multiple comparisons.  The comparison target (the "d" value)
 * *must* be a constant string, and the first character of this
 * string *must* be upper case (or non-alphabetic).
 *
 * To use them, "FAST_COMP_DECLARE" must appear in variable declarations
 * at the top of the procedure.  Then "fast_comp_load" must be invoked
 * to preload the first character of the string.
 */
#define FAST_COMP_DECLARE		int FAST_COMP_ch
#define fast_comp_load(c)		FAST_COMP_ch = toupper(c)
#define fast_strbegConst(s, d)		strbegConst(s, d)
#define fast_stribegConst(s, d)		(FAST_COMP_ch == (d)[0] \
	    && strincmp((s), (d), sizeof(d)-1) == 0)
#define fast_header_cmp(s, d, result)	(FAST_COMP_ch == (d)[0] \
	    && header_ncmp((s), (d), sizeof(d)-1, (result), sizeof(result)-1))



/*****************************************************************************
 *
 * System portability definitions, header inclusions, and brokeness unbotching.
 *
 ****************************************************************************/

#ifdef HAS_SETEGID
#define SETGID(s) setegid(s)
#else
#define SETGID(s) setgid(s)
#endif


#if defined(__STDC__) || defined(_AIX)
# define ANSI_C 1
#endif

#ifndef P_
# ifdef ANSI_C
#   define P_(ARGS) ARGS
# else
#   define P_(ARGS) ()
#   define const
# endif
#endif

#ifdef __alpha
# define int32 int
#else
# define int32 long
#endif

/* avoid conflict with typedef'd word */
#ifdef CRAY
# define word wrd
#endif

/*
 *  Nice work Convex people! Thanks a million!
 *  When STDC is used feof() is defined as a true library routine
 *  in the header files and moreover the library routine also leaks
 *  royally. (It returns always 1!!) Consequently this macro is
 *  unavoidable.)
 */
#ifdef	__convex__
# ifndef   feof
#   define feof(p) ((p)->_flag&_IOEOF)
# endif
#endif

/* 
 * Ultrix's fflush returns EOF and sets error flag if the stream is read-only.
 */
#if defined(ULTRIX_FFLUSH_BUG) && defined(ANSI_C)
# define fflush(fp) \
	    ((((fp)->_flag & (_IOREAD | _IORW)) == _IOREAD) ? 0 : fflush(fp))
#endif

#ifdef SHORTNAMES	/* map long names to shorter ones */
# include <shortname.h>
#endif

#ifdef ANSI_C
  typedef void * malloc_t;
#else
  typedef char * malloc_t;
#endif

#ifdef I_STDLIB
# include <stdlib.h>
#else
  extern malloc_t	malloc(), realloc(), calloc();
  extern void		free(), exit(), _exit();
  extern char		*getenv();
#endif

#ifdef ANSI_C
# include <string.h>
#else
# if defined(_CONVEX_SOURCE) && defined(index)
#   undef _CONVEX_SOURCE
#   include <string.h>     /* Now there is no proto for index. */
#   define _CONVEX_SOURCE
# else
#   ifdef STRINGS
#     include <strings.h>
#   endif
# endif
  extern char *index(), *rindex();
  extern char *strcpy(), *strcat(), *strncpy();
  /* following are provided by libutil.a for systems that lack them */
  extern char *strstr(), *strtok(), *strpbrk();
  extern int strspn(), strcspn();
#endif

#ifdef MEMCPY
# ifndef ANSI_C
#   if defined(I_MEMORY)
#     include <memory.h>
#   else
#     if defined(__convexc__)
        extern void *memcpy(), *memset();
#     else
        extern char *memcpy(), *memset();
#     endif
      extern int memcmp();
#   endif
# endif
# define bcopy(src, dest, len)	memcpy((dest), (src), (len))
# define bcmp(s1, s2, len)	memcmp((s1), (s2), (len))
# define bzero(s, len)		memset((s), 0, (len))
#endif

/*
 * Some of the old BSD ctype conversion macros corrupted characters.
 * We will substitute our own versions if required.
 */
#include <ctype.h>
#ifdef BROKE_CTYPE
# undef  toupper
# define toupper(c)	(islower(c) ? ((c) - 'a' + 'A') : (c))
# undef  tolower
# define tolower(c)	(isupper(c) ? ((c) - 'A' + 'a') : (c))
#endif

#if defined(ANSI_C)
# include <unistd.h>
#else
  char *getlogin();
  long lseek();
  unsigned sleep();
#endif

/* things normally found in <unistd.h> */
#ifndef F_OK
# define F_OK	0
# define X_OK	1
# define W_OK	2
# define R_OK	4
#endif
#ifndef SEEK_SET
# define SEEK_SET	0
# define SEEK_CUR	1
# define SEEK_END	2
#endif
#ifndef STDIN_FILENO
# define STDIN_FILENO	0
# define STDOUT_FILENO	1
# define STDERR_FILENO	2
#endif

/* Elm likes to use these happy names instead */
#define ACCESS_EXISTS	F_OK
#define EXECUTE_ACCESS	X_OK
#define WRITE_ACCESS	W_OK
#define READ_ACCESS	R_OK
#define EDIT_ACCESS	(R_OK|W_OK)

/* <ulimit.h> is XPG3 ... but not POSIX nor ANSI */
extern long ulimit P_((int, ...));

#ifdef POSIX_SIGNALS
# define signal posix_signal
  extern SIGHAND_TYPE
	      (*posix_signal P_((int, SIGHAND_TYPE (*)(int)))) P_((int));
#else
# ifdef SIGSET
#   define signal sigset
#   ifdef _AIX
      extern SIGHAND_TYPE (*sigset(int sig, SIGHAND_TYPE (*func)(int)))(int);
#   endif
# endif
#endif

#if defined(POSIX_SIGNALS) && !defined(__386BSD__)
# define JMP_BUF		sigjmp_buf
# define SETJMP(env)		sigsetjmp((env), 1)
# define LONGJMP(env,val)	siglongjmp((env), (val))
#else
# define JMP_BUF		jmp_buf
# define SETJMP(env)		setjmp(env)
# define LONGJMP(env,val)	longjmp((env), (val))
#endif

#ifdef I_LOCALE
# include <locale.h>
#endif
//#ifdef I_NL_TYPES
//# include <nl_types.h>
//#else
//# include "nl_types.h"
//#endif
#ifndef	USENLS
# define MCprintf printf
# define MCfprintf fprintf
# define MCsprintf sprintf
#else
# include "mcprt.h"
#endif

/* FOO - I wonder if we should be including <time.h> in this header */
char *ctime P_((const time_t *));


/*****************************************************************************
 *
 * data structures
 *
 ****************************************************************************/


/* defines (struct addrs) */
#include "parseaddrs.h"


/** "status" values for the header and alias record **/

#define ACTION		(1<<0)
#define CONFIDENTIAL	(1<<1)
//#define DELETED		(1<<2)
#define EXPIRED		(1<<3)
#define FORM_LETTER	(1<<4)
#define NEW		(1<<5)
#define PRIVATE		(1<<6)
#define TAGGED		(1<<7)
#define URGENT		(1<<8)
#define VISIBLE		(1<<9)
#define UNREAD		(1<<10)
#define REPLIED_TO	(1<<11)
#define MIME_MESSAGE	(1<<12)	/* indicates existence of MIME Header */
#define MIME_NEEDDECOD	(1<<13)	/* indicates that we need to call mmdecode */
#define MIME_NOTPLAIN	(1<<14)	/* indicates that we have a content-type,
				   for which we need metamail anyway. */

/** "exit_disposition" values */

#define UNSET		0
#define KEEP		1
//#define STORE		2
#define DELETE		3

struct header_rec {
	int  lines;		/** # of lines in the message	**/
	int  status;		/** Urgent, Deleted, Expired?	**/
	int  org_status;	/** to restore if requested     **/
	int  index_number;	/** relative loc in file...	**/
	int  encrypted;		/** whether msg has encryption	**/
	int  exit_disposition;	/** whether to keep, store, delete **/
	int  status_chgd;	/** whether became read or old, etc. **/
	long content_length;	/** content_length in bytes from message header	**/
	long offset;		/** offset in bytes of message	**/
	time_t received_time;	/** when elm received here	**/
	char from[STRING];	/** who sent the message?	**/
	char to[STRING];	/** who it was sent to		**/
	char messageid[STRING];	/** the Message-ID: value	**/
	char time_zone[12];	/**                incl. tz	**/
	time_t time_sent;	/** gmt when sent for sorting	**/
	char time_menu[TLEN];	/** just the month..day for menu **/
	time_t tz_offset;	/** offset to gmt of time sent	**/
	char subject[STRING];   /** The subject of the mail	**/
	char mailx_status[WLEN];/** mailx status flags (RO...)	**/
	char allfrom[STRING];	/** The whole, unparsed From: field **/
	char allto[VERY_LONG_STRING];/** all to/cc fields, not just first **/
	long cc_index;		/** index in allto of cc fields **/
	struct addrs ml_to;	/** mlist parsed 'to' fields    **/
	long ml_cc_index;	/** index in ml_to of cc fields **/
       };

/** some defines for the "type" field of the alias record **/

#define SYSTEM		(1<<0)
#define USER		(1<<1)
#define PERSON		(1<<2)
#define GROUP		(1<<3)
#define DUPLICATE	(1<<4)		/* system aliases only */

/** some defines to aid in the limiting of alias displays **/
#define BY_NAME		(1<<6)
#define BY_ALIAS	(1<<7)


struct alias_disk_rec {
	int32 status;			/* DELETED, TAGGED, VISIBLE, ...     */
	int32 alias;			/* alias name                        */
	int32 last_name;		/* actual personal (last) name       */
	int32 name;			/* actual personal name (first last) */
	int32 comment;			/* comment, doesn't show in headers  */
	int32 address;			/* non expanded address              */
	int32 type;			/* mask-- sys/user, person/group     */
	int32 length;			/* length of alias data on file      */
       };

struct alias_rec {
	int   status;			/* DELETED, TAGGED, VISIBLE, ...     */
	char  *alias;			/* alias name                        */
	char  *last_name;		/* actual personal (last) name       */
	char  *name;			/* actual personal name (first last) */
	char  *comment;			/* comment, doesn't show in headers  */
	char  *address;			/* non expanded address              */
	int   type;			/* mask-- sys/user, person/group     */
	long  length;			/* length of alias data on file      */
       };

struct addr_rec {
	 char   address[NLEN];	/* machine!user you get mail as      */
	 struct addr_rec *next;	/* linked list pointer to next       */
	};


/*****************************************************************************
 *
 * Data common to many programs in the Elm package.
 *
 ****************************************************************************/


/*  #ifdef INTERN */
/*  # define EXTERN */
/*  # define INIT(X) =X */
/*  #else */
/*  # define EXTERN extern */
/*  # define INIT(X) */
/*  #endif */

/*  #ifdef INTERN */
/*  static char ident[] = WHAT_STRING; */
/*  static char copyright[] = "\ */
/*  @(#)          (C) Copyright 1986,1987, Dave Taylor\n\ */
/*  @(#)          (C) Copyright 1988-1995, The Usenet Community Trust\n"; */
/*  #endif */

/*  #ifdef DEBUG */
/*  #   define dprint(LVL, PRINTF_ARGS) \ */
/*  	if (debug < (LVL)) ; else (fprintf PRINTF_ARGS, fflush(debugfile)) */
/*  #else */
/*  #   define dprint(n,x) */
/*  #endif */


/*
 * The following globals are commonly used across all the programs in
 * the Elm suite (either directly or through the library).
 *
 * The initialize_common() routine should be called *first thing*
 * to set these values up.
 *
 * WARNING - Some of these items are overridden by the elmrc file, so
 * Elm and the utilities may have different notions as to their proper
 * values.  Yes, I do think this is a bug.
 */

#if 0
 int debug;			        /* debugging verbosity (0=off)	*/
 FILE *debugfile;   	                /* file for debut output	*/
 char *user_name;		 	/* user name, from passwd	*/
 char *user_home;			/* home directory, from passwd	*/
 char user_fullname[SLEN];	        /* full username, from passwd	*/
 char host_name[SLEN];		        /* uucp name of local machine	*/
 char host_domain[SLEN];		/* local domain with leading dot*/
 char host_fullname[SLEN];	        /* local FQDN to use for mail	*/
 char *incoming_folder;		        /* default folder ($MAIL)	*/
 nl_catd elm_msg_cat;		        /* message catalog		*/
 struct addr_rec *alternative_addresses;/* other addrs where we get mail*/
#endif

/*****************************************************************************
 *
 * declarations for routines in lib/libutil.a
 *
 ****************************************************************************/

#include "elm_lib.h"

#endif // _Pantomime_H_elm_defs
