#ifndef _Pantomime_H_elm_lib
#define _Pantomime_H_elm_lib
/*
 * Declaration of routines in the Elm library.
 * This header normally included through "elm_defs.h".
 */

/* add_site.c */

void add_site P_((char *, const char *, char *));


/* addrmchusr.c */

int addr_matches_user P_((char *, const char *));


/* aliasdb.c */

#ifdef ANSI_C
struct dbz;
#endif
int read_one_alias P_((struct dbz *, struct alias_disk_rec *));
struct alias_rec *fetch_alias P_((struct dbz *, char *));
char *next_addr_in_list P_((char **));


/* atonum.c */

int atonum P_((const char *));


/* basename.c */

char *basename P_((const char *));


/* can_access.c */

int can_access P_((const char *, int));


/* can_open.c */

int can_open P_((const char *, const char *));


/* chloc.c */

int chloc P_((const char *, int));
int qchloc P_((const char *, int));


/* date_util.c */

int cvt_dayname_to_daynum P_((const char *, int *));
int cvt_monthname_to_monthnum P_((const char *, int *));
int cvt_yearstr_to_yearnum P_((const char *, int *));
int cvt_mmddyy_to_dayofyear P_((int, int, int, int *));
int cvt_timezone_to_offset P_((char *, int *));
int cvt_numtz_to_mins P_((const char *));
int cvt_timestr_to_hhmmss P_((const char *, int *, int *, int *));
long make_gmttime P_((int, int, int, int, int, int));


/* elm_access.c */

int elm_access P_((const char *, int));


/* errno.c */

extern int errno;
#ifndef STRERROR
char *strerror P_((int));
#endif


/* expand.c */

int expand P_((char *));
char *expand_define P_((const char *));


/* fast_getpw.c */

#ifdef ANSI_C
struct passwd;
#endif
struct passwd *fast_getpwuid P_((int));


/* figadrssee.c */

void figure_out_addressee P_((const char *, const char *, char *));


/* gcos_name.c */

char *gcos_name P_((char *, const char *));


/* get_tz.c */

#ifdef ANSI_C
struct tm;
#endif
int get_tz_mins P_((void));
char *get_tz_name P_((struct tm *));


/* getarpdate.c */

char *get_arpa_date P_((void));


/* getfullnam.c */

char *get_full_name P_((const char *));


/* gethostname.c */

void get_hostname P_((char *, int));
void get_hostdomain P_((char *, int));


/* getword.c */

int get_word P_((const char *, int, char *, int));


/* header_cmp.c */

char *header_cmp P_((const char *, const char *, const char *));
int header_ncmp P_((const char *, const char *, int, const char *, int));


/* in_list.c */

int in_list P_((char *, char *));


/* initcommon.c */

void initialize_common P_((void));


/* ldstate.c */

/* environment parameter that points to folder state file */
#define FOLDER_STATE_ENV	"ELMSTATE"

struct folder_state {
    char *folder_name;	/* full pathname to current folder	*/
    int num_mssgs;	/* number of messages in the folder	*/
    long *idx_list;	/* index of seek offsets for messages	*/
    long *clen_list;	/* list of content lengths for mssgs	*/
    int num_sel;	/* number of messages selected		*/
    int *sel_list;	/* list of selected message numbers	*/

};

int load_folder_state_file P_((struct folder_state *));


/* len_next.c */

int len_next_part P_((const char *));


/* mail_gets.c */

int mail_gets P_((char *, int, FILE *));


/* mailfile.c */

	/* ##### defined in mailfile.h  ##### */


/* mcprt.c */

	/* ##### defined in mcprt.h ##### */


/* mcprtlib.c */

	/* ##### defined in mcprtlib.c ###### */


/* mk_aliases.c */

int check_alias P_((char *));
void despace_address P_((char *));
int do_newalias P_((char *, char *, int, int));


/* mk_lockname.c */

char *mk_lockname P_((const char *));


/* mlist.c */

	/* ##### defined in parseaddrs.h ##### */


/* move_left.c */

void move_left P_((char *, int));


/* msgcat.c */

	/* ##### defined in msgcat.h ##### */


/* ndbz.c */

	/* ##### defined in ndbz.h ##### */



/* okay_addr.c */

int okay_address P_((char *, char *));


/* opt_utils.c */

#ifndef HAS_CUSERID
char *cuserid P_((char *));
#endif
    /* strtok() declared in elm_defs.h */
    /* strpbrk() declared in elm_defs.h */
    /* strspn() declared in elm_defs.h */
    /* strcspn() declared in elm_defs.h */
#ifndef TEMPNAM
/*char *tempnam P_((char *, char *));*/
#endif
#ifndef GETOPT
/*int getopt P_((int, char **, char *));*/
#endif
#ifndef RENAME
/*int rename P_((char *, char *));*/
#endif
#ifndef MKDIR
/*int mkdir P_((const char *, int));*/
#endif


/* parsarpdat.c */

int parse_arpa_date P_((const char *, struct header_rec *));


/* parsarpmbox.c */

int parse_arpa_mailbox P_((const char *, char *, int, char *, int, char **));


/* parsarpwho.c */

int parse_arpa_who P_((const char *, char *));


/* patmatch.c */

#define PM_NOCASE	(1<<0)		/* letter case insignificant	*/
#define PM_WSFOLD	(1<<1)		/* fold white space		*/
#define PM_FANCHOR	(1<<2)		/* anchor pat at front (like ^)	*/
#define PM_BANCHOR	(1<<3)		/* anchor pat at back (like $)	*/

int patmatch P_((const char *, const char *, int));


/* posixsig.c */

#ifdef POSIX_SIGNALS
SIGHAND_TYPE (*posix_signal P_((int, SIGHAND_TYPE (*)(int)))) P_((int));
#endif


/* putenv.c */
/*  #ifndef PUTENV */
/*  int putenv P_((const char *)); */
/*  #endif */


/* qstrings.c */

char *qstrpbrk P_((const char *, const char *));
int qstrspn P_((const char *, const char *));
int qstrcspn P_((const char *, const char *));


/* realfrom.c */

int real_from P_((const char *, struct header_rec *));


/* remfirstwd.c */

void remove_first_word P_((char *));
void remove_header_keyword P_((char *));


/* reverse.c */

void reverse P_((char *));


/* rfc822tlen.c */

int rfc822_toklen P_((const char *));


/* safemalloc.c */

/*
 * The "safe_malloc_fail_handler" vector points to a routine that is
 * invoked if one of the safe_malloc() routines fails.  At startup, this
 * will point to the default handler that prints a diagnostic message
 * and aborts.  The vector may be changed to install a different error
 * handler.
 */
extern void (*safe_malloc_fail_handler) P_((const char *, unsigned));

void dflt_safe_malloc_fail_handler P_((const char *, unsigned));
malloc_t safe_malloc P_((unsigned));
malloc_t safe_realloc P_((malloc_t, unsigned));
char *safe_strdup P_((const char *));


/* shiftlower.c */

char *shift_lower P_((char *));


/* strfcpy.c */

char *strfcpy P_((char *, const char *, int));
void  strfcat P_((char *, const char *, int));


/* strftime.c */

#ifndef STRFTIME
#ifdef ANSI_C
struct tm;
#endif
size_t strftime P_((char *, size_t, const char *, const struct tm *));
#endif


/* strincmp.c */

int strincmp P_((const char *, const char *, int));
int istrcmp P_((const char *, const char *));


/* striparens.c */

char *strip_parens P_((const char *));
char *get_parens P_((const char *));


/* strstr.c */

    /* strstr() declared in elm_defs.h */


/* strtokq.c */

char *strtokq P_((char *, const char *, int));


/* tail_of.c */

int tail_of P_((char *, char *, char *));


/* trim.c */

char *trim_quotes P_((char *));
char *trim_trailing_slashes P_((char *));
char *trim_trailing_spaces P_((char *));


/* validname.c */

int valid_name P_((const char *));

#endif // _Pantomime_H_elm_lib
