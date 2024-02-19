/*
 *  Name: dos2unix
 *  Documentation:
 *    Remove cr ('\x0d') characters from a file.
 *
 *  The dos2unix package is distributed under FreeBSD style license.
 *  See also https://www.freebsd.org/copyright/freebsd-license.html
 *  --------
 *
 *  Copyright (C) 2009-2024 Erwin Waterlander
 *  Copyright (C) 1998 Christian Wurll
 *  Copyright (C) 1998 Bernd Johannes Wuebben
 *  Copyright (C) 1994-1995 Benjamin Lin.
 *  All rights reserved.
 *
 *  Redistribution and use in source and binary forms, with or without
 *  modification, are permitted provided that the following conditions
 *  are met:
 *  1. Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *  2. Redistributions in binary form must reproduce the above copyright
 *     notice in the documentation and/or other materials provided with
 *     the distribution.
 *
 *  THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
 *  EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
 *  IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
 *  PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE
 *  FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
 *  CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
 *  OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
 *  BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 *  WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
 *  OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
 *  IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *
 *  == 1.0 == 1989.10.04 == John Birchfield (jb@koko.csustan.edu)
 *  == 1.1 == 1994.12.20 == Benjamin Lin (blin@socs.uts.edu.au)
 *     Cleaned up for Borland C/C++ 4.02
 *  == 1.2 == 1995.03.16 == Benjamin Lin (blin@socs.uts.edu.au)
 *     Modified to more conform to UNIX style.
 *  == 2.0 == 1995.03.19 == Benjamin Lin (blin@socs.uts.edu.au)
 *     Rewritten from scratch.
 *  == 2.1 == 1995.03.29 == Benjamin Lin (blin@socs.uts.edu.au)
 *     Conversion to SunOS charset implemented.
 *  == 2.2 == 1995.03.30 == Benjamin Lin (blin@socs.uts.edu.au)
 *     Fixed a bug in 2.1 where in new-file mode, if outfile already exists
 *     conversion can not be completed properly.
 *
 * Added Mac text file translation, i.e. \r to \n conversion
 * Bernd Johannes Wuebben, wuebben@kde.org
 * Wed Feb  4 19:12:58 EST 1998
 *
 * Added extra newline if ^M occurs
 * Christian Wurll, wurll@ira.uka.de
 * Thu Nov 19 1998
 *
 *  See ChangeLog.txt for complete version history.
 *
 */


/* #define DEBUG 1 */
#define __DOS2UNIX_C

#include "common.h"
#include "dos2unix.h"
# if (defined(_WIN32) && !defined(__CYGWIN__))
#include <windows.h>
#endif
#ifdef D2U_UNICODE
#if !defined(__MSDOS__) && !defined(_WIN32) && !defined(__OS2__)  /* Unix, Cygwin */
# include <langinfo.h>
#endif
#endif

void PrintLicense(void)
{
  D2U_ANSI_FPRINTF(stdout,_("\
Copyright (C) 2009-%d Erwin Waterlander\n\
Copyright (C) 1998      Christian Wurll (Version 3.1)\n\
Copyright (C) 1998      Bernd Johannes Wuebben (Version 3.0)\n\
Copyright (C) 1994-1995 Benjamin Lin\n\
All rights reserved.\n\n"),2024);
  PrintBSDLicense();
}

#ifdef D2U_UNICODE
wint_t StripDelimiterW(FILE* ipInF, FILE* ipOutF, CFlag *ipFlag, wint_t CurChar, unsigned int *converted, const char *progname)
{
  wint_t TempNextChar;
  /* CurChar is always CR (x0d) */
  /* In normal dos2unix mode put nothing (skip CR). */
  /* Don't modify Mac files when in dos2unix mode. */
  if ( (TempNextChar = d2u_getwc(ipInF, ipFlag->bomtype)) != WEOF) {
    if (d2u_ungetwc( TempNextChar, ipInF, ipFlag->bomtype) == WEOF) {  /* put back peek char */
        d2u_getc_error(ipFlag,progname);
        return WEOF;
    }
    if ( TempNextChar != 0x0a ) {
      if (d2u_putwc(CurChar, ipOutF, ipFlag, progname) == WEOF) {  /* Mac line, put CR */
          d2u_putwc_error(ipFlag,progname);
          return WEOF;
      }
    } else {
      (*converted)++;
      if (ipFlag->NewLine) {  /* add additional LF? */
        if (d2u_putwc(0x0a, ipOutF, ipFlag, progname) == WEOF) {
            d2u_putwc_error(ipFlag,progname);
            return WEOF;
        }
      }
    }
  } else {
    if (ferror(ipInF)) {
        d2u_getc_error(ipFlag,progname);
        return WEOF;
    }
    if ( CurChar == 0x0d ) {  /* EOF: last Mac line delimiter (CR)? */
        if (d2u_putwc(CurChar, ipOutF, ipFlag, progname) == WEOF) {
            d2u_putwc_error(ipFlag,progname);
            return WEOF;
        }
    }
  }
  return CurChar;
}
#endif

/* CUR        NEXT
   0xd(CR)    0xa(LF)  => put LF if option -l was used
   0xd(CR)  ! 0xa(LF)  => put CR
   0xd(CR)    EOF      => put CR
 */
int StripDelimiter(FILE* ipInF, FILE* ipOutF, CFlag *ipFlag, int CurChar, unsigned int *converted, const char *progname)
{
  int TempNextChar;
  /* CurChar is always CR (x0d) */
  /* In normal dos2unix mode put nothing (skip CR). */
  /* Don't modify Mac files when in dos2unix mode. */
  if ( (TempNextChar = fgetc(ipInF)) != EOF) {
    if (ungetc( TempNextChar, ipInF ) == EOF) { /* put back peek char */
        d2u_getc_error(ipFlag,progname);
        return EOF;
    }
    if ( TempNextChar != '\x0a' ) {
      if (fputc( CurChar, ipOutF ) == EOF) { /* Mac line, put CR */
          d2u_putc_error(ipFlag,progname);
          return EOF;
      }
    } else {
      (*converted)++;
      if (ipFlag->NewLine) {  /* add additional LF? */
        if (fputc('\x0a', ipOutF) == EOF) {
            d2u_putc_error(ipFlag,progname);
            return EOF;
        }
      }
    }
  } else {
    if (ferror(ipInF)) {
        d2u_getc_error(ipFlag,progname);
        return EOF;
    }
    if ( CurChar == '\x0d' ) {  /* EOF: last Mac line delimiter (CR)? */
        if (fputc( CurChar, ipOutF ) == EOF) {
            d2u_putc_error(ipFlag,progname);
            return EOF;
        }
    }
  }
  return CurChar;
}

/* converts stream ipInF to UNIX format text and write to stream ipOutF
 * RetVal: 0  if success
 *         -1  otherwise
 */
#ifdef D2U_UNICODE
int ConvertDosToUnixW(FILE* ipInF, FILE* ipOutF, CFlag *ipFlag, const char *progname)
{
    int RetVal = 0;
    wint_t PrevChar = WEOF;
    wint_t TempChar;
    wint_t TempNextChar;
    unsigned int line_nr = 1;
    unsigned int converted = 0;

    ipFlag->status = 0;

    /* CR-LF -> LF */
    /* LF    -> LF, in case the input file is a Unix text file */
    /* CR    -> CR, in dos2unix mode (don't modify Mac file) */
    /* CR    -> LF, in Mac mode */
    /* \x0a = Newline/Line Feed (LF) */
    /* \x0d = Carriage Return (CR) */

    switch (ipFlag->FromToMode)
    {
      case FROMTO_DOS2UNIX: /* dos2unix */
        while ((TempChar = d2u_getwc(ipInF, ipFlag->bomtype)) != WEOF) {  /* get character */
          if ((ipFlag->Force == 0) &&
              (TempChar < 32) &&
              (TempChar != 0x0a) &&  /* Not an LF */
              (TempChar != 0x0d) &&  /* Not a CR */
              (TempChar != 0x09) &&  /* Not a TAB */
              (TempChar != 0x0c)) {  /* Not a form feed */
            RetVal = -1;
            ipFlag->status |= BINARY_FILE ;
            if (ipFlag->verbose) {
              if ((ipFlag->stdio_mode) && (!ipFlag->error)) ipFlag->error = 1;
              D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
              D2U_UTF8_FPRINTF(stderr, _("Binary symbol 0x00%02X found at line %u\n"),TempChar, line_nr);
            }
            break;
          }
          if (TempChar != 0x0d) {
            if (TempChar == 0x0a) /* Count all DOS and Unix line breaks */
              ++line_nr;
            if (d2u_putwc(TempChar, ipOutF, ipFlag, progname) == WEOF) {
              RetVal = -1;
              d2u_putwc_error(ipFlag,progname);
              break;
            }
          } else {
            if (StripDelimiterW( ipInF, ipOutF, ipFlag, TempChar, &converted, progname) == WEOF) {
              RetVal = -1;
              break;
            }
          }
          PrevChar = TempChar;
        }
        if (TempChar == WEOF && ipFlag->add_eol && PrevChar != WEOF && PrevChar != 0x0a) {
          /* Add missing line break at the last line. */
            if (ipFlag->verbose > 1) {
              D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
              D2U_UTF8_FPRINTF(stderr, _("Added line break to last line.\n"));
            }
            if (d2u_putwc(0x0a, ipOutF, ipFlag, progname) == WEOF) {
              RetVal = -1;
              d2u_putwc_error(ipFlag,progname);
            }
        }
        if ((TempChar == WEOF) && ferror(ipInF)) {
          RetVal = -1;
          d2u_getc_error(ipFlag,progname);
        }
        break;
      case FROMTO_MAC2UNIX: /* mac2unix */
        while ((TempChar = d2u_getwc(ipInF, ipFlag->bomtype)) != WEOF) {
          if ((ipFlag->Force == 0) &&
              (TempChar < 32) &&
              (TempChar != 0x0a) &&  /* Not an LF */
              (TempChar != 0x0d) &&  /* Not a CR */
              (TempChar != 0x09) &&  /* Not a TAB */
              (TempChar != 0x0c)) {  /* Not a form feed */
            RetVal = -1;
            ipFlag->status |= BINARY_FILE ;
            if (ipFlag->verbose) {
              if ((ipFlag->stdio_mode) && (!ipFlag->error)) ipFlag->error = 1;
              D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
              D2U_UTF8_FPRINTF(stderr, _("Binary symbol 0x00%02X found at line %u\n"), TempChar, line_nr);
            }
            break;
          }
          if ((TempChar != 0x0d)) {
            if (TempChar == 0x0a) /* Count all DOS and Unix line breaks */
              ++line_nr;
            if(d2u_putwc(TempChar, ipOutF, ipFlag, progname) == WEOF) {
              RetVal = -1;
              d2u_putwc_error(ipFlag,progname);
              break;
            }
          } else{
            /* TempChar is a CR */
            if ( (TempNextChar = d2u_getwc(ipInF, ipFlag->bomtype)) != WEOF) {
              if (d2u_ungetwc( TempNextChar, ipInF, ipFlag->bomtype) == WEOF) {  /* put back peek char */
                d2u_getc_error(ipFlag,progname);
                RetVal = -1;
                break;
              }
              /* Don't touch this delimiter if it's a CR,LF pair. */
              if ( TempNextChar == 0x0a ) {
                if (d2u_putwc(0x0d, ipOutF, ipFlag, progname) == WEOF) { /* put CR, part of DOS CR-LF */
                  d2u_putwc_error(ipFlag,progname);
                  RetVal = -1;
                  break;
                }
                PrevChar = TempChar;
                continue;
              }
            }
            if (d2u_putwc(0x0a, ipOutF, ipFlag, progname) == WEOF) { /* MAC line end (CR). Put LF */
              RetVal = -1;
              d2u_putwc_error(ipFlag,progname);
              break;
            }
            converted++;
            line_nr++; /* Count all Mac line breaks */
            if (ipFlag->NewLine) {  /* add additional LF? */
              if (d2u_putwc(0x0a, ipOutF, ipFlag, progname) == WEOF) {
                RetVal = -1;
                d2u_putwc_error(ipFlag,progname);
                break;
              }
            }
          }
          PrevChar = TempChar;
        }
        if (TempChar == WEOF && ipFlag->add_eol && PrevChar != WEOF && !(PrevChar == 0x0a || PrevChar == 0x0d)) {
          /* Add missing line break at the last line. */
            if (ipFlag->verbose > 1) {
              D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
              D2U_UTF8_FPRINTF(stderr, _("Added line break to last line.\n"));
            }
            if (d2u_putwc(0x0a, ipOutF, ipFlag, progname) == WEOF) {
              RetVal = -1;
              d2u_putwc_error(ipFlag,progname);
            }
        }
        if ((TempChar == WEOF) && ferror(ipInF)) {
          RetVal = -1;
          d2u_getc_error(ipFlag,progname);
        }
        break;
      default: /* unknown FromToMode */
      ;
#if DEBUG
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_UTF8_FPRINTF(stderr, _("program error, invalid conversion mode %d\n"),ipFlag->FromToMode);
      exit(1);
#endif
    }
    if (ipFlag->status & UNICODE_CONVERSION_ERROR)
        ipFlag->line_nr = line_nr;
    if ((RetVal == 0) && (ipFlag->verbose > 1)) {
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_UTF8_FPRINTF(stderr, _("Converted %u out of %u line breaks.\n"), converted, line_nr -1);
    }
    return RetVal;
}
#endif

/* converts stream ipInF to UNIX format text and write to stream ipOutF
 * RetVal: 0  if success
 *         -1  otherwise
 */
int ConvertDosToUnix(FILE* ipInF, FILE* ipOutF, CFlag *ipFlag, const char *progname)
{
    int RetVal = 0;
    int PrevChar = EOF;
    int TempChar;
    int TempNextChar;
    int *ConvTable;
    unsigned int line_nr = 1;
    unsigned int converted = 0;

    ipFlag->status = 0;

    switch (ipFlag->ConvMode) {
      case CONVMODE_ASCII: /* ascii */
      case CONVMODE_UTF16LE: /* Assume UTF-16LE, bomtype = FILE_UTF8 or GB18030 */
      case CONVMODE_UTF16BE: /* Assume UTF-16BE, bomtype = FILE_UTF8 or GB18030 */
        ConvTable = D2UAsciiTable;
        break;
      case CONVMODE_7BIT: /* 7bit */
        ConvTable = D2U7BitTable;
        break;
      case CONVMODE_437: /* iso */
        ConvTable = D2UIso437Table;
        break;
      case CONVMODE_850: /* iso */
        ConvTable = D2UIso850Table;
        break;
      case CONVMODE_860: /* iso */
        ConvTable = D2UIso860Table;
        break;
      case CONVMODE_863: /* iso */
        ConvTable = D2UIso863Table;
        break;
      case CONVMODE_865: /* iso */
        ConvTable = D2UIso865Table;
        break;
      case CONVMODE_1252: /* iso */
        ConvTable = D2UIso1252Table;
        break;
      default: /* unknown convmode */
        ipFlag->status |= WRONG_CODEPAGE ;
        return(-1);
    }
    /* Turn off ISO and 7-bit conversion for Unicode text files */
    if (ipFlag->bomtype > 0)
      ConvTable = D2UAsciiTable;

    if ((ipFlag->ConvMode > CONVMODE_7BIT) && (ipFlag->verbose)) { /* not ascii or 7bit */
       D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
       D2U_UTF8_FPRINTF(stderr, _("using code page %d.\n"), ipFlag->ConvMode);
    }

    /* CR-LF -> LF */
    /* LF    -> LF, in case the input file is a Unix text file */
    /* CR    -> CR, in dos2unix mode (don't modify Mac file) */
    /* CR    -> LF, in Mac mode */
    /* \x0a = Newline/Line Feed (LF) */
    /* \x0d = Carriage Return (CR) */

    switch (ipFlag->FromToMode) {
      case FROMTO_DOS2UNIX: /* dos2unix */
        while ((TempChar = fgetc(ipInF)) != EOF) {  /* get character */
          if ((ipFlag->Force == 0) &&
              (TempChar < 32) &&
              (TempChar != '\x0a') &&  /* Not an LF */
              (TempChar != '\x0d') &&  /* Not a CR */
              (TempChar != '\x09') &&  /* Not a TAB */
              (TempChar != '\x0c')) {  /* Not a form feed */
            RetVal = -1;
            ipFlag->status |= BINARY_FILE ;
            if (ipFlag->verbose) {
              if ((ipFlag->stdio_mode) && (!ipFlag->error)) ipFlag->error = 1;
              D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
              D2U_UTF8_FPRINTF(stderr, _("Binary symbol 0x%02X found at line %u\n"),TempChar, line_nr);
            }
            break;
          }
          if (TempChar != '\x0d') {
            if (TempChar == '\x0a') /* Count all DOS and Unix line breaks */
              ++line_nr;
            if (fputc(ConvTable[TempChar], ipOutF) == EOF) {
              RetVal = -1;
              d2u_putc_error(ipFlag,progname);
              break;
            }
          } else {
            if (StripDelimiter( ipInF, ipOutF, ipFlag, TempChar, &converted, progname) == EOF) {
              RetVal = -1;
              break;
            }
          }
          PrevChar = TempChar;
        }
        if (TempChar == EOF && ipFlag->add_eol && PrevChar != EOF && PrevChar != '\x0a') {
          /* Add missing line break at the last line. */
            if (ipFlag->verbose > 1) {
              D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
              D2U_UTF8_FPRINTF(stderr, _("Added line break to last line.\n"));
            }
           if (fputc('\x0a', ipOutF) == EOF) {
              RetVal = -1;
              d2u_putc_error(ipFlag,progname);
            }
        }
        if ((TempChar == EOF) && ferror(ipInF)) {
          RetVal = -1;
          d2u_getc_error(ipFlag,progname);
        }
        break;
      case FROMTO_MAC2UNIX: /* mac2unix */
        while ((TempChar = fgetc(ipInF)) != EOF) {
          if ((ipFlag->Force == 0) &&
              (TempChar < 32) &&
              (TempChar != '\x0a') &&  /* Not an LF */
              (TempChar != '\x0d') &&  /* Not a CR */
              (TempChar != '\x09') &&  /* Not a TAB */
              (TempChar != '\x0c')) {  /* Not a form feed */
            RetVal = -1;
            ipFlag->status |= BINARY_FILE ;
            if (ipFlag->verbose) {
              if ((ipFlag->stdio_mode) && (!ipFlag->error)) ipFlag->error = 1;
              D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
              D2U_UTF8_FPRINTF(stderr, _("Binary symbol 0x%02X found at line %u\n"),TempChar, line_nr);
            }
            break;
          }
          if ((TempChar != '\x0d')) {
            if (TempChar == '\x0a') /* Count all DOS and Unix line breaks */
              ++line_nr;
            if(fputc(ConvTable[TempChar], ipOutF) == EOF) {
              RetVal = -1;
              d2u_putc_error(ipFlag,progname);
              break;
            }
          } else{
            /* TempChar is a CR */
            if ( (TempNextChar = fgetc(ipInF)) != EOF) {
              if (ungetc( TempNextChar, ipInF ) == EOF) {  /* put back peek char */
                d2u_getc_error(ipFlag,progname);
                RetVal = -1;
                break;
              }
              /* Don't touch this delimiter if it's a CR,LF pair. */
              if ( TempNextChar == '\x0a' ) {
                if (fputc('\x0d', ipOutF) == EOF) { /* put CR, part of DOS CR-LF */
                  RetVal = -1;
                  d2u_putc_error(ipFlag,progname);
                  break;
                }
                PrevChar = TempChar;
                continue;
              }
            }
            if (fputc('\x0a', ipOutF) == EOF) { /* MAC line end (CR). Put LF */
              RetVal = -1;
              d2u_putc_error(ipFlag,progname);
              break;
            }
            converted++;
            line_nr++; /* Count all Mac line breaks */
            if (ipFlag->NewLine) {  /* add additional LF? */
              if (fputc('\x0a', ipOutF) == EOF) {
                RetVal = -1;
                d2u_putc_error(ipFlag,progname);
                break;
              }
            }
          }
          PrevChar = TempChar;
        }
        if (TempChar == EOF && ipFlag->add_eol && PrevChar != EOF && !(PrevChar == '\x0a' || PrevChar == '\x0d')) {
          /* Add missing line break at the last line. */
            if (ipFlag->verbose > 1) {
              D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
              D2U_UTF8_FPRINTF(stderr, _("Added line break to last line.\n"));
            }
            if (fputc('\x0a', ipOutF) == EOF) {
              RetVal = -1;
              d2u_putc_error(ipFlag,progname);
            }
        }
        if ((TempChar == EOF) && ferror(ipInF)) {
          RetVal = -1;
          d2u_getc_error(ipFlag,progname);
        }
        break;
      default: /* unknown FromToMode */
      ;
#if DEBUG
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_UTF8_FPRINTF(stderr, _("program error, invalid conversion mode %d\n"),ipFlag->FromToMode);
      exit(1);
#endif
    }
    if ((RetVal == 0) && (ipFlag->verbose > 1)) {
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_UTF8_FPRINTF(stderr, _("Converted %u out of %u line breaks.\n"),converted, line_nr -1);
    }
    return RetVal;
}


int main (int argc, char *argv[])
{
  /* variable declarations */
  char progname[9];
  CFlag *pFlag;
  char *ptr;
  char localedir[1024];
  int ret;
# ifdef __MINGW64__
  int _dowildcard = -1; /* enable wildcard expansion for Win64 */
# endif
  int  argc_new;
  char **argv_new;
#ifdef D2U_UNIFILE
  wchar_t **wargv;
  char ***argv_glob;
# endif

  progname[8] = '\0';
  strcpy(progname,"dos2unix");

#ifdef ENABLE_NLS
   ptr = getenv("DOS2UNIX_LOCALEDIR");
   if (ptr == NULL)
      d2u_strncpy(localedir,LOCALEDIR,sizeof(localedir));
   else {
      if (strlen(ptr) < sizeof(localedir))
         d2u_strncpy(localedir,ptr,sizeof(localedir));
      else {
         D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
         D2U_ANSI_FPRINTF(stderr, "%s", _("error: Value of environment variable DOS2UNIX_LOCALEDIR is too long.\n"));
         d2u_strncpy(localedir,LOCALEDIR,sizeof(localedir));
      }
   }
#endif

#if defined(ENABLE_NLS) || (defined(D2U_UNICODE) && !defined(__MSDOS__) && !defined(_WIN32) && !defined(__OS2__))
/* setlocale() is also needed for nl_langinfo() */
#if (defined(_WIN32) && !defined(__CYGWIN__))
/* When the locale is set to "" on Windows all East-Asian multi-byte ANSI encoded text is printed
   wrongly when you use standard printf(). Also UTF-8 code is printed wrongly. See also test/setlocale.c.
   When we set the locale to "C" gettext still translates the messages on Windows. On Unix this would disable
   gettext. */
   setlocale (LC_ALL, "C");
#else
   setlocale (LC_ALL, "");
#endif
#endif

#ifdef ENABLE_NLS
   bindtextdomain (PACKAGE, localedir);
   textdomain (PACKAGE);
#endif


  /* variable initialisations */
  pFlag = (CFlag*)malloc(sizeof(CFlag));
  if (pFlag == NULL) {
    D2U_UTF8_FPRINTF(stderr, "dos2unix:");
    D2U_ANSI_FPRINTF(stderr, " %s\n", strerror(errno));
    return errno;
  }
  pFlag->FromToMode = FROMTO_DOS2UNIX;  /* default dos2unix */
  pFlag->keep_bom = 0;

  if ( ((ptr=strrchr(argv[0],'/')) == NULL) && ((ptr=strrchr(argv[0],'\\')) == NULL) )
    ptr = argv[0];
  else
    ptr++;

  if ((strcmpi("mac2unix", ptr) == 0) || (strcmpi("mac2unix.exe", ptr) == 0)) {
    pFlag->FromToMode = FROMTO_MAC2UNIX;
    strcpy(progname,"mac2unix");
  }

#ifdef D2U_UNIFILE
  /* Get arguments in wide Unicode format in the Windows Command Prompt */

  /* This does not support wildcard expansion (globbing) */
  wargv = CommandLineToArgvW(GetCommandLineW(), &argc);

  argv_glob = (char ***)malloc(sizeof(char***));
  if (argv_glob == NULL) {
    D2U_UTF8_FPRINTF(stderr, "%s:", progname);
    D2U_ANSI_FPRINTF(stderr, " %s\n", strerror(errno));
    free(pFlag);
    return errno;
  }
  /* Glob the arguments and convert them to UTF-8 */
  argc_new = glob_warg(argc, wargv, argv_glob, pFlag, progname);
  argv_new = *argv_glob;
#else  
  argc_new = argc;
  argv_new = argv;
#endif

#ifdef D2U_UNICODE
  ret = parse_options(argc_new, argv_new, pFlag, localedir, progname, PrintLicense, ConvertDosToUnix, ConvertDosToUnixW);
#else
  ret = parse_options(argc_new, argv_new, pFlag, localedir, progname, PrintLicense, ConvertDosToUnix);
#endif
  free(pFlag);
  return ret;
}
