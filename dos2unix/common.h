/*
 *   Copyright (C) 2009-2016 Erwin Waterlander
 *   All rights reserved.
 *
 *   Redistribution and use in source and binary forms, with or without
 *   modification, are permitted provided that the following conditions
 *   are met:
 *   1. Redistributions of source code must retain the above copyright
 *      notice, this list of conditions and the following disclaimer.
 *   2. Redistributions in binary form must reproduce the above copyright
 *      notice in the documentation and/or other materials provided with
 *      the distribution.
 *
 *   THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
 *   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *   PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE
 *   FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 *   OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 *   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 *   OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 *   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 */

#ifndef __D2U_COMMON_H
#define __D2U_COMMON_H

/* define feature test macros for realpath() -- needed on    */
/* systems that have S_ISLNK, but chicken/egg means we must  */
/* define early, before including stdlib.h (or sys/stat.h)   */
/*   Defining _XOPEN_SOURCE results in undefined lstat() on FreeBSD 10.1. EW 2015-05-03 */
/* #define _XOPEN_SOURCE 500 */

/* similarly, instead of realpath we like to use, if         */
/* available, the canonicalize_file_name() function, which   */
/* is a GNU extension. We only ACTUALLY use the function if  */
/* USE_CANONICALIZE_FILE_NAME is defined, but we don't define*/
/* that until later. So...define the feature test macro now. */
#define _GNU_SOURCE

#ifdef ENABLE_NLS

#include <libintl.h>
#define _(String) gettext (String)
#define gettext_noop(String) String
#define N_(String) gettext_noop (String)

#else

#define _(String) (String)
#define N_(String) String
#define textdomain(Domain)
#define bindtextdomain(Package, Directory)

#endif

#if defined(__DJGPP__) || defined(__TURBOC__) /* DJGPP */
#  include <dir.h>
#else
#  if !defined(__MSYS__) && !defined(_MSC_VER)
#    include <libgen.h>
#  endif
#endif
#if !defined(__TURBOC__) && !defined(_MSC_VER)
#include <unistd.h>
#endif
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#ifdef __GNUC__
#ifndef strcmpi
#  include <strings.h>
#  define strcmpi(s1, s2) strcasecmp(s1, s2)
#endif
#endif
#ifdef _MSC_VER
#  include <sys/utime.h>
#else
#  include <utime.h>
#endif
#include <limits.h>
#ifdef __TURBOC__
#define __FLAT__
#endif
#include <sys/stat.h>
#include <errno.h>
#if defined(D2U_UNICODE) || defined(_WIN32)
#include <wchar.h>
#endif

#if (defined(__WATCOMC__) && defined(__NT__))  /* Watcom */
#  define _WIN32 1
#endif

#if defined(__WATCOMC__) && defined(__I86__) /* Watcom C, 16 bit Intel */
#define __MSDOS__ 1
#endif

#if defined(__WATCOMC__) && defined(__DOS__) /* Watcom C, 32 bit DOS */
#define __MSDOS__ 1
#endif

#if defined(ENABLE_NLS) || (defined(D2U_UNICODE) && !defined(__MSDOS__) && !defined(_WIN32) && !defined(__OS2__))
/* setlocale() is also needed for nl_langinfo() */
#include <locale.h>
#endif

/* Watcom C has mkstemp, but no mktemp().
 * MinGW has mktemp() and mkstemp(). MinGW mkstemp() is not working for me.
 * MSVC has mktemp(), but no mkstemp().
 * Assume that none of the Windows compilers have mkstemp().
 * On Windows I need something that can also work with Unicode file names (UTF-16).
 * On Windows GetTempFileName() will be used, as is adviced on MSDN. */
#if  defined(__TURBOC__) || defined(__DJGPP__) || (defined(_WIN32) && !defined(__CYGWIN__))
/* Some compilers have no mkstemp().
 * Use mktemp() instead.
 * BORLANDC, DJGPP, MINGW32, MSVC */
#define NO_MKSTEMP 1
#endif

#if  defined(__TURBOC__) || defined(__DJGPP__) || defined(__MINGW32__) || defined(__WATCOMC__) || defined(_MSC_VER)
/* Some compilers have no chown(). */
#define NO_CHOWN 1
#endif

/* Watcom C defines S_ISLNK */
#ifdef __WATCOMC__
#undef S_ISLNK
#endif

/* Microsoft Visual C++ */
#ifdef _MSC_VER
#define S_ISCHR( m )    (((m) & _S_IFMT) == _S_IFCHR)
#define S_ISDIR( m )    (((m) & _S_IFMT) == _S_IFDIR)
#define S_ISFIFO( m )   (((m) & _S_IFMT) == _S_IFIFO)
#define S_ISREG( m )    (((m) & _S_IFMT) == _S_IFREG)
#define NO_CHMOD 1  /* no chmod() available */
#endif

#if defined(__MSDOS__) || defined(_WIN32) || defined(__OS2__)
/* Systems without soft links use 'stat' instead of 'lstat'. */
#define STAT stat
#else
#define STAT lstat
#endif

#if defined(__MSDOS__) || defined(_WIN32) || defined(__OS2__)
/* On some systems rename() will always fail if target file already exists. */
#define NEED_REMOVE 1
#endif

#if defined(__MSDOS__) || defined(_WIN32) || defined(__CYGWIN__) || defined(__OS2__) /* DJGPP, MINGW32 and OS/2 */
/* required for setmode() and O_BINARY */
#include <fcntl.h>
#include <io.h>
#endif

#if defined(__MSDOS__) || defined(_WIN32) || defined(__CYGWIN__) || defined(__OS2__)
  #define R_CNTRL   "rb"
  #define W_CNTRL   "wb"
#else
  #define R_CNTRL   "r"
  #define W_CNTRL   "w"
#endif
#define R_CNTRLW   L"rb"
#define W_CNTRLW   L"wb"

#define BINARY_FILE 0x1
#define NO_REGFILE  0x2
#define WRONG_CODEPAGE  0x4
#define OUTPUTFILE_SYMLINK 0x8
#define INPUT_TARGET_NO_REGFILE 0x10
#define OUTPUT_TARGET_NO_REGFILE 0x20
#define LOCALE_NOT_UTF 0x40     /* Locale not an Unicode Transformation Format */
#define WCHAR_T_TOO_SMALL 0x80
#define UNICODE_CONVERSION_ERROR 0x100
#define UNICODE_NOT_SUPPORTED 0x200

#define CONVMODE_ASCII   0
#define CONVMODE_UTF16LE 1
#define CONVMODE_UTF16BE 2
#define CONVMODE_7BIT    3
#define CONVMODE_437     437
#define CONVMODE_850     850
#define CONVMODE_860     860
#define CONVMODE_863     863
#define CONVMODE_865     865
#define CONVMODE_1252    1252

#define FROMTO_DOS2UNIX 0
#define FROMTO_MAC2UNIX 1
#define FROMTO_UNIX2DOS 2
#define FROMTO_UNIX2MAC 3

#define INFO_DOS  0x1
#define INFO_UNIX 0x2
#define INFO_MAC  0x4
#define INFO_BOM  0x8
#define INFO_TEXT 0x10
#define INFO_DEFAULT 0x1F
#define INFO_CONVERT 0x20
#define INFO_HEADER  0x40
#define INFO_NOPATH  0x80
#define INFO_PRINT0  0x100

#define SYMLINK_SKIP 0
#define SYMLINK_FOLLOW 1
#define SYMLINK_REPLACE 2

#define FILE_MBS     0  /* Multi-byte string or 8-bit char */
#define FILE_UTF16LE 1  /* UTF-16 Little Endian */
#define FILE_UTF16BE 2  /* UTF-16 Big Endian */
#define FILE_UTF8    3  /* UTF-8 */
#define FILE_GB18030 4  /* GB18030 */

#define D2U_DISPLAY_ANSI       0
#define D2U_DISPLAY_UNICODE    1
#define D2U_DISPLAY_UNICODEBOM 2
#define D2U_DISPLAY_UTF8       3
#define D2U_DISPLAY_UTF8BOM    4

/* locale conversion targets */
#define TARGET_UTF8    0
#define TARGET_GB18030 1
#define D2U_MAX_PATH 2048

typedef struct
{
  int NewFile;                          /* is in new file mode? */
  int verbose;                          /* 0 = quiet, 1 = normal, 2 = verbose */
  int KeepDate;                         /* should keep date stamp? */
  int ConvMode;                         /* 0: ascii, 1: 7bit, 2: iso */
  int FromToMode;                       /* 0: dos2unix/unix2dos, 1: mac2unix/unix2mac */
  int NewLine;                          /* if TRUE, then additional newline */
  int Force;                            /* if TRUE, force conversion of all files. */
  int AllowChown;                       /* if TRUE, allow file ownership change in old file mode. */
  int Follow;                           /* 0: skip symlink, 1: follow symbolic link, 2: replace symlink. */
  int status;
  int stdio_mode;                       /* if TRUE, stdio mode */
  int to_stdout;                        /* write output to stdout in old file mode */
  int error;                            /* an error occurred */
  int bomtype;                          /* byte order mark */
  int add_bom;                          /* 1: write BOM */
  int keep_bom;                         /* 1: write BOM if input file has BOM. 0: Do not write BOM */
  int keep_utf16;                       /* 1: write UTF-16 format when input file is UTF-16 format */
  int file_info;                        /* 1: print file information */
  int locale_target;                    /* locale conversion target. 0: UTF-8; 1: GB18030 */
  unsigned int line_nr;                 /* line number where UTF-16 error occurs */
  int add_eol;                          /* Add End Of Line to last line */
} CFlag;


int symbolic_link(const char *path);
int regfile(char *path, int allowSymlinks, CFlag *ipFlag, const char *progname);
int regfile_target(char *path, CFlag *ipFlag, const char *progname);
void PrintUsage(const char *progname);
void PrintBSDLicense(void);
void PrintVersion(const char *progname, const char *localedir);
#ifdef ENABLE_NLS
void PrintLocaledir(const char *localedir);
#endif
FILE* OpenInFile(char *ipFN);
FILE* OpenOutFile(char *opFN);
FILE* OpenOutFiled(int fd);
#if defined(__TURBOC__) || defined(__MSYS__)
char *dirname(char *path);
#endif
FILE* MakeTempFileFrom(const char *OutFN, char **fname_ret);
int ResolveSymbolicLink(char *lFN, char **rFN, CFlag *ipFlag, const char *progname);
FILE *read_bom (FILE *f, int *bomtype);
FILE *write_bom (FILE *f, CFlag *ipFlag, const char *progname);
void print_bom (const int bomtype, const char *filename, const char *progname);
int check_unicode(FILE *InF, FILE *TempF,  CFlag *ipFlag, const char *ipInFN, const char *progname);
void print_messages_stdio(const CFlag *pFlag, const char *progname);
void print_messages_newfile(const CFlag *pFlag, const char *infile, const char *outfile, const char *progname, const int RetVal);
void print_messages_oldfile(const CFlag *pFlag, const char *infile, const char *progname, const int RetVal);
int ConvertNewFile(char *ipInFN, char *ipOutFN, CFlag *ipFlag, const char *progname,
                   int (*Convert)(FILE*, FILE*, CFlag *, const char *)
#ifdef D2U_UNICODE
                 , int (*ConvertW)(FILE*, FILE*, CFlag *, const char *)
#endif
                  );
int ConvertStdio(CFlag *ipFlag, const char *progname,
                   int (*Convert)(FILE*, FILE*, CFlag *, const char *)
#ifdef D2U_UNICODE
                 , int (*ConvertW)(FILE*, FILE*, CFlag *, const char *)
#endif
                  );
int parse_options(int argc, char *argv[],
                  CFlag *pFlag, const char *localedir, const char *progname,
                  void (*PrintLicense)(void),
                  int (*Convert)(FILE*, FILE*, CFlag *, const char *)
#ifdef D2U_UNICODE
                , int (*ConvertW)(FILE*, FILE*, CFlag *, const char *)
#endif
                  );
void d2u_getc_error(CFlag *ipFlag, const char *progname);
void d2u_putc_error(CFlag *ipFlag, const char *progname);
#ifdef D2U_UNICODE
void d2u_putwc_error(CFlag *ipFlag, const char *progname);
wint_t d2u_getwc(FILE *f, int bomtype);
wint_t d2u_ungetwc(wint_t wc, FILE *f, int bomtype);
wint_t d2u_putwc(wint_t wc, FILE *f, CFlag *ipFlag, const char *progname);
#endif
char *d2u_strncpy(char *dest, const char *src, size_t dest_size);

#ifdef D2U_UNIFILE
#define UNICODE
#define _UNICODE
#define D2U_UTF8_FPRINTF d2u_utf8_fprintf
#define D2U_ANSI_FPRINTF d2u_ansi_fprintf
void d2u_utf8_fprintf( FILE *stream, const char* format, ... );
void d2u_ansi_fprintf( FILE *stream, const char* format, ... );
int glob_warg(int argc, wchar_t *wargv[], char ***argv, CFlag *ipFlag, const char *progname);
#else
#define D2U_UTF8_FPRINTF fprintf
#define D2U_ANSI_FPRINTF fprintf
#endif

#endif
