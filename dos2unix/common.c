/*
 *   Copyright (C) 2009-2023 Erwin Waterlander
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

#include "common.h"
#include "dos2unix.h"
#include "querycp.h"

#include <stdarg.h>

#if defined(D2U_UNIFILE) || (defined(D2U_UNICODE) && defined(_WIN32))
#include <windows.h>
#endif

#if defined(D2U_UNICODE) && !defined(__MSDOS__) && !defined(_WIN32) && !defined(__OS2__)  /* Unix, Cygwin */
# include <langinfo.h>
#endif

#if defined(__GLIBC__)
/* on glibc, canonicalize_file_name() broken prior to 2.4 (06-Mar-2006) */
# if __GNUC_PREREQ (2,4)
#  define USE_CANONICALIZE_FILE_NAME 1
# endif
#elif defined(__CYGWIN__)
/* on cygwin, canonicalize_file_name() available since api 0/213 */
/* (1.7.0beta61, 25-Sep-09) */
# include <cygwin/version.h>
# if (CYGWIN_VERSION_DLL_COMBINED >= 213) && (CYGWIN_VERSION_DLL_MAJOR >= 1007)
#  define USE_CANONICALIZE_FILE_NAME 1
# endif
#endif

/* global variables */
#ifdef D2U_UNIFILE
int d2u_display_encoding = D2U_DISPLAY_ANSI ;
#endif

/* Copy string src to dest, and null terminate dest.
   dest_size must be the buffer size of dest. */
char *d2u_strncpy(char *dest, const char *src, size_t dest_size)
{
    strncpy(dest,src,dest_size);
    dest[dest_size-1] = '\0';
#ifdef DEBUG
    if(strlen(src) > (dest_size-1)) {
        D2U_UTF8_FPRINTF(stderr, "Text %s has been truncated from %d to %d characters in %s to prevent a buffer overflow.\n", src, (int)strlen(src), (int)dest_size, "d2u_strncpy()");
    }
#endif
    return dest;
}

int d2u_fclose (FILE *fp, const char *filename, CFlag *ipFlag, const char *m, const char *progname)
{
  if (fclose(fp) != 0) {
    if (ipFlag->verbose) {
      ipFlag->error = errno;
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      if (m[0] == 'w')
        D2U_UTF8_FPRINTF(stderr, _("Failed to write to temporary output file %s:"), filename);
      else
        D2U_UTF8_FPRINTF(stderr, _("Failed to close input file %s:"), filename);
      D2U_ANSI_FPRINTF(stderr, " %s\n", strerror(errno));
    }
    return EOF;
  }
#if DEBUG
  else
     fprintf(stderr, "%s: Closing file \"%s\" OK.\n", progname, filename);
#endif
  return 0;
}


/*
 * Print last system error on Windows.
 *
 */
#if (defined(_WIN32) && !defined(__CYGWIN__))
void d2u_PrintLastError(const char *progname)
{
    /* Retrieve the system error message for the last-error code */

    LPVOID lpMsgBuf;
    DWORD dw;

    dw = GetLastError();

    FormatMessage(
        FORMAT_MESSAGE_ALLOCATE_BUFFER |
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        dw,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPTSTR) &lpMsgBuf,
        0, NULL );

    /* Display the error message */

    /* MessageBox(NULL, (LPCTSTR)lpMsgBuf, TEXT("Error"), MB_OK); */
    D2U_UTF8_FPRINTF(stderr, "%s: ",progname);
#ifdef _UNICODE
    fwprintf(stderr, L"%ls\n",(LPCTSTR)lpMsgBuf);
#else
    fprintf(stderr, "%s\n",(LPCTSTR)lpMsgBuf);
#endif

    LocalFree(lpMsgBuf);
}


int d2u_WideCharToMultiByte(UINT CodePage, DWORD dwFlags, LPCWSTR lpWideCharStr, int cchWideChar, LPSTR lpMultiByteStr, int cbMultiByte, LPCSTR lpDefaultChar, LPBOOL lpUsedDefaultChar)
{
  int i;

  if ( (i = WideCharToMultiByte(CodePage, dwFlags, lpWideCharStr, cchWideChar, lpMultiByteStr, cbMultiByte, lpDefaultChar, lpUsedDefaultChar)) == 0)
      d2u_PrintLastError("dos2unix");

  return i;
}

int d2u_MultiByteToWideChar(UINT CodePage, DWORD dwFlags, LPCSTR lpMultiByteStr, int cbMultiByte, LPWSTR lpWideCharStr, int cchWideChar)
{
  int i;

  if ( (i = MultiByteToWideChar(CodePage, dwFlags, lpMultiByteStr, cbMultiByte, lpWideCharStr, cchWideChar)) == 0)
      d2u_PrintLastError("dos2unix");
  return i;
}

#endif

#ifdef D2U_UNIFILE
/*
 * d2u_utf8_fprintf()  : printf wrapper, print in Windows Command Prompt in Unicode
 * mode, to have consistent output. Regardless of active code page.
 *
 * On Windows the file system uses always Unicode UTF-16 encoding, regardless
 * of the system default code page. This means that files and directories can
 * have names that can't be encoded in the default system Windows ANSI code
 * page.
 *
 * Dos2unix for Windows with Unicode file name support translates all directory
 * names to UTF-8, to be able to  work with char type strings.  This is also
 * done to keep the code portable.
 *
 * Dos2unix's messages are encoded in the default Windows ANSI code page, which
 * can be translated with gettext. Gettext/libintl recodes messages (format) to
 * the system default ANSI code page.
 *
 * d2u_utf8_fprintf() on Windows assumes that:
 * - The format string is encoded in the system default ANSI code page.
 * - The arguments are encoded in UTF-8.
 *
 * There are several methods for printing Unicode in the Windows Console, but
 * none of them is perfect. There are so many issues that I decided to go back
 * to ANSI by default.
 *
 * The use of setlocale() has influence on this function when ANSI or UTF-8 is
 * printed. See also dos2unix.c and unix2dos.c and test/setlocale.c and
 * test/setlocale.png.
 */

void d2u_utf8_fprintf( FILE *stream, const char* format, ... ) {
   va_list args;
   char buf[D2U_MAX_PATH];
   char formatmbs[D2U_MAX_PATH];
   wchar_t formatwcs[D2U_MAX_PATH];
   UINT outputCP;
   wchar_t wstr[D2U_MAX_PATH];
   int prevmode;
   static int BOM_printed = 0;

   va_start(args, format);

   /* The format string is encoded in the system default
    * Windows ANSI code page. May have been translated
    * by gettext. Convert it to wide characters. */
   d2u_MultiByteToWideChar(CP_ACP,0, format, -1, formatwcs, D2U_MAX_PATH);
   /* then convert the format string to UTF-8 */
   d2u_WideCharToMultiByte(CP_UTF8, 0, formatwcs, -1, formatmbs, D2U_MAX_PATH, NULL, NULL);

   /* The arguments (file names) are in UTF-8 encoding, because
    * in dos2unix for Windows all file names are in UTF-8 format.
    * Print to buffer (UTF-8) */
   vsnprintf(buf, sizeof(buf), formatmbs, args);

   if ((d2u_display_encoding == D2U_DISPLAY_UTF8) || (d2u_display_encoding == D2U_DISPLAY_UTF8BOM)) {

   /* A disadvantage of this method is that all non-ASCII characters are printed
      wrongly when the console uses raster font (which is the default).
      When I switch the system ANSI code page to 936 (Simplified Chinese) or 932 (Japanese)
      I see lot of flickering in the console when I print UTF-8.
      The cause could be that I have a Dutch Windows installation, and when the console is
      switched to UTF-8 mode (CP65001) the font is switched back to Western font (Lucida Console,
      Consolas). These are the only fonts which I can select when I set the code page in the
      console to 65001 with chcp, while the system ANSI code is 936 or 932.
   */
       /* print UTF-8 buffer to console in UTF-8 mode */
      outputCP = GetConsoleOutputCP();
      SetConsoleOutputCP(CP_UTF8);
      if (! BOM_printed) {
          if (d2u_display_encoding == D2U_DISPLAY_UTF8BOM)
              fwprintf(stream, L"%S","\xEF\xBB\xBF");
          BOM_printed = 1;
      }
      fwprintf(stream,L"%S",buf);
      fflush(stream);
      SetConsoleOutputCP(outputCP);

   /* The following UTF-8 method does not give correct output. I don't know why. */
   /*prevmode = _setmode(_fileno(stream), _O_U8TEXT);
     fwprintf(stream,L"%S",buf);
     fflush(stream);
     _setmode(_fileno(stream), prevmode); */

   } else if ((d2u_display_encoding == D2U_DISPLAY_UNICODE) || (d2u_display_encoding == D2U_DISPLAY_UNICODEBOM)) {

   /* Printing UTF-16 works correctly. Works also good with raster fonts.
      No need to change the OEM code page to the system ANSI code page.
    */
      d2u_MultiByteToWideChar(CP_UTF8,0, buf, -1, wstr, D2U_MAX_PATH);
      prevmode = _setmode(_fileno(stream), _O_U16TEXT);
      if (! BOM_printed) {
          /* For correct redirection in PowerShell we need to print a BOM */
          if (d2u_display_encoding == D2U_DISPLAY_UNICODEBOM)
              fwprintf(stream, L"\xfeff");
          BOM_printed = 1;
      }
      fwprintf(stream,L"%ls",wstr);
      fflush(stream);  /* Flushing is required to get correct UTF-16 when stdout is redirected. */
      _setmode(_fileno(stream), prevmode);

   } else {  /* ANSI */

      d2u_MultiByteToWideChar(CP_UTF8,0, buf, -1, wstr, D2U_MAX_PATH);
      /* Convert the whole message to ANSI, some Unicode characters may fail to translate to ANSI.
         They will be displayed as a question mark. */
      d2u_WideCharToMultiByte(CP_ACP, 0, wstr, -1, buf, D2U_MAX_PATH, NULL, NULL);
      fprintf(stream,"%s",buf);
   }

   va_end( args );
}

/* d2u_ansi_fprintf()
   fprintf wrapper for Windows console.

   Format and arguments are in ANSI format.
   Redirect the printing to d2u_utf8_fprintf such that the output
   format is consistent. To prevent a mix of ANSI/UTF-8/UTF-16
   encodings in the print output. Mixed format printing may get the whole
   console mixed up.
 */

void d2u_ansi_fprintf( FILE *stream, const char* format, ... ) {
   va_list args;
   char buf[D2U_MAX_PATH];        /* ANSI encoded string */
   char bufmbs[D2U_MAX_PATH];     /* UTF-8 encoded string */
   wchar_t bufwcs[D2U_MAX_PATH];  /* Wide encoded string */

   va_start(args, format);

   vsnprintf(buf, sizeof(buf), format, args);
   /* The format string and arguments are encoded in the system default
    * Windows ANSI code page. May have been translated
    * by gettext. Convert it to wide characters. */
   d2u_MultiByteToWideChar(CP_ACP,0, buf, -1, bufwcs, D2U_MAX_PATH);
   /* then convert the format string to UTF-8 */
   d2u_WideCharToMultiByte(CP_UTF8, 0, bufwcs, -1, bufmbs, D2U_MAX_PATH, NULL, NULL);

   d2u_utf8_fprintf(stream, "%s",bufmbs);

   va_end( args );
}
#endif

/*   d2u_rename
 *   wrapper for rename().
 *   On Windows file names are encoded in UTF-8.
 */
int d2u_rename(const char *oldname, const char *newname)
{
#ifdef D2U_UNIFILE
   wchar_t oldnamew[D2U_MAX_PATH];
   wchar_t newnamew[D2U_MAX_PATH];
   d2u_MultiByteToWideChar(CP_UTF8, 0, oldname, -1, oldnamew, D2U_MAX_PATH);
   d2u_MultiByteToWideChar(CP_UTF8, 0, newname, -1, newnamew, D2U_MAX_PATH);
   return _wrename(oldnamew, newnamew);
#else
   return rename(oldname, newname);
#endif
}

/*   d2u_unlink
 *   wrapper for unlink().
 *   On Windows file names are encoded in UTF-8.
 */
int d2u_unlink(const char *filename)
{
#ifdef D2U_UNIFILE
   wchar_t filenamew[D2U_MAX_PATH];
   d2u_MultiByteToWideChar(CP_UTF8, 0, filename, -1, filenamew, D2U_MAX_PATH);
   return _wunlink(filenamew);
#else
   return unlink(filename);
#endif
}

/******************************************************************
 *
 * int symbolic_link(char *path)
 *
 * test if *path points to a file that exists and is a symbolic link
 *
 * returns 1 on success, 0 when it fails.
 *
 ******************************************************************/

#ifdef D2U_UNIFILE

int symbolic_link(const char *path)
{
   DWORD attrs;
   wchar_t pathw[D2U_MAX_PATH];

   d2u_MultiByteToWideChar(CP_UTF8, 0, path, -1, pathw, D2U_MAX_PATH);
   attrs = GetFileAttributesW(pathw);

   if (attrs == INVALID_FILE_ATTRIBUTES)
      return(0);

   return ((attrs & FILE_ATTRIBUTE_REPARSE_POINT) != 0);
}

#elif(defined(_WIN32) && !defined(__CYGWIN__))

int symbolic_link(const char *path)
{
   DWORD attrs;

   attrs = GetFileAttributes(path);

   if (attrs == INVALID_FILE_ATTRIBUTES)
      return(0);

   return ((attrs & FILE_ATTRIBUTE_REPARSE_POINT) != 0);
}

#else
int symbolic_link(const char *path)
{
#ifdef S_ISLNK
   struct stat buf;

   if (STAT(path, &buf) == 0) {
      if (S_ISLNK(buf.st_mode))
         return(1);
   }
#endif
   return(0);
}
#endif

/******************************************************************
 *
 * int regfile(char *path, int allowSymlinks)
 *
 * test if *path points to a regular file (or is a symbolic link,
 * if allowSymlinks != 0).
 *
 * returns 0 on success, -1 when it fails.
 *
 ******************************************************************/
int regfile(char *path, int allowSymlinks, CFlag *ipFlag, const char *progname)
{
#ifdef D2U_UNIFILE
   struct _stat buf;
   wchar_t pathw[D2U_MAX_PATH];
#else
   struct stat buf;
#endif

#ifdef D2U_UNIFILE
   d2u_MultiByteToWideChar(CP_UTF8, 0, path, -1, pathw, D2U_MAX_PATH);
   if (_wstat(pathw, &buf) == 0) {
#else
   if (STAT(path, &buf) == 0) {
#endif
#if DEBUG
      D2U_UTF8_FPRINTF(stderr, "%s: %s", progname, path);
      D2U_UTF8_FPRINTF(stderr, " MODE 0%o ", buf.st_mode);
#ifdef S_ISSOCK
      if (S_ISSOCK(buf.st_mode))
         D2U_UTF8_FPRINTF(stderr, " (socket)");
#endif
#ifdef S_ISLNK
      if (S_ISLNK(buf.st_mode))
         D2U_UTF8_FPRINTF(stderr, " (symbolic link)");
#endif
      if (S_ISREG(buf.st_mode))
         D2U_UTF8_FPRINTF(stderr, " (regular file)");
#ifdef S_ISBLK
      if (S_ISBLK(buf.st_mode))
         D2U_UTF8_FPRINTF(stderr, " (block device)");
#endif
      if (S_ISDIR(buf.st_mode))
         D2U_UTF8_FPRINTF(stderr, " (directory)");
      if (S_ISCHR(buf.st_mode))
         D2U_UTF8_FPRINTF(stderr, " (character device)");
      if (S_ISFIFO(buf.st_mode))
         D2U_UTF8_FPRINTF(stderr, " (FIFO)");
      D2U_UTF8_FPRINTF(stderr, "\n");
#endif
      if ((S_ISREG(buf.st_mode))
#ifdef S_ISLNK
          || (S_ISLNK(buf.st_mode) && allowSymlinks)
#endif
         )
         return(0);
      else
         return(-1);
   }
   else {
     if (ipFlag->verbose) {
       const char *errstr = strerror(errno);
       ipFlag->error = errno;
       D2U_UTF8_FPRINTF(stderr, "%s: %s:", progname, path);
       D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
     }
     return(-1);
   }
}

/******************************************************************
 *
 * int regfile_target(char *path)
 *
 * test if *path points to a regular file (follow symbolic link)
 *
 * returns 0 on success, -1 when it fails.
 *
 ******************************************************************/
int regfile_target(char *path, CFlag *ipFlag, const char *progname)
{
#ifdef D2U_UNIFILE
   struct _stat buf;
   wchar_t pathw[D2U_MAX_PATH];
#else
   struct stat buf;
#endif

#ifdef D2U_UNIFILE
   d2u_MultiByteToWideChar(CP_UTF8, 0, path, -1, pathw, D2U_MAX_PATH);
   if (_wstat(pathw, &buf) == 0) {
#else
   if (stat(path, &buf) == 0) {
#endif
      if (S_ISREG(buf.st_mode))
         return(0);
      else
         return(-1);
   }
   else {
     if (ipFlag->verbose) {
       const char *errstr = strerror(errno);
       ipFlag->error = errno;
       D2U_UTF8_FPRINTF(stderr, "%s: %s:", progname, path);
       D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
     }
     return(-1);
   }
}

/*
 *   glob_warg() expands the wide command line arguments.
 *   Input  : wide Unicode arguments.
 *   Output : argv : expanded arguments in UTF-8 format.
 *   Returns: new argc value.
 *            -1 when an error occurred.
 *
 */

#ifdef D2U_UNIFILE
int glob_warg(int argc, wchar_t *wargv[], char ***argv, CFlag *ipFlag, const char *progname)
{
  int i;
  int argc_glob = 0;
  wchar_t *warg;
  wchar_t *path;
  wchar_t *path_and_filename;
  wchar_t *ptr;
  char  *arg;
  char  **argv_new;
  const char *errstr;
  size_t len;
  int found, add_path;
  WIN32_FIND_DATA FindFileData;
  HANDLE hFind;

  argv_new = (char **)malloc(sizeof(char**));
  if (argv_new == NULL) goto glob_failed;

  len = (size_t)d2u_WideCharToMultiByte(CP_UTF8, 0, wargv[0], -1, NULL, 0, NULL, NULL);
  arg = (char *)malloc(len);
  if (arg == NULL) goto glob_failed;
  d2u_WideCharToMultiByte(CP_UTF8, 0, wargv[argc_glob], -1, arg, (int)len, NULL, NULL);
  argv_new[argc_glob] = arg;

  for (i=1; i<argc; ++i)
  {
    warg = wargv[i];
    found = 0;
    add_path = 0;
    /* FindFileData.cFileName has the path stripped off. We need to add it again. */
    path = _wcsdup(warg);
    /* replace all back slashes with slashes */
    while ( (ptr = wcschr(path,L'\\')) != NULL) {
      *ptr = L'/';
    }
    if ( (ptr = wcsrchr(path,L'/')) != NULL) {
      ptr++;
      *ptr = L'\0';
      add_path = 1;
    }

    hFind = FindFirstFileW(warg, &FindFileData);
    while (hFind != INVALID_HANDLE_VALUE)
    {
      char **new_argv_new;
      len = wcslen(path) + wcslen(FindFileData.cFileName) + 2;
      path_and_filename = (wchar_t *)malloc(len*sizeof(wchar_t));
      if (path_and_filename == NULL) goto glob_failed;
      if (add_path) {
        wcsncpy(path_and_filename, path, wcslen(path)+1);
        wcsncat(path_and_filename, FindFileData.cFileName, wcslen(FindFileData.cFileName)+1);
      } else {
        wcsncpy(path_and_filename, FindFileData.cFileName, wcslen(FindFileData.cFileName)+1);
      }

      found = 1;
      ++argc_glob;
      len =(size_t) d2u_WideCharToMultiByte(CP_UTF8, 0, path_and_filename, -1, NULL, 0, NULL, NULL);
      arg = (char *)malloc((size_t)len);
      if (arg == NULL) goto glob_failed;
      d2u_WideCharToMultiByte(CP_UTF8, 0, path_and_filename, -1, arg, (int)len, NULL, NULL);
      free(path_and_filename);
      new_argv_new = (char **)realloc(argv_new, (size_t)(argc_glob+1)*sizeof(char**));
      if (new_argv_new == NULL) goto glob_failed;
      else
        argv_new = new_argv_new;
      argv_new[argc_glob] = arg;

      if (!FindNextFileW(hFind, &FindFileData)) {
        FindClose(hFind);
        hFind = INVALID_HANDLE_VALUE;
      }
    }
    free(path);
    if (found == 0) {
    /* Not a file. Just copy the argument */
      char **new_argv_new;
      ++argc_glob;
      len =(size_t) d2u_WideCharToMultiByte(CP_UTF8, 0, warg, -1, NULL, 0, NULL, NULL);
      arg = (char *)malloc((size_t)len);
      if (arg == NULL) goto glob_failed;
      d2u_WideCharToMultiByte(CP_UTF8, 0, warg, -1, arg, (int)len, NULL, NULL);
      new_argv_new = (char **)realloc(argv_new, (size_t)(argc_glob+1)*sizeof(char**));
      if (new_argv_new == NULL) goto glob_failed;
      else
        argv_new = new_argv_new;
      argv_new[argc_glob] = arg;
    }
  }
  *argv = argv_new;
  return ++argc_glob;

  glob_failed:
  if (ipFlag->verbose) {
    ipFlag->error = errno;
    errstr = strerror(errno);
    D2U_UTF8_FPRINTF(stderr, "%s:", progname);
    D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
  }
  return -1;
}
#endif

void PrintBSDLicense(void)
{
  D2U_ANSI_FPRINTF(stdout,"%s", _("\
Redistribution and use in source and binary forms, with or without\n\
modification, are permitted provided that the following conditions\n\
are met:\n\
1. Redistributions of source code must retain the above copyright\n\
   notice, this list of conditions and the following disclaimer.\n\
2. Redistributions in binary form must reproduce the above copyright\n\
   notice in the documentation and/or other materials provided with\n\
   the distribution.\n\n\
"));
  D2U_ANSI_FPRINTF(stdout,"%s", _("\
THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY\n\
EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE\n\
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR\n\
PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE\n\
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR\n\
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT\n\
OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR\n\
BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,\n\
WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE\n\
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN\n\
IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.\n\
"));
}

int is_dos2unix(const char *progname)
{
  if ((strncmp(progname, "dos2unix", sizeof("dos2unix")) == 0) || (strncmp(progname, "mac2unix", sizeof("mac2unix")) == 0))
    return 1;
  else
    return 0;
}

void PrintUsage(const char *progname)
{
  D2U_ANSI_FPRINTF(stdout,_("Usage: %s [options] [file ...] [-n infile outfile ...]\n"), progname);
#ifndef NO_CHOWN
  D2U_ANSI_FPRINTF(stdout,_(" --allow-chown         allow file ownership change\n"));
#endif
  D2U_ANSI_FPRINTF(stdout,_(" -ascii                convert only line breaks (default)\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -iso                  conversion between DOS and ISO-8859-1 character set\n"));
  D2U_ANSI_FPRINTF(stdout,_("   -1252               use Windows code page 1252 (Western European)\n"));
  D2U_ANSI_FPRINTF(stdout,_("   -437                use DOS code page 437 (US) (default)\n"));
  D2U_ANSI_FPRINTF(stdout,_("   -850                use DOS code page 850 (Western European)\n"));
  D2U_ANSI_FPRINTF(stdout,_("   -860                use DOS code page 860 (Portuguese)\n"));
  D2U_ANSI_FPRINTF(stdout,_("   -863                use DOS code page 863 (French Canadian)\n"));
  D2U_ANSI_FPRINTF(stdout,_("   -865                use DOS code page 865 (Nordic)\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -7                    convert 8 bit characters to 7 bit space\n"));
  if (is_dos2unix(progname))
    D2U_ANSI_FPRINTF(stdout,_(" -b, --keep-bom        keep Byte Order Mark\n"));
  else
    D2U_ANSI_FPRINTF(stdout,_(" -b, --keep-bom        keep Byte Order Mark (default)\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -c, --convmode        conversion mode\n\
   convmode            ascii, 7bit, iso, mac, default to ascii\n"));
#ifdef D2U_UNIFILE
  D2U_ANSI_FPRINTF(stdout,_(" -D, --display-enc     set encoding of displayed text messages\n\
   encoding            ansi, unicode, utf8, default to ansi\n"));
#endif
  D2U_ANSI_FPRINTF(stdout,_(" -e, --add-eol         add a line break to the last line if there isn't one\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -f, --force           force conversion of binary files\n"));
#ifdef D2U_UNICODE
#if (defined(_WIN32) && !defined(__CYGWIN__))
  D2U_ANSI_FPRINTF(stdout,_(" -gb, --gb18030        convert UTF-16 to GB18030\n"));
#endif
#endif
  D2U_ANSI_FPRINTF(stdout,_(" -h, --help            display this help text\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -i, --info[=FLAGS]    display file information\n\
   file ...            files to analyze\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -k, --keepdate        keep output file date\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -L, --license         display software license\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -l, --newline         add additional newline\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -m, --add-bom         add Byte Order Mark (default UTF-8)\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -n, --newfile         write to new file\n\
   infile              original file in new-file mode\n\
   outfile             output file in new-file mode\n"));
#ifndef NO_CHOWN
  D2U_ANSI_FPRINTF(stdout,_(" --no-allow-chown      don't allow file ownership change (default)\n"));
#endif
  D2U_ANSI_FPRINTF(stdout,_(" --no-add-eol          don't add a line break to the last line if there isn't one (default)\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -O, --to-stdout       write to standard output\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -o, --oldfile         write to old file (default)\n\
   file ...            files to convert in old-file mode\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -q, --quiet           quiet mode, suppress all warnings\n"));
  if (is_dos2unix(progname))
    D2U_ANSI_FPRINTF(stdout,_(" -r, --remove-bom      remove Byte Order Mark (default)\n"));
  else
    D2U_ANSI_FPRINTF(stdout,_(" -r, --remove-bom      remove Byte Order Mark\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -s, --safe            skip binary files (default)\n"));
#ifdef D2U_UNICODE
  D2U_ANSI_FPRINTF(stdout,_(" -u,  --keep-utf16     keep UTF-16 encoding\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -ul, --assume-utf16le assume that the input format is UTF-16LE\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -ub, --assume-utf16be assume that the input format is UTF-16BE\n"));
#endif
  D2U_ANSI_FPRINTF(stdout,_(" -v,  --verbose        verbose operation\n"));
#ifdef S_ISLNK
  D2U_ANSI_FPRINTF(stdout,_(" -F, --follow-symlink  follow symbolic links and convert the targets\n"));
#endif
#if defined(S_ISLNK) || (defined(_WIN32) && !defined(__CYGWIN__))
  D2U_ANSI_FPRINTF(stdout,_(" -R, --replace-symlink replace symbolic links with converted files\n\
                         (original target files remain unchanged)\n"));
  D2U_ANSI_FPRINTF(stdout,_(" -S, --skip-symlink    keep symbolic links and targets unchanged (default)\n"));
#endif
  D2U_ANSI_FPRINTF(stdout,_(" -V, --version         display version number\n"));
}

#define MINGW32_W64 1

void PrintVersion(const char *progname, const char *localedir)
{
  D2U_ANSI_FPRINTF(stdout,"%s %s (%s)\n", progname, VER_REVISION, VER_DATE);
#if DEBUG
  D2U_ANSI_FPRINTF(stdout,"VER_AUTHOR: %s\n", VER_AUTHOR);
#endif
#if defined(__WATCOMC__) && defined(__I86__)
  D2U_ANSI_FPRINTF(stdout,"%s", _("DOS 16 bit version (WATCOMC).\n"));
#elif defined(__TURBOC__) && defined(__MSDOS__)
  D2U_ANSI_FPRINTF(stdout,"%s", _("DOS 16 bit version (TURBOC).\n"));
#elif defined(__WATCOMC__) && defined(__DOS__)
  D2U_ANSI_FPRINTF(stdout,"%s", _("DOS 32 bit version (WATCOMC).\n"));
#elif defined(__DJGPP__)
  D2U_ANSI_FPRINTF(stdout,"%s", _("DOS 32 bit version (DJGPP).\n"));
#elif defined(__MSYS__)
  D2U_ANSI_FPRINTF(stdout,"%s", _("MSYS version.\n"));
#elif defined(__CYGWIN__)
  D2U_ANSI_FPRINTF(stdout,"%s", _("Cygwin version.\n"));
#elif defined(__WIN64__) && defined(__MINGW64__)
  D2U_ANSI_FPRINTF(stdout,"%s", _("Windows 64 bit version (MinGW-w64).\n"));
#elif defined(__WATCOMC__) && defined(__NT__)
  D2U_ANSI_FPRINTF(stdout,"%s", _("Windows 32 bit version (WATCOMC).\n"));
#elif defined(_WIN32) && defined(__MINGW32__) && (D2U_COMPILER == MINGW32_W64)
  D2U_ANSI_FPRINTF(stdout,"%s", _("Windows 32 bit version (MinGW-w64).\n"));
#elif defined(_WIN32) && defined(__MINGW32__)
  D2U_ANSI_FPRINTF(stdout,"%s", _("Windows 32 bit version (MinGW).\n"));
#elif defined(_WIN64) && defined(_MSC_VER)
  D2U_ANSI_FPRINTF(stdout,_("Windows 64 bit version (MSVC %d).\n"),_MSC_VER);
#elif defined(_WIN32) && defined(_MSC_VER)
  D2U_ANSI_FPRINTF(stdout,_("Windows 32 bit version (MSVC %d).\n"),_MSC_VER);
#elif defined (__OS2__) && defined(__WATCOMC__) /* OS/2 Warp */
  D2U_ANSI_FPRINTF(stdout,"%s", _("OS/2 version (WATCOMC).\n"));
#elif defined (__OS2__) && defined(__EMX__) /* OS/2 Warp */
  D2U_ANSI_FPRINTF(stdout,"%s", _("OS/2 version (EMX).\n"));
#elif defined(__OS)
  D2U_ANSI_FPRINTF(stdout,_("%s version.\n"), __OS);
#endif
#if defined(_WIN32) && defined(WINVER)
  D2U_ANSI_FPRINTF(stdout,"WINVER 0x%X\n",WINVER);
#endif
#ifdef D2U_UNICODE
  D2U_ANSI_FPRINTF(stdout,"%s", _("With Unicode UTF-16 support.\n"));
#else
  D2U_ANSI_FPRINTF(stdout,"%s", _("Without Unicode UTF-16 support.\n"));
#endif
#ifdef _WIN32
#ifdef D2U_UNIFILE
  D2U_ANSI_FPRINTF(stdout,"%s", _("With Unicode file name support.\n"));
#else
  D2U_ANSI_FPRINTF(stdout,"%s", _("Without Unicode file name support.\n"));
#endif
#endif
#ifdef ENABLE_NLS
  D2U_ANSI_FPRINTF(stdout,"%s", _("With native language support.\n"));
#else
  D2U_ANSI_FPRINTF(stdout,"%s", "Without native language support.\n");
#endif
#ifndef NO_CHOWN
  D2U_ANSI_FPRINTF(stdout,"%s", _("With support to preserve the user and group ownership of files.\n"));
#else
  D2U_ANSI_FPRINTF(stdout,"%s", _("Without support to preserve the user and group ownership of files.\n"));
#endif
#ifdef ENABLE_NLS
  D2U_ANSI_FPRINTF(stdout,"LOCALEDIR: %s\n", localedir);
#endif
  D2U_ANSI_FPRINTF(stdout,"https://waterlan.home.xs4all.nl/dos2unix.html\n");
  D2U_ANSI_FPRINTF(stdout,"https://dos2unix.sourceforge.io/\n");
}

/* opens file of name ipFN in read only mode
 * returns: NULL if failure
 *          file stream otherwise
 */
FILE* OpenInFile(char *ipFN)
{
#ifdef D2U_UNIFILE
  wchar_t pathw[D2U_MAX_PATH];

  d2u_MultiByteToWideChar(CP_UTF8, 0, ipFN, -1, pathw, D2U_MAX_PATH);
  return _wfopen(pathw, R_CNTRLW);
#else
  return (fopen(ipFN, R_CNTRL));
#endif
}


/* opens file of name opFN in write only mode
 * returns: NULL if failure
 *          file stream otherwise
 */
FILE* OpenOutFile(char *opFN)
{
#ifdef D2U_UNIFILE
  wchar_t pathw[D2U_MAX_PATH];

  d2u_MultiByteToWideChar(CP_UTF8, 0, opFN, -1, pathw, D2U_MAX_PATH);
  return _wfopen(pathw, W_CNTRLW);
#else
  return (fopen(opFN, W_CNTRL));
#endif
}

/* opens file descriptor in write only mode
 * returns: NULL if failure
 *          file stream otherwise
 */
FILE* OpenOutFiled(int fd)
{
  return (fdopen(fd, W_CNTRL));
}

#if defined(__TURBOC__) || defined(__MSYS__) || defined(_MSC_VER)
/* Both dirname() and basename() may modify the contents of path.
 * It may be desirable to pass a copy. */
char *dirname(char *path)
{
  char *ptr;

  /* replace all back slashes with slashes */
  while ( (ptr = strchr(path,'\\')) != NULL)
    *ptr = '/';
  /* Code checkers may report that the condition (path == NULL) is redundant.
     E.g. Cppcheck 1.72. The condition (path == NULL) is needed, because
     the behaviour of strrchr is not specified when it get's a NULL string.
     The behaviour may be undefined, dependent on the implementation. */
  if ((path == NULL) || ((ptr=strrchr(path,'/')) == NULL))
    return ".";

  if (strcmp(path,"/") == 0)
    return "/";

  *ptr = '\0';
  return path;
}

#ifdef NO_MKSTEMP
char *basename(char *path)
{
  char *ptr;

  /* replace all back slashes with slashes */
  while ( (ptr = strchr(path,'\\')) != NULL)
    *ptr = '/';
  /* Code checkers may report that the condition (path == NULL) is redundant.
     E.g. Cppcheck 1.72. The condition (path == NULL) is needed, because
     the behaviour of strrchr is not specified when it get's a NULL string.
     The behaviour may be undefined, dependent on the implementation. */
  if ((path == NULL) || ((ptr=strrchr(path,'/')) == NULL))
    return path ;

  if (strcmp(path,"/") == 0)
    return "/";

   ptr++;
   return ptr ;
}
#endif
#endif

/* Standard mktemp() is not safe to use (See mktemp(3)).
 * On Windows it is recommended to use GetTempFileName() (See MSDN).
 * This mktemp() wrapper redirects to GetTempFileName() on Windows.
 * On Windows template is not modified, the returned pointer has to
 * be used.
 */
#ifdef NO_MKSTEMP
char *d2u_mktemp(char *template)
{
#if defined(_WIN32) && !defined(__CYGWIN__)

  unsigned int uRetVal;
  char *cpy1, *cpy2, *dn, *bn;
  char *ptr;
  size_t len;
#ifdef D2U_UNIFILE /* template is UTF-8 formatted. */
  wchar_t dnw[MAX_PATH];
  wchar_t bnw[MAX_PATH];
  wchar_t szTempFileNamew[MAX_PATH];
  char *fname_str;
  int error = 0;
#else
  char szTempFileName[MAX_PATH];
  char *fname_str;
#endif
  if ((cpy1 = strdup(template)) == NULL)
    return NULL;
  if ((cpy2 = strdup(template)) == NULL) {
    free(cpy1);
    return NULL;
  }
  dn = dirname(cpy1);
  bn = basename(cpy2);
#ifdef D2U_UNIFILE /* template is UTF-8 formatted. */
  if (d2u_MultiByteToWideChar(CP_UTF8, 0, dn, -1, NULL, 0) > (MAX_PATH - 15)) {
      D2U_UTF8_FPRINTF(stderr, "%s: ", "dos2unix");
      D2U_ANSI_FPRINTF(stderr, _("Path for temporary output file is too long:"));
      D2U_UTF8_FPRINTF(stderr, " %s\n", dn);
      error=1;
  }
  if ((!error) && (d2u_MultiByteToWideChar(CP_UTF8, 0, dn, -1, dnw, MAX_PATH) == 0))
    error=1;
  if ((!error) && (d2u_MultiByteToWideChar(CP_UTF8, 0, bn, -1, bnw, MAX_PATH) == 0))
    error=1;
  free(cpy1);
  free(cpy2);
  if (error)
    return NULL;
  uRetVal = GetTempFileNameW(dnw, bnw, 0, szTempFileNamew);
  if (! uRetVal) {
    d2u_PrintLastError("dos2unix");
    return NULL;
  }
  len =(size_t) d2u_WideCharToMultiByte(CP_UTF8, 0, szTempFileNamew, -1, NULL, 0, NULL, NULL);
  fname_str = (char *)malloc(len);
  if (! fname_str)
    return NULL;
  if (d2u_WideCharToMultiByte(CP_UTF8, 0, szTempFileNamew, -1, fname_str, MAX_PATH, NULL, NULL) == 0)
    return NULL;
#else
  uRetVal = GetTempFileNameA(dn, bn, 0, szTempFileName);
  free(cpy1);
  free(cpy2);
  if (! uRetVal) {
    d2u_PrintLastError("dos2unix");
    return NULL;
  }
  len = strlen(szTempFileName) +1;
  fname_str = (char *)malloc(len);
  if (! fname_str)
    return NULL;
  d2u_strncpy(fname_str, szTempFileName,len);
#endif
  /* replace all back slashes with slashes */
  while ( (ptr = strchr(fname_str,'\\')) != NULL)
    *ptr = '/';
  return fname_str;

#else
  return mktemp(template);
#endif
}
#endif

FILE* MakeTempFileFrom(const char *OutFN, char **fname_ret)
{
  char *cpy = strdup(OutFN);
  char *dir = NULL;
  size_t fname_len = 0;
  char  *fname_str = NULL;
  FILE *fp = NULL;  /* file pointer */
#ifdef NO_MKSTEMP
  char *name;
#else
  int fd = -1;  /* file descriptor */
#endif

  *fname_ret = NULL;

  if (!cpy)
    goto make_failed;

  dir = dirname(cpy);

  fname_len = strlen(dir) + strlen("/d2utmpXXXXXX") + sizeof (char);
  if (!(fname_str = (char *)malloc(fname_len)))
    goto make_failed;
  sprintf(fname_str, "%s%s", dir, "/d2utmpXXXXXX");
  *fname_ret = fname_str;

  free(cpy);
  cpy = NULL;

#ifdef NO_MKSTEMP
  if ((name = d2u_mktemp(fname_str)) == NULL)
    goto make_failed;
  *fname_ret = name;
  if ((fp = OpenOutFile(name)) == NULL)
    goto make_failed;
#else
  if ((fd = mkstemp(fname_str)) == -1)
    goto make_failed;

  if ((fp=OpenOutFiled(fd)) == NULL)
    goto make_failed;
#endif

  return (fp);

  make_failed:
    if (cpy) {
       free(cpy);
       cpy = NULL;
    }
    free(*fname_ret);
    *fname_ret = NULL;
    return NULL;
}

/* Test if *lFN is the name of a symbolic link.  If not, set *rFN equal
 * to lFN, and return 0.  If so, then use canonicalize_file_name or
 * realpath to determine the pointed-to file; the resulting name is
 * stored in newly allocated memory, *rFN is set to point to that value,
 * and 1 is returned. On error, -1 is returned and errno is set as
 * appropriate.
 *
 * Note that if symbolic links are not supported, then 0 is always returned
 * and *rFN = lFN.
 *
 * returns: 0 if success, and *lFN is not a symlink
 *          1 if success, and *lFN is a symlink
 *         -1 otherwise
 */
int ResolveSymbolicLink(char *lFN, char **rFN, CFlag *ipFlag, const char *progname)
{
  int RetVal = 0;
#ifdef S_ISLNK
  struct stat StatBuf;
  const char *errstr;
  char *targetFN = NULL;

  if (STAT(lFN, &StatBuf)) {
    if (ipFlag->verbose) {
      ipFlag->error = errno;
      errstr = strerror(errno);
      D2U_UTF8_FPRINTF(stderr, "%s: %s:", progname, lFN);
      D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
    }
    RetVal = -1;
  }
  else if (S_ISLNK(StatBuf.st_mode)) {
#if USE_CANONICALIZE_FILE_NAME
    targetFN = canonicalize_file_name(lFN);
    if (!targetFN) {
      if (ipFlag->verbose) {
        ipFlag->error = errno;
        errstr = strerror(errno);
        D2U_UTF8_FPRINTF(stderr, "%s: %s:", progname, lFN);
        D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
      }
      RetVal = -1;
    }
    else {
      *rFN = targetFN;
      RetVal = 1;
    }
#else
    /* Sigh. Use realpath, but realize that it has a fatal
     * flaw: PATH_MAX isn't necessarily the maximum path
     * length -- so realpath() might fail. */
    targetFN = (char *) malloc(PATH_MAX * sizeof(char));
    if (!targetFN) {
      if (ipFlag->verbose) {
        ipFlag->error = errno;
        errstr = strerror(errno);
        D2U_UTF8_FPRINTF(stderr, "%s: %s:", progname, lFN);
        D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
      }
      RetVal = -1;
    }
    else {
      /* is there any platform with S_ISLNK that does not have realpath? */
      char *rVal = realpath(lFN, targetFN);
      if (!rVal) {
        if (ipFlag->verbose) {
          ipFlag->error = errno;
          errstr = strerror(errno);
          D2U_UTF8_FPRINTF(stderr, "%s: %s:", progname, lFN);
          D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
        }
        free(targetFN);
        RetVal = -1;
      }
      else {
        *rFN = rVal;
        RetVal = 1;
      }
    }
#endif /* !USE_CANONICALIZE_FILE_NAME */
  }
  else
    *rFN = lFN;
#else  /* !S_ISLNK */
  *rFN = lFN;
#endif /* !S_ISLNK */
  return RetVal;
}

/* Read the Byte Order Mark.
   Returns file pointer or NULL in case of a read error */

FILE *read_bom (FILE *f, int *bomtype)
{
  /* BOMs
   * UTF16-LE  ff fe
   * UTF16-BE  fe ff
   * UTF-8     ef bb bf
   * GB18030   84 31 95 33
   */

  *bomtype = FILE_MBS;

   /* Check for BOM */
   if  (f != NULL) {
      int bom[4];
      if ((bom[0] = fgetc(f)) == EOF) {
         if (ferror(f)) {
           return NULL;
         }
         *bomtype = FILE_MBS;
         return(f);
      }
      if ((bom[0] != 0xff) && (bom[0] != 0xfe) && (bom[0] != 0xef) && (bom[0] != 0x84)) {
         if (ungetc(bom[0], f) == EOF) return NULL;
         *bomtype = FILE_MBS;
         return(f);
      }
      if ((bom[1] = fgetc(f)) == EOF) {
         if (ferror(f)) {
           return NULL;
         }
         if (ungetc(bom[1], f) == EOF) return NULL;
         if (ungetc(bom[0], f) == EOF) return NULL;
         *bomtype = FILE_MBS;
         return(f);
      }
      if ((bom[0] == 0xff) && (bom[1] == 0xfe)) { /* UTF16-LE */
         *bomtype = FILE_UTF16LE;
         return(f);
      }
      if ((bom[0] == 0xfe) && (bom[1] == 0xff)) { /* UTF16-BE */
         *bomtype = FILE_UTF16BE;
         return(f);
      }
      if ((bom[2] = fgetc(f)) == EOF) {
         if (ferror(f)) {
           return NULL;
         }
         if (ungetc(bom[2], f) == EOF) return NULL;
         if (ungetc(bom[1], f) == EOF) return NULL;
         if (ungetc(bom[0], f) == EOF) return NULL;
         *bomtype = FILE_MBS;
         return(f);
      }
      if ((bom[0] == 0xef) && (bom[1] == 0xbb) && (bom[2]== 0xbf)) { /* UTF-8 */
         *bomtype = FILE_UTF8;
         return(f);
      }
      if ((bom[0] == 0x84) && (bom[1] == 0x31) && (bom[2]== 0x95)) {
         bom[3] = fgetc(f);
           if (ferror(f)) {
             return NULL;
          }
         if (bom[3]== 0x33) { /* GB18030 */
           *bomtype = FILE_GB18030;
           return(f);
         }
         if (ungetc(bom[3], f) == EOF) return NULL;
      }
      if (ungetc(bom[2], f) == EOF) return NULL;
      if (ungetc(bom[1], f) == EOF) return NULL;
      if (ungetc(bom[0], f) == EOF) return NULL;
      *bomtype = FILE_MBS;
      return(f);
   }
  return(f);
}

FILE *write_bom (FILE *f, CFlag *ipFlag, const char *progname)
{
  int bomtype = ipFlag->bomtype;

  if ((bomtype == FILE_MBS)&&(ipFlag->locale_target == TARGET_GB18030))
    bomtype = FILE_GB18030;

  if (ipFlag->keep_utf16)
  {
    switch (bomtype) {
      case FILE_UTF16LE:   /* UTF-16 Little Endian */
        if (fprintf(f, "%s", "\xFF\xFE") < 0) return NULL;
        if (ipFlag->verbose > 1) {
          D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
          D2U_ANSI_FPRINTF(stderr, _("Writing %s BOM.\n"), _("UTF-16LE"));
        }
        break;
      case FILE_UTF16BE:   /* UTF-16 Big Endian */
        if (fprintf(f, "%s", "\xFE\xFF") < 0) return NULL;
        if (ipFlag->verbose > 1) {
          D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
          D2U_ANSI_FPRINTF(stderr, _("Writing %s BOM.\n"), _("UTF-16BE"));
        }
        break;
      case FILE_GB18030:  /* GB18030 */
        if (fprintf(f, "%s", "\x84\x31\x95\x33") < 0) return NULL;
        if (ipFlag->verbose > 1) {
          D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
          D2U_ANSI_FPRINTF(stderr, _("Writing %s BOM.\n"), _("GB18030"));
        }
        break;
      default:      /* UTF-8 */
        if (fprintf(f, "%s", "\xEF\xBB\xBF") < 0) return NULL;
        if (ipFlag->verbose > 1) {
          D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
          D2U_ANSI_FPRINTF(stderr, _("Writing %s BOM.\n"), _("UTF-8"));
        }
      ;
    }
  } else {
    if ((bomtype == FILE_GB18030) ||
        (((bomtype == FILE_UTF16LE)||(bomtype == FILE_UTF16BE))&&(ipFlag->locale_target == TARGET_GB18030))
       ) {
        if (fprintf(f, "%s", "\x84\x31\x95\x33") < 0) return NULL; /* GB18030 */
        if (ipFlag->verbose > 1)
        {
          D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
          D2U_ANSI_FPRINTF(stderr, _("Writing %s BOM.\n"), _("GB18030"));
        }
     } else {
        if (fprintf(f, "%s", "\xEF\xBB\xBF") < 0) return NULL; /* UTF-8 */
        if (ipFlag->verbose > 1)
        {
          D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
          D2U_ANSI_FPRINTF(stderr, _("Writing %s BOM.\n"), _("UTF-8"));
        }
     }
  }
  return(f);
}

void print_bom (const int bomtype, const char *filename, const char *progname)
{
    char informat[64];

    switch (bomtype) {
    case FILE_UTF16LE:   /* UTF-16 Little Endian */
      d2u_strncpy(informat,_("UTF-16LE"),sizeof(informat));
      break;
    case FILE_UTF16BE:   /* UTF-16 Big Endian */
      d2u_strncpy(informat,_("UTF-16BE"),sizeof(informat));
      break;
    case FILE_UTF8:      /* UTF-8 */
      d2u_strncpy(informat,_("UTF-8"),sizeof(informat));
      break;
    case FILE_GB18030:      /* GB18030 */
      d2u_strncpy(informat,_("GB18030"),sizeof(informat));
      break;
    default:
    ;
  }

  if (bomtype > 0) {
#ifdef D2U_UNIFILE
    wchar_t informatw[64];
#endif
    informat[sizeof(informat)-1] = '\0';

/* Change informat to UTF-8 for d2u_utf8_fprintf. */
#ifdef D2U_UNIFILE
    /* The format string is encoded in the system default
     * Windows ANSI code page. May have been translated
     * by gettext. Convert it to wide characters. */
    d2u_MultiByteToWideChar(CP_ACP,0, informat, -1, informatw, sizeof(informat));
    /* then convert the format string to UTF-8 */
    d2u_WideCharToMultiByte(CP_UTF8, 0, informatw, -1, informat, sizeof(informat), NULL, NULL);
#endif

    D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
    D2U_UTF8_FPRINTF(stderr, _("Input file %s has %s BOM.\n"), filename, informat);
  }

}

void print_bom_info (const int bomtype)
{
/* The BOM info must not be translated to other languages, otherwise scripts
   that process the output may not work in other than English locales. */
    switch (bomtype) {
    case FILE_UTF16LE:   /* UTF-16 Little Endian */
      D2U_UTF8_FPRINTF(stdout, "  UTF-16LE");
      break;
    case FILE_UTF16BE:   /* UTF-16 Big Endian */
      D2U_UTF8_FPRINTF(stdout, "  UTF-16BE");
      break;
    case FILE_UTF8:      /* UTF-8 */
      D2U_UTF8_FPRINTF(stdout, "  UTF-8   ");
      break;
    case FILE_GB18030:   /* GB18030 */
      D2U_UTF8_FPRINTF(stdout, "  GB18030 ");
      break;
    default:
      D2U_UTF8_FPRINTF(stdout, "  no_bom  ");
    ;
  }
}

/* check_unicode_info()
 * Print assumed encoding and read file's BOM. Return file's BOM in *bomtype_orig.
 * Set ipFlag->bomtype to assumed BOM type, when file's BOM == FILE_MBS.
 * Return -1 when a read error occurred, or when whar_t < 32 bit on non-Windows OS.
 * Return 0 when everything is OK.
 */

int check_unicode_info(FILE *InF, CFlag *ipFlag, const char *progname, int *bomtype_orig)
{
#ifdef D2U_UNICODE
  if (ipFlag->verbose > 1) {
    if (ipFlag->ConvMode == CONVMODE_UTF16LE) {
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_UTF8_FPRINTF(stderr, _("Assuming UTF-16LE encoding.\n") );
    }
    if (ipFlag->ConvMode == CONVMODE_UTF16BE) {
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_UTF8_FPRINTF(stderr, _("Assuming UTF-16BE encoding.\n") );
    }
  }
#endif
  if ((InF = read_bom(InF, &ipFlag->bomtype)) == NULL) {
    d2u_getc_error(ipFlag,progname);
    return -1;
  }
  *bomtype_orig = ipFlag->bomtype;
#ifdef D2U_UNICODE
  if ((ipFlag->bomtype == FILE_MBS) && (ipFlag->ConvMode == CONVMODE_UTF16LE))
    ipFlag->bomtype = FILE_UTF16LE;
  if ((ipFlag->bomtype == FILE_MBS) && (ipFlag->ConvMode == CONVMODE_UTF16BE))
    ipFlag->bomtype = FILE_UTF16BE;


#if !defined(_WIN32) && !defined(__CYGWIN__) /* Not Windows or Cygwin */
  if (!ipFlag->keep_utf16 && ((ipFlag->bomtype == FILE_UTF16LE) || (ipFlag->bomtype == FILE_UTF16BE))) {
    if (sizeof(wchar_t) < 4) {
      /* A decoded UTF-16 surrogate pair must fit in a wchar_t */
      ipFlag->status |= WCHAR_T_TOO_SMALL ;
      if (!ipFlag->error) ipFlag->error = 1;
      return -1;
    }
  }
#endif
#endif

  return 0;
}

int check_unicode(FILE *InF, FILE *TempF,  CFlag *ipFlag, const char *ipInFN, const char *progname)
{

#ifdef D2U_UNICODE
  if (ipFlag->verbose > 1) {
    if (ipFlag->ConvMode == CONVMODE_UTF16LE) {
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_UTF8_FPRINTF(stderr, _("Assuming UTF-16LE encoding.\n") );
    }
    if (ipFlag->ConvMode == CONVMODE_UTF16BE) {
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_UTF8_FPRINTF(stderr, _("Assuming UTF-16BE encoding.\n") );
    }
  }
#endif
  if ((InF = read_bom(InF, &ipFlag->bomtype)) == NULL) {
    d2u_getc_error(ipFlag,progname);
    return -1;
  }
  if (ipFlag->verbose > 1)
    print_bom(ipFlag->bomtype, ipInFN, progname);
#ifndef D2U_UNICODE
  /* It is possible that an UTF-16 has no 8-bit binary symbols. We must stop
   * processing an UTF-16 file when UTF-16 is not supported. Don't trust on
   * finding a binary symbol.
   */
  if ((ipFlag->bomtype == FILE_UTF16LE) || (ipFlag->bomtype == FILE_UTF16BE)) {
    ipFlag->status |= UNICODE_NOT_SUPPORTED ;
    return -1;
  }
#endif
#ifdef D2U_UNICODE
  if ((ipFlag->bomtype == FILE_MBS) && (ipFlag->ConvMode == CONVMODE_UTF16LE))
    ipFlag->bomtype = FILE_UTF16LE;
  if ((ipFlag->bomtype == FILE_MBS) && (ipFlag->ConvMode == CONVMODE_UTF16BE))
    ipFlag->bomtype = FILE_UTF16BE;


#if !defined(_WIN32) && !defined(__CYGWIN__) /* Not Windows or Cygwin */
  if (!ipFlag->keep_utf16 && ((ipFlag->bomtype == FILE_UTF16LE) || (ipFlag->bomtype == FILE_UTF16BE))) {
    if (sizeof(wchar_t) < 4) {
      /* A decoded UTF-16 surrogate pair must fit in a wchar_t */
      ipFlag->status |= WCHAR_T_TOO_SMALL ;
      if (!ipFlag->error) ipFlag->error = 1;
      return -1;
    }
  }
#endif

#if !defined(__MSDOS__) && !defined(_WIN32) && !defined(__OS2__)  /* Unix, Cygwin */
  if (strcmp(nl_langinfo(CODESET), "GB18030") == 0)
    ipFlag->locale_target = TARGET_GB18030;
#endif
#endif

  if ((ipFlag->add_bom) || ((ipFlag->keep_bom) && (ipFlag->bomtype > 0)))
    if (write_bom(TempF, ipFlag, progname) == NULL) return -1;

  return 0;
}

/* convert file ipInFN and write to file ipOutFN
 * returns: 0 if success
 *         -1 otherwise
 */
int ConvertNewFile(char *ipInFN, char *ipOutFN, CFlag *ipFlag, const char *progname,
                   int (*Convert)(FILE*, FILE*, CFlag *, const char *)
#ifdef D2U_UNICODE
                 , int (*ConvertW)(FILE*, FILE*, CFlag *, const char *)
#endif
                  )
{
  int RetVal = 0;
  FILE *InF = NULL;
  FILE *TempF = NULL;
  char *TempPath;
  const char *errstr;
#ifdef D2U_UNIFILE
   struct _stat StatBuf;
   wchar_t pathw[D2U_MAX_PATH];
#else
  struct stat StatBuf;
#endif
  struct utimbuf UTimeBuf;
#ifndef NO_CHMOD
  mode_t mask;
#endif
  char *TargetFN = NULL;
  int ResolveSymlinkResult = 0;

  ipFlag->status = 0 ;

  /* Test if output file is a symbolic link */
  if (symbolic_link(ipOutFN) && !ipFlag->Follow) {
    ipFlag->status |= OUTPUTFILE_SYMLINK ;
    /* Not a failure, skipping input file according spec. (keep symbolic link unchanged) */
    return -1;
  }

  /* Test if input file is a regular file or symbolic link */
  if (regfile(ipInFN, 1, ipFlag, progname)) {
    ipFlag->status |= NO_REGFILE ;
    /* Not a failure, skipping non-regular input file according spec. */
    return -1;
  }

  /* Test if input file target is a regular file */
  if (symbolic_link(ipInFN) && regfile_target(ipInFN, ipFlag,progname)) {
    ipFlag->status |= INPUT_TARGET_NO_REGFILE ;
    /* Not a failure, skipping non-regular input file according spec. */
    return -1;
  }

  /* Test if output file target is a regular file */
  if (symbolic_link(ipOutFN) && (ipFlag->Follow == SYMLINK_FOLLOW) && regfile_target(ipOutFN, ipFlag,progname)) {
    ipFlag->status |= OUTPUT_TARGET_NO_REGFILE ;
    /* Failure, input is regular, cannot produce output. */
    if (!ipFlag->error) ipFlag->error = 1;
    return -1;
  }

  /* retrieve ipInFN file date stamp */
#ifdef D2U_UNIFILE
  d2u_MultiByteToWideChar(CP_UTF8, 0, ipInFN, -1, pathw, D2U_MAX_PATH);
  if (_wstat(pathw, &StatBuf)) {
#else
  if (stat(ipInFN, &StatBuf)) {
#endif
    if (ipFlag->verbose) {
      ipFlag->error = errno;
      errstr = strerror(errno);
      D2U_UTF8_FPRINTF(stderr, "%s: %s:", progname, ipInFN);
      D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
    }
    return -1;
  }

  /* can open in file? */
  InF=OpenInFile(ipInFN);
  if (InF == NULL) {
    if (ipFlag->verbose) {
      ipFlag->error = errno;
      errstr = strerror(errno);
      D2U_UTF8_FPRINTF(stderr, "%s: %s:", progname, ipInFN);
      D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
    }
    return -1;
  }

  /* If output file is a symbolic link, optional resolve the link and modify  */
  /* the target, instead of removing the link and creating a new regular file */
  TargetFN = ipOutFN;
  if (symbolic_link(ipOutFN) && !RetVal) {
    ResolveSymlinkResult = 0; /* indicates that TargetFN need not be freed */
    if (ipFlag->Follow == SYMLINK_FOLLOW) {
      ResolveSymlinkResult = ResolveSymbolicLink(ipOutFN, &TargetFN, ipFlag, progname);
      if (ResolveSymlinkResult < 0) {
        if (ipFlag->verbose) {
          D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
          D2U_UTF8_FPRINTF(stderr, _("problems resolving symbolic link '%s'\n"), ipOutFN);
          D2U_UTF8_FPRINTF(stderr, _("          output file remains in '%s'\n"), TempPath);
        }
        RetVal = -1;
      }
    }
  }
  /* The symbolic link's target could be on another file system. rename() used below
   * can't move files to another file system. We need to create the temp file on the
   * target file system.
   */

  /* can open temp output file? */
  if((TempF = MakeTempFileFrom(TargetFN, &TempPath))==NULL) {
    if (ipFlag->verbose) {
      if (errno) {
        ipFlag->error = errno;
        errstr = strerror(errno);
        D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
        D2U_ANSI_FPRINTF(stderr, _("Failed to open temporary output file: %s\n"), errstr);
      } else {
        /*  In case temp path was too long on Windows, errno is 0. */
        if (!ipFlag->error) ipFlag->error = 1;
      }
    }
    RetVal = -1;
  }

#if DEBUG
  if (TempPath != NULL) {
    D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
    D2U_UTF8_FPRINTF(stderr, _("using %s as temporary file\n"), TempPath);
  }
#endif

  if (!RetVal)
    if (check_unicode(InF, TempF, ipFlag, ipInFN, progname))
      RetVal = -1;

  /* conversion successful? */
#ifdef D2U_UNICODE
  if ((ipFlag->bomtype == FILE_UTF16LE) || (ipFlag->bomtype == FILE_UTF16BE)) {
    if ((!RetVal) && (ConvertW(InF, TempF, ipFlag, progname)))
      RetVal = -1;
    if (ipFlag->status & UNICODE_CONVERSION_ERROR) {
      if (!ipFlag->error) ipFlag->error = 1;
      RetVal = -1;
    }
  } else {
    if ((!RetVal) && (Convert(InF, TempF, ipFlag, progname)))
      RetVal = -1;
  }
#else
  if ((!RetVal) && (Convert(InF, TempF, ipFlag, progname)))
    RetVal = -1;
#endif

   /* can close in file? */
  if (d2u_fclose(InF, ipInFN, ipFlag, "r", progname) == EOF)
    RetVal = -1;

  /* can close output file? */
  if (TempF) {
    if (d2u_fclose(TempF, TempPath, ipFlag, "w", progname) == EOF)
      RetVal = -1;
  }

#ifndef NO_CHMOD
  if (!RetVal)
  {
    if (ipFlag->NewFile == 0) { /* old-file mode */
       RetVal = chmod (TempPath, StatBuf.st_mode); /* set original permissions */
    } else {
       mask = umask(0); /* get process's umask */
       umask(mask); /* set umask back to original */
       RetVal = chmod(TempPath, StatBuf.st_mode & ~mask); /* set original permissions, minus umask */
    }

    if (RetVal) {
       if (ipFlag->verbose) {
         ipFlag->error = errno;
         errstr = strerror(errno);
         D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
         D2U_UTF8_FPRINTF(stderr, _("Failed to change the permissions of temporary output file %s:"), TempPath);
         D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
       }
    }
  }
#endif

#ifndef NO_CHOWN
  if (!RetVal && (ipFlag->NewFile == 0)) { /* old-file mode */
     /* Change owner and group of the temporary output file to the original file's uid and gid. */
     /* Required when a different user (e.g. root) has write permission on the original file. */
     /* Make sure that the original owner can still access the file. */
     if (chown(TempPath, StatBuf.st_uid, StatBuf.st_gid)) {
        if (ipFlag->AllowChown) {
          if (ipFlag->verbose) {
            D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
            D2U_UTF8_FPRINTF(stderr, _("The user and/or group ownership of file %s is not preserved.\n"), ipOutFN);
          }
#ifndef NO_CHMOD
          /* Set read/write permissions same as in new file mode. */
          mask = umask(0); /* get process's umask */
          umask(mask); /* set umask back to original */
          RetVal = chmod(TempPath, StatBuf.st_mode & ~mask); /* set original permissions, minus umask */
          if (RetVal) {
             if (ipFlag->verbose) {
               ipFlag->error = errno;
               errstr = strerror(errno);
               D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
               D2U_UTF8_FPRINTF(stderr, _("Failed to change the permissions of temporary output file %s:"), TempPath);
               D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
             }
          }
#endif
        } else {
          if (ipFlag->verbose) {
            ipFlag->error = errno;
            errstr = strerror(errno);
            D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
            D2U_UTF8_FPRINTF(stderr, _("Failed to change the owner and group of temporary output file %s:"), TempPath);
            D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
          }
          RetVal = -1;
        }
     }
  }
#endif

  if ((!RetVal) && (ipFlag->KeepDate))
  {
    UTimeBuf.actime = StatBuf.st_atime;
    UTimeBuf.modtime = StatBuf.st_mtime;
    /* can change output file time to in file time? */
    if (utime(TempPath, &UTimeBuf) == -1) {
      if (ipFlag->verbose) {
        ipFlag->error = errno;
        errstr = strerror(errno);
        D2U_UTF8_FPRINTF(stderr, "%s: %s:", progname, TempPath);
        D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
      }
      RetVal = -1;
    }
  }

  /* any error? cleanup the temp file */
  if (RetVal && (TempPath != NULL)) {
    if (d2u_unlink(TempPath) && (errno != ENOENT)) {
      if (ipFlag->verbose) {
        ipFlag->error = errno;
        errstr = strerror(errno);
        D2U_UTF8_FPRINTF(stderr, "%s: %s:", progname, TempPath);
        D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
      }
      RetVal = -1;
    }
  }

  /* can rename temporary file to output file? */
  if (!RetVal) {
#ifdef NEED_REMOVE
    if (d2u_unlink(TargetFN) && (errno != ENOENT)) {
      if (ipFlag->verbose) {
        ipFlag->error = errno;
        errstr = strerror(errno);
        D2U_UTF8_FPRINTF(stderr, "%s: %s:", progname, TargetFN);
        D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
      }
      RetVal = -1;
    }
#endif

    if (d2u_rename(TempPath, TargetFN) != 0) {
      if (ipFlag->verbose) {
        ipFlag->error = errno;
        errstr = strerror(errno);
        D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
        D2U_UTF8_FPRINTF(stderr, _("problems renaming '%s' to '%s':"), TempPath, TargetFN);
        D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
#ifdef S_ISLNK
        if (ResolveSymlinkResult > 0)
          D2U_UTF8_FPRINTF(stderr, _("          which is the target of symbolic link '%s'\n"), ipOutFN);
#endif
        D2U_UTF8_FPRINTF(stderr, _("          output file remains in '%s'\n"), TempPath);
      }
      RetVal = -1;
    }

    if (ResolveSymlinkResult > 0)
      free(TargetFN);
  }
  free(TempPath);
  return RetVal;
}

/* convert file ipInFN and write to file ipOutFN
 * returns: 0 if success
 *         -1 otherwise
 */
int ConvertToStdout(char *ipInFN, CFlag *ipFlag, const char *progname,
                   int (*Convert)(FILE*, FILE*, CFlag *, const char *)
#ifdef D2U_UNICODE
                 , int (*ConvertW)(FILE*, FILE*, CFlag *, const char *)
#endif
                  )
{
  int RetVal = 0;
  FILE *InF = NULL;
  const char *errstr;

  ipFlag->status = 0 ;

  /* Test if input file is a regular file or symbolic link */
  if (regfile(ipInFN, 1, ipFlag, progname)) {
    ipFlag->status |= NO_REGFILE ;
    /* Not a failure, skipping non-regular input file according spec. */
    return -1;
  }

  /* Test if input file target is a regular file */
  if (symbolic_link(ipInFN) && regfile_target(ipInFN, ipFlag,progname)) {
    ipFlag->status |= INPUT_TARGET_NO_REGFILE ;
    /* Not a failure, skipping non-regular input file according spec. */
    return -1;
  }

  /* can open in file? */
  InF=OpenInFile(ipInFN);
  if (InF == NULL) {
    if (ipFlag->verbose) {
      ipFlag->error = errno;
      errstr = strerror(errno);
      D2U_UTF8_FPRINTF(stderr, "%s: %s:", progname, ipInFN);
      D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
    }
    return -1;
  }

#if defined(_WIN32) && !defined(__CYGWIN__)

    /* stdin and stdout are by default text streams. We need
     * to set them to binary mode. Otherwise an LF will
     * automatically be converted to CR-LF on DOS/Windows.
     * Erwin */

    /* POSIX 'setmode' was deprecated by MicroSoft since
     * Visual C++ 2005. Use ISO C++ conformant '_setmode' instead. */

    _setmode(_fileno(stdout), _O_BINARY);
#elif defined(__MSDOS__) || defined(__CYGWIN__) || defined(__OS2__)
    setmode(fileno(stdout), O_BINARY);
#endif

  if (!RetVal)
    if (check_unicode(InF, stdout, ipFlag, ipInFN, progname))
      RetVal = -1;

  /* conversion successful? */
#ifdef D2U_UNICODE
  if ((ipFlag->bomtype == FILE_UTF16LE) || (ipFlag->bomtype == FILE_UTF16BE)) {
    if ((!RetVal) && (ConvertW(InF, stdout, ipFlag, progname)))
      RetVal = -1;
    if (ipFlag->status & UNICODE_CONVERSION_ERROR) {
      if (!ipFlag->error) ipFlag->error = 1;
      RetVal = -1;
    }
  } else {
    if ((!RetVal) && (Convert(InF, stdout, ipFlag, progname)))
      RetVal = -1;
  }
#else
  if ((!RetVal) && (Convert(InF, stdout, ipFlag, progname)))
    RetVal = -1;
#endif

   /* can close in file? */
  if (d2u_fclose(InF, ipInFN, ipFlag, "r", progname) == EOF)
    RetVal = -1;

  return RetVal;
}

/* convert stdin and write to stdout
 * returns: 0 if success
 *         -1 otherwise
 */
int ConvertStdio(CFlag *ipFlag, const char *progname,
                   int (*Convert)(FILE*, FILE*, CFlag *, const char *)
#ifdef D2U_UNICODE
                 , int (*ConvertW)(FILE*, FILE*, CFlag *, const char *)
#endif
                  )
{
    ipFlag->NewFile = 1;
    ipFlag->KeepDate = 0;

#if defined(_WIN32) && !defined(__CYGWIN__)

    /* stdin and stdout are by default text streams. We need
     * to set them to binary mode. Otherwise an LF will
     * automatically be converted to CR-LF on DOS/Windows.
     * Erwin */

    /* POSIX 'setmode' was deprecated by MicroSoft since
     * Visual C++ 2005. Use ISO C++ conformant '_setmode' instead. */

    _setmode(_fileno(stdout), _O_BINARY);
    _setmode(_fileno(stdin), _O_BINARY);
#elif defined(__MSDOS__) || defined(__CYGWIN__) || defined(__OS2__)
    setmode(fileno(stdout), O_BINARY);
    setmode(fileno(stdin), O_BINARY);
#endif

    if (check_unicode(stdin, stdout, ipFlag, "stdin", progname))
        return -1;

#ifdef D2U_UNICODE
    if ((ipFlag->bomtype == FILE_UTF16LE) || (ipFlag->bomtype == FILE_UTF16BE)) {
        return ConvertW(stdin, stdout, ipFlag, progname);
    } else {
        return Convert(stdin, stdout, ipFlag, progname);
    }
#else
    return Convert(stdin, stdout, ipFlag, progname);
#endif
}

void print_messages_stdio(const CFlag *pFlag, const char *progname)
{
    if (pFlag->status & BINARY_FILE) {
      D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
      D2U_UTF8_FPRINTF(stderr, _("Skipping binary file %s\n"), "stdin");
    } else if (pFlag->status & WRONG_CODEPAGE) {
      D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
      D2U_UTF8_FPRINTF(stderr, _("code page %d is not supported.\n"), pFlag->ConvMode);
#ifdef D2U_UNICODE
    } else if (pFlag->status & WCHAR_T_TOO_SMALL) {
      D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
      D2U_UTF8_FPRINTF(stderr, _("Skipping UTF-16 file %s, the size of wchar_t is %d bytes.\n"), "stdin", (int)sizeof(wchar_t));
    } else if (pFlag->status & UNICODE_CONVERSION_ERROR) {
      D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
      D2U_UTF8_FPRINTF(stderr, _("Skipping UTF-16 file %s, an UTF-16 conversion error occurred on line %u.\n"), "stdin", pFlag->line_nr);
#else
    } else if (pFlag->status & UNICODE_NOT_SUPPORTED) {
      D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
      D2U_UTF8_FPRINTF(stderr, _("Skipping UTF-16 file %s, UTF-16 conversion is not supported in this version of %s.\n"), "stdin", progname);
#endif
    }
}

void print_format(const CFlag *pFlag, char *informat, char *outformat, size_t lin, size_t lout)
{
  informat[0]='\0';
  outformat[0]='\0';

  if (pFlag->bomtype == FILE_UTF16LE)
    d2u_strncpy(informat,_("UTF-16LE"),lin);
  if (pFlag->bomtype == FILE_UTF16BE)
    d2u_strncpy(informat,_("UTF-16BE"),lin);
  informat[lin-1]='\0';

#ifdef D2U_UNICODE
  if ((pFlag->bomtype == FILE_UTF16LE)||(pFlag->bomtype == FILE_UTF16BE)) {
#if !defined(__MSDOS__) && !defined(_WIN32) && !defined(__OS2__)  /* Unix, Cygwin */
    d2u_strncpy(outformat,nl_langinfo(CODESET),lout);
#endif

#if defined(_WIN32) && !defined(__CYGWIN__) /* Windows, not Cygwin */
    if (pFlag->locale_target == TARGET_GB18030)
      d2u_strncpy(outformat, _("GB18030"),lout);
    else
      d2u_strncpy(outformat, _("UTF-8"),lout);
#endif

    if (pFlag->keep_utf16)
    {
      if (pFlag->bomtype == FILE_UTF16LE)
        d2u_strncpy(outformat,_("UTF-16LE"),lout);
      if (pFlag->bomtype == FILE_UTF16BE)
        d2u_strncpy(outformat,_("UTF-16BE"),lout);
    }
    outformat[lout-1]='\0';
  }
#endif
}

void print_messages(const CFlag *pFlag, const char *infile, const char *outfile, const char *progname, const int conversion_error)
{
  char informat[32];
  char outformat[64];
# ifdef D2U_UNIFILE
  wchar_t informatw[32];
  wchar_t outformatw[64];
#endif

  print_format(pFlag, informat, outformat, sizeof(informat), sizeof(outformat));

/* Change informat and outformat to UTF-8 for d2u_utf8_fprintf. */
# ifdef D2U_UNIFILE
   /* The format string is encoded in the system default
    * Windows ANSI code page. May have been translated
    * by gettext. Convert it to wide characters. */
   d2u_MultiByteToWideChar(CP_ACP,0, informat, -1, informatw, sizeof(informat));
   d2u_MultiByteToWideChar(CP_ACP,0, outformat, -1, outformatw, sizeof(outformat));
   /* then convert the format string to UTF-8 */
   d2u_WideCharToMultiByte(CP_UTF8, 0, informatw, -1, informat, sizeof(informat), NULL, NULL);
   d2u_WideCharToMultiByte(CP_UTF8, 0, outformatw, -1, outformat, sizeof(outformat), NULL, NULL);
#endif

  if (pFlag->status & NO_REGFILE) {
    D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
    D2U_UTF8_FPRINTF(stderr, _("Skipping %s, not a regular file.\n"), infile);
  } else if (pFlag->status & OUTPUTFILE_SYMLINK) {
    D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
    if (outfile)
      D2U_UTF8_FPRINTF(stderr, _("Skipping %s, output file %s is a symbolic link.\n"), infile, outfile);
    else
      D2U_UTF8_FPRINTF(stderr, _("Skipping symbolic link %s.\n"), infile);
  } else if (pFlag->status & INPUT_TARGET_NO_REGFILE) {
    D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
    D2U_UTF8_FPRINTF(stderr, _("Skipping symbolic link %s, target is not a regular file.\n"), infile);
  } else if ((pFlag->status & OUTPUT_TARGET_NO_REGFILE) && outfile) {
    D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
    D2U_UTF8_FPRINTF(stderr, _("Skipping %s, target of symbolic link %s is not a regular file.\n"), infile, outfile);
  } else if (pFlag->status & BINARY_FILE) {
    D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
    D2U_UTF8_FPRINTF(stderr, _("Skipping binary file %s\n"), infile);
  } else if (pFlag->status & WRONG_CODEPAGE) {
    D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
    D2U_UTF8_FPRINTF(stderr, _("code page %d is not supported.\n"), pFlag->ConvMode);
#ifdef D2U_UNICODE
  } else if (pFlag->status & WCHAR_T_TOO_SMALL) {
    D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
    D2U_UTF8_FPRINTF(stderr, _("Skipping UTF-16 file %s, the size of wchar_t is %d bytes.\n"), infile, (int)sizeof(wchar_t));
  } else if (pFlag->status & UNICODE_CONVERSION_ERROR) {
    D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
    D2U_UTF8_FPRINTF(stderr, _("Skipping UTF-16 file %s, an UTF-16 conversion error occurred on line %u.\n"), infile, pFlag->line_nr);
#else
  } else if (pFlag->status & UNICODE_NOT_SUPPORTED) {
    D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
    D2U_UTF8_FPRINTF(stderr, _("Skipping UTF-16 file %s, UTF-16 conversion is not supported in this version of %s.\n"), infile, progname);
#endif
  } else {
    if (!conversion_error) {
      D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
      if (informat[0] == '\0') {
        if (is_dos2unix(progname)) {
          if (outfile)
            D2U_UTF8_FPRINTF(stderr, _("converting file %s to file %s in Unix format...\n"), infile, outfile);
          else
            D2U_UTF8_FPRINTF(stderr, _("converting file %s to Unix format...\n"), infile);
        } else {
          if (pFlag->FromToMode == FROMTO_UNIX2MAC) {
            if (outfile)
              D2U_UTF8_FPRINTF(stderr, _("converting file %s to file %s in Mac format...\n"), infile, outfile);
            else
              D2U_UTF8_FPRINTF(stderr, _("converting file %s to Mac format...\n"), infile);
          } else {
            if (outfile)
              D2U_UTF8_FPRINTF(stderr, _("converting file %s to file %s in DOS format...\n"), infile, outfile);
            else
              D2U_UTF8_FPRINTF(stderr, _("converting file %s to DOS format...\n"), infile);
          }
        }
      } else {
        if (is_dos2unix(progname)) {
          if (outfile)
    /* TRANSLATORS:
1st %s is encoding of input file.
2nd %s is name of input file.
3rd %s is encoding of output file.
4th %s is name of output file.
E.g.: converting UTF-16LE file in.txt to UTF-8 file out.txt in Unix format... */
            D2U_UTF8_FPRINTF(stderr, _("converting %s file %s to %s file %s in Unix format...\n"), informat, infile, outformat, outfile);
          else
    /* TRANSLATORS:
1st %s is encoding of input file.
2nd %s is name of input file.
3rd %s is encoding of output (input file is overwritten).
E.g.: converting UTF-16LE file foo.txt to UTF-8 Unix format... */
            D2U_UTF8_FPRINTF(stderr, _("converting %s file %s to %s Unix format...\n"), informat, infile, outformat);
        } else {
          if (pFlag->FromToMode == FROMTO_UNIX2MAC) {
            if (outfile)
              D2U_UTF8_FPRINTF(stderr, _("converting %s file %s to %s file %s in Mac format...\n"), informat, infile, outformat, outfile);
            else
              D2U_UTF8_FPRINTF(stderr, _("converting %s file %s to %s Mac format...\n"), informat, infile, outformat);
          } else {
            if (outfile)
              D2U_UTF8_FPRINTF(stderr, _("converting %s file %s to %s file %s in DOS format...\n"), informat, infile, outformat, outfile);
            else
              D2U_UTF8_FPRINTF(stderr, _("converting %s file %s to %s DOS format...\n"), informat, infile, outformat);
          }
        }
      }
    } else {
      D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
      if (outfile)
        D2U_UTF8_FPRINTF(stderr, _("problems converting file %s to file %s\n"), infile, outfile);
      else
        D2U_UTF8_FPRINTF(stderr, _("problems converting file %s\n"), infile);
    }
  }
}

void print_messages_info(const CFlag *pFlag, const char *infile, const char *progname)
{
  if (pFlag->status & NO_REGFILE) {
    if (pFlag->verbose) {
      D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
      D2U_UTF8_FPRINTF(stderr, _("Skipping %s, not a regular file.\n"), infile);
    }
  } else if (pFlag->status & INPUT_TARGET_NO_REGFILE) {
    if (pFlag->verbose) {
      D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
      D2U_UTF8_FPRINTF(stderr, _("Skipping symbolic link %s, target is not a regular file.\n"), infile);
    }
#ifdef D2U_UNICODE
  } else if (pFlag->status & WCHAR_T_TOO_SMALL) {
    if (pFlag->verbose) {
      D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
      D2U_UTF8_FPRINTF(stderr, _("Skipping UTF-16 file %s, the size of wchar_t is %d bytes.\n"), infile, (int)sizeof(wchar_t));
    }
#endif
  }
}

void printInfo(CFlag *ipFlag, const char *filename, int bomtype, unsigned int lb_dos, unsigned int lb_unix, unsigned int lb_mac)
{
  static int header_done = 0;

  if (ipFlag->file_info & INFO_CONVERT) {
    if ((ipFlag->FromToMode == FROMTO_DOS2UNIX) && (lb_dos == 0))
      return;
    if (((ipFlag->FromToMode == FROMTO_UNIX2DOS)||(ipFlag->FromToMode == FROMTO_UNIX2MAC)) && (lb_unix == 0))
      return;
    if ((ipFlag->FromToMode == FROMTO_MAC2UNIX) && (lb_mac == 0))
      return;
    if ((ipFlag->Force == 0) && (ipFlag->status & BINARY_FILE))
      return;
  }

  if ((ipFlag->file_info & INFO_HEADER) && (! header_done)) {
    if (ipFlag->file_info & INFO_DOS)
      D2U_UTF8_FPRINTF(stdout, "     DOS");
    if (ipFlag->file_info & INFO_UNIX)
      D2U_UTF8_FPRINTF(stdout, "    UNIX");
    if (ipFlag->file_info & INFO_MAC)
      D2U_UTF8_FPRINTF(stdout, "     MAC");
    if (ipFlag->file_info & INFO_BOM)
      D2U_UTF8_FPRINTF(stdout, "  BOM     ");
    if (ipFlag->file_info & INFO_TEXT)
      D2U_UTF8_FPRINTF(stdout, "  TXTBIN");
    if (*filename != '\0') {
      if (ipFlag->file_info & INFO_DEFAULT)
        D2U_UTF8_FPRINTF(stdout, "  ");
      D2U_UTF8_FPRINTF(stdout, "FILE");
    }
    if (ipFlag->file_info & INFO_PRINT0)
      (void) fputc(0, stdout);
    else
      D2U_UTF8_FPRINTF(stdout, "\n");
    header_done = 1;
  }

  if (ipFlag->file_info & INFO_DOS)
    D2U_UTF8_FPRINTF(stdout, "  %6u", lb_dos);
  if (ipFlag->file_info & INFO_UNIX)
    D2U_UTF8_FPRINTF(stdout, "  %6u", lb_unix);
  if (ipFlag->file_info & INFO_MAC)
    D2U_UTF8_FPRINTF(stdout, "  %6u", lb_mac);
  if (ipFlag->file_info & INFO_BOM)
    print_bom_info(bomtype);
  if (ipFlag->file_info & INFO_TEXT) {
    if (ipFlag->status & BINARY_FILE)
      D2U_UTF8_FPRINTF(stdout, "  binary");
    else
      D2U_UTF8_FPRINTF(stdout, "  text  ");
  }
  if (*filename != '\0') {
    const char *ptr;
    if ((ipFlag->file_info & INFO_NOPATH) && (((ptr=strrchr(filename,'/')) != NULL) || ((ptr=strrchr(filename,'\\')) != NULL)) )
      ptr++;
    else
      ptr = filename;
    if (ipFlag->file_info & INFO_DEFAULT)
      D2U_UTF8_FPRINTF(stdout, "  ");
    D2U_UTF8_FPRINTF(stdout, "%s",ptr);
  }
  if (ipFlag->file_info & INFO_PRINT0)
    (void) fputc(0, stdout);
  else
    D2U_UTF8_FPRINTF(stdout, "\n");
}

#ifdef D2U_UNICODE
void FileInfoW(FILE* ipInF, CFlag *ipFlag, const char *filename, int bomtype, const char *progname)
{
  wint_t TempChar;
  wint_t PreviousChar = 0;
  unsigned int lb_dos = 0;
  unsigned int lb_unix = 0;
  unsigned int lb_mac = 0;

  ipFlag->status = 0;

  while ((TempChar = d2u_getwc(ipInF, ipFlag->bomtype)) != WEOF) {
    if ( (TempChar < 32) &&
        (TempChar != 0x0a) &&  /* Not an LF */
        (TempChar != 0x0d) &&  /* Not a CR */
        (TempChar != 0x09) &&  /* Not a TAB */
        (TempChar != 0x0c)) {  /* Not a form feed */
      ipFlag->status |= BINARY_FILE ;
    }
    if (TempChar != 0x0a) { /* Not an LF */
      PreviousChar = TempChar;
      if (TempChar == 0x0d) /* CR */
        lb_mac++;
    } else{
      /* TempChar is an LF */
      if ( PreviousChar == 0x0d ) { /* CR,LF pair. */
        lb_dos++;
        lb_mac--;
        PreviousChar = TempChar;
        continue;
      }
      PreviousChar = TempChar;
      lb_unix++; /* Unix line end (LF). */
    }
  }
  if ((TempChar == WEOF) && ferror(ipInF)) {
    ipFlag->error = errno;
    if (ipFlag->verbose) {
      const char *errstr = strerror(errno);
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_UTF8_FPRINTF(stderr, _("can not read from input file %s:"), filename);
      D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
    }
    return;
  }

  printInfo(ipFlag, filename, bomtype, lb_dos, lb_unix, lb_mac);

}
#endif

void FileInfo(FILE* ipInF, CFlag *ipFlag, const char *filename, int bomtype, const char *progname)
{
  int TempChar;
  int PreviousChar = 0;
  unsigned int lb_dos = 0;
  unsigned int lb_unix = 0;
  unsigned int lb_mac = 0;

  ipFlag->status = 0;

  while ((TempChar = fgetc(ipInF)) != EOF) {
    if ( (TempChar < 32) &&
        (TempChar != '\x0a') &&  /* Not an LF */
        (TempChar != '\x0d') &&  /* Not a CR */
        (TempChar != '\x09') &&  /* Not a TAB */
        (TempChar != '\x0c')) {  /* Not a form feed */
      ipFlag->status |= BINARY_FILE ;
      }
    if (TempChar != '\x0a') { /* Not an LF */
      PreviousChar = TempChar;
      if (TempChar == '\x0d') /* CR */
        lb_mac++;
    } else {
      /* TempChar is an LF */
      if ( PreviousChar == '\x0d' ) { /* CR,LF pair. */
        lb_dos++;
        lb_mac--;
        PreviousChar = TempChar;
        continue;
      }
      PreviousChar = TempChar;
      lb_unix++; /* Unix line end (LF). */
    }
  }
  if ((TempChar == EOF) && ferror(ipInF)) {
    ipFlag->error = errno;
    if (ipFlag->verbose) {
      const char *errstr = strerror(errno);
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_UTF8_FPRINTF(stderr, _("can not read from input file %s:"), filename);
      D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
    }
    return;
  }

  printInfo(ipFlag, filename, bomtype, lb_dos, lb_unix, lb_mac);
}

int GetFileInfo(char *ipInFN, CFlag *ipFlag, const char *progname)
{
  FILE *InF = NULL;
  int bomtype_orig = FILE_MBS; /* messages must print the real bomtype, not the assumed bomtype */

  ipFlag->status = 0 ;

  /* Test if input file is a regular file or symbolic link */
  if (regfile(ipInFN, 1, ipFlag, progname)) {
    ipFlag->status |= NO_REGFILE ;
    /* Not a failure, skipping non-regular input file according spec. */
    return -1;
  }

  /* Test if input file target is a regular file */
  if (symbolic_link(ipInFN) && regfile_target(ipInFN, ipFlag,progname)) {
    ipFlag->status |= INPUT_TARGET_NO_REGFILE ;
    /* Not a failure, skipping non-regular input file according spec. */
    return -1;
  }


  /* can open in file? */
  InF=OpenInFile(ipInFN);
  if (InF == NULL) {
    if (ipFlag->verbose) {
      const char *errstr = strerror(errno);
      ipFlag->error = errno;
      D2U_UTF8_FPRINTF(stderr, "%s: %s: ", progname, ipInFN);
      D2U_ANSI_FPRINTF(stderr, "%s\n", errstr);
    }
    return -1;
  }


  if (check_unicode_info(InF, ipFlag, progname, &bomtype_orig)) {
    d2u_fclose(InF, ipInFN, ipFlag, "r", progname);
    return -1;
  }

  /* info successful? */
#ifdef D2U_UNICODE
  if ((ipFlag->bomtype == FILE_UTF16LE) || (ipFlag->bomtype == FILE_UTF16BE)) {
    FileInfoW(InF, ipFlag, ipInFN, bomtype_orig, progname);
  } else {
    FileInfo(InF, ipFlag, ipInFN, bomtype_orig, progname);
  }
#else
  FileInfo(InF, ipFlag, ipInFN, bomtype_orig, progname);
#endif

  /* can close in file? */
  if (d2u_fclose(InF, ipInFN, ipFlag, "r", progname) == EOF)
    return -1;

  return 0;
}

int GetFileInfoStdio(CFlag *ipFlag, const char *progname)
{
  int bomtype_orig = FILE_MBS; /* messages must print the real bomtype, not the assumed bomtype */

  ipFlag->status = 0 ;

#if defined(_WIN32) && !defined(__CYGWIN__)

    /* stdin and stdout are by default text streams. We need
     * to set them to binary mode. Otherwise an LF will
     * automatically be converted to CR-LF on DOS/Windows.
     * Erwin */

    /* POSIX 'setmode' was deprecated by MicroSoft since
     * Visual C++ 2005. Use ISO C++ conformant '_setmode' instead. */

    _setmode(_fileno(stdin), _O_BINARY);
#elif defined(__MSDOS__) || defined(__CYGWIN__) || defined(__OS2__)
    setmode(fileno(stdin), O_BINARY);
#endif

  if (check_unicode_info(stdin, ipFlag, progname, &bomtype_orig))
    return -1;

  /* info successful? */
#ifdef D2U_UNICODE
  if ((ipFlag->bomtype == FILE_UTF16LE) || (ipFlag->bomtype == FILE_UTF16BE)) {
    FileInfoW(stdin, ipFlag, "", bomtype_orig, progname);
  } else {
    FileInfo(stdin, ipFlag, "", bomtype_orig, progname);
  }
#else
  FileInfo(stdin, ipFlag, "", bomtype_orig, progname);
#endif

  return 0;
}

void get_info_options(char *option, CFlag *pFlag, const char *progname)
{
  char *ptr;
  int default_info = 1;

  ptr = option;

  if (*ptr == '\0') { /* no flags */
    pFlag->file_info |= INFO_DEFAULT;
    return;
  }

  while (*ptr != '\0') {
    switch (*ptr) {
      case '0':   /* Print null characters instead of newline characters. */
        pFlag->file_info |= INFO_PRINT0;
        break;
      case 'd':   /* Print nr of DOS line breaks. */
        pFlag->file_info |= INFO_DOS;
        default_info = 0;
        break;
      case 'u':   /* Print nr of Unix line breaks. */
        pFlag->file_info |= INFO_UNIX;
        default_info = 0;
        break;
      case 'm':   /* Print nr of Mac line breaks. */
        pFlag->file_info |= INFO_MAC;
        default_info = 0;
        break;
      case 'b':   /* Print BOM. */
        pFlag->file_info |= INFO_BOM;
        default_info = 0;
        break;
      case 't':   /* Text or binary. */
        pFlag->file_info |= INFO_TEXT;
        default_info = 0;
        break;
      case 'c':   /* Print only files that would be converted. */
        pFlag->file_info |= INFO_CONVERT;
        default_info = 0;
        break;
      case 'h':   /* Print a header. */
        pFlag->file_info |= INFO_HEADER;
        break;
      case 'p':   /* Remove path from file names. */
        pFlag->file_info |= INFO_NOPATH;
        break;
      default:
       /* Terminate the program on a wrong option. If pFlag->file_info is
          zero and the program goes on, it may do unwanted conversions. */
        D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
        D2U_UTF8_FPRINTF(stderr,_("wrong flag '%c' for option -i or --info\n"), *ptr);
        exit(1);
      ;
    }
    ptr++;
  }
  if (default_info)
    pFlag->file_info |= INFO_DEFAULT;
}

int parse_options(int argc, char *argv[],
                  CFlag *pFlag, const char *localedir, const char *progname,
                  void (*PrintLicense)(void),
                  int (*Convert)(FILE*, FILE*, CFlag *, const char *)
#ifdef D2U_UNICODE
                , int (*ConvertW)(FILE*, FILE*, CFlag *, const char *)
#endif
                  )
{
  int ArgIdx = 0;
  int ShouldExit = 0;
  int CanSwitchFileMode = 1;
  int process_options = 1;
#ifdef D2U_UNIFILE
  char *ptr;
#endif

  /* variable initialisations */
  pFlag->NewFile = 0;
  pFlag->verbose = 1;
  pFlag->KeepDate = 0;
  pFlag->ConvMode = CONVMODE_ASCII;  /* default ascii */
  pFlag->NewLine = 0;
  pFlag->Force = 0;
  pFlag->Follow = SYMLINK_SKIP;
  pFlag->status = 0;
  pFlag->stdio_mode = 1;
  pFlag->to_stdout = 0;
  pFlag->error = 0;
  pFlag->bomtype = FILE_MBS;
  pFlag->add_bom = 0;
  pFlag->keep_utf16 = 0;
  pFlag->file_info = 0;
  pFlag->locale_target = TARGET_UTF8;
  pFlag->add_eol = 0;

#ifdef D2U_UNIFILE
   ptr = getenv("DOS2UNIX_DISPLAY_ENC");
   if (ptr != NULL) {
      if (strncmp(ptr, "ansi", sizeof("ansi")) == 0)
         d2u_display_encoding = D2U_DISPLAY_ANSI;
      else if (strncmp(ptr, "unicode", sizeof("unicode")) == 0)
         d2u_display_encoding = D2U_DISPLAY_UNICODE;
      else if (strncmp(ptr, "unicodebom", sizeof("unicodebom")) == 0)
         d2u_display_encoding = D2U_DISPLAY_UNICODEBOM;
      else if (strncmp(ptr, "utf8", sizeof("utf8")) == 0)
         d2u_display_encoding = D2U_DISPLAY_UTF8;
      else if (strncmp(ptr, "utf8bom", sizeof("utf8bom")) == 0)
         d2u_display_encoding = D2U_DISPLAY_UTF8BOM;
   }
#endif

  while ((++ArgIdx < argc) && (!ShouldExit))
  {
    /* is it an option? */
    if ((argv[ArgIdx][0] == '-') && process_options)
    {
      /* an option */
      if (strcmp(argv[ArgIdx],"--") == 0)
        process_options = 0;
      else if ((strcmp(argv[ArgIdx],"-h") == 0) || (strcmp(argv[ArgIdx],"--help") == 0))
      {
        PrintUsage(progname);
        return(pFlag->error);
      }
      else if ((strcmp(argv[ArgIdx],"-b") == 0) || (strcmp(argv[ArgIdx],"--keep-bom") == 0))
        pFlag->keep_bom = 1;
      else if ((strcmp(argv[ArgIdx],"-k") == 0) || (strcmp(argv[ArgIdx],"--keepdate") == 0))
        pFlag->KeepDate = 1;
      else if ((strcmp(argv[ArgIdx],"-e") == 0) || (strcmp(argv[ArgIdx],"--add-eol") == 0))
        pFlag->add_eol = 1;
      else if (strcmp(argv[ArgIdx],"--no-add-eol") == 0)
        pFlag->add_eol = 0;
      else if ((strcmp(argv[ArgIdx],"-f") == 0) || (strcmp(argv[ArgIdx],"--force") == 0))
        pFlag->Force = 1;
#ifndef NO_CHOWN
      else if (strcmp(argv[ArgIdx],"--allow-chown") == 0)
        pFlag->AllowChown = 1;
      else if (strcmp(argv[ArgIdx],"--no-allow-chown") == 0)
        pFlag->AllowChown = 0;
#endif
#ifdef D2U_UNICODE
#if (defined(_WIN32) && !defined(__CYGWIN__))
      else if ((strcmp(argv[ArgIdx],"-gb") == 0) || (strcmp(argv[ArgIdx],"--gb18030") == 0))
        pFlag->locale_target = TARGET_GB18030;
#endif
#endif
      else if ((strcmp(argv[ArgIdx],"-s") == 0) || (strcmp(argv[ArgIdx],"--safe") == 0))
        pFlag->Force = 0;
      else if ((strcmp(argv[ArgIdx],"-q") == 0) || (strcmp(argv[ArgIdx],"--quiet") == 0))
        pFlag->verbose = 0;
      else if ((strcmp(argv[ArgIdx],"-v") == 0) || (strcmp(argv[ArgIdx],"--verbose") == 0))
        pFlag->verbose = 2;
      else if ((strcmp(argv[ArgIdx],"-l") == 0) || (strcmp(argv[ArgIdx],"--newline") == 0))
        pFlag->NewLine = 1;
      else if ((strcmp(argv[ArgIdx],"-m") == 0) || (strcmp(argv[ArgIdx],"--add-bom") == 0))
        pFlag->add_bom = 1;
      else if ((strcmp(argv[ArgIdx],"-r") == 0) || (strcmp(argv[ArgIdx],"--remove-bom") == 0)) {
        pFlag->keep_bom = 0;
        pFlag->add_bom = 0;
      }
      else if ((strcmp(argv[ArgIdx],"-S") == 0) || (strcmp(argv[ArgIdx],"--skip-symlink") == 0))
        pFlag->Follow = SYMLINK_SKIP;
      else if ((strcmp(argv[ArgIdx],"-F") == 0) || (strcmp(argv[ArgIdx],"--follow-symlink") == 0))
        pFlag->Follow = SYMLINK_FOLLOW;
      else if ((strcmp(argv[ArgIdx],"-R") == 0) || (strcmp(argv[ArgIdx],"--replace-symlink") == 0))
        pFlag->Follow = SYMLINK_REPLACE;
      else if ((strcmp(argv[ArgIdx],"-V") == 0) || (strcmp(argv[ArgIdx],"--version") == 0)) {
        PrintVersion(progname, localedir);
        return(pFlag->error);
      }
      else if ((strcmp(argv[ArgIdx],"-L") == 0) || (strcmp(argv[ArgIdx],"--license") == 0)) {
        PrintLicense();
        return(pFlag->error);
      }
      else if (strcmp(argv[ArgIdx],"-ascii") == 0) { /* SunOS compatible options */
        pFlag->ConvMode = CONVMODE_ASCII;
        pFlag->keep_utf16 = 0;
        pFlag->locale_target = TARGET_UTF8;
      }
      else if (strcmp(argv[ArgIdx],"-7") == 0)
        pFlag->ConvMode = CONVMODE_7BIT;
      else if (strcmp(argv[ArgIdx],"-iso") == 0) {
        pFlag->ConvMode = (int)query_con_codepage();
        if (pFlag->verbose) {
           D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
           D2U_UTF8_FPRINTF(stderr,_("active code page: %d\n"), pFlag->ConvMode);
        }
        if (pFlag->ConvMode < 2)
           pFlag->ConvMode = CONVMODE_437;
      }
      else if (strcmp(argv[ArgIdx],"-437") == 0)
        pFlag->ConvMode = CONVMODE_437;
      else if (strcmp(argv[ArgIdx],"-850") == 0)
        pFlag->ConvMode = CONVMODE_850;
      else if (strcmp(argv[ArgIdx],"-860") == 0)
        pFlag->ConvMode = CONVMODE_860;
      else if (strcmp(argv[ArgIdx],"-863") == 0)
        pFlag->ConvMode = CONVMODE_863;
      else if (strcmp(argv[ArgIdx],"-865") == 0)
        pFlag->ConvMode = CONVMODE_865;
      else if (strcmp(argv[ArgIdx],"-1252") == 0)
        pFlag->ConvMode = CONVMODE_1252;
#ifdef D2U_UNICODE
      else if ((strcmp(argv[ArgIdx],"-u") == 0) || (strcmp(argv[ArgIdx],"--keep-utf16") == 0))
        pFlag->keep_utf16 = 1;
      else if ((strcmp(argv[ArgIdx],"-ul") == 0) || (strcmp(argv[ArgIdx],"--assume-utf16le") == 0))
        pFlag->ConvMode = CONVMODE_UTF16LE;
      else if ((strcmp(argv[ArgIdx],"-ub") == 0) || (strcmp(argv[ArgIdx],"--assume-utf16be") == 0))
        pFlag->ConvMode = CONVMODE_UTF16BE;
#endif
      else if (strcmp(argv[ArgIdx],"--info") == 0)
        pFlag->file_info |= INFO_DEFAULT;
      else if (strncmp(argv[ArgIdx],"--info=", (size_t)7) == 0) {
        get_info_options(argv[ArgIdx]+7, pFlag, progname);
      } else if (strncmp(argv[ArgIdx],"-i", (size_t)2) == 0) {
        get_info_options(argv[ArgIdx]+2, pFlag, progname);
      } else if ((strcmp(argv[ArgIdx],"-c") == 0) || (strcmp(argv[ArgIdx],"--convmode") == 0)) {
        if (++ArgIdx < argc) {
          if (strcmpi(argv[ArgIdx],"ascii") == 0) { /* Benjamin Lin's legacy options */
            pFlag->ConvMode = CONVMODE_ASCII;
            pFlag->keep_utf16 = 0;
          }
          else if (strcmpi(argv[ArgIdx], "7bit") == 0)
            pFlag->ConvMode = CONVMODE_7BIT;
          else if (strcmpi(argv[ArgIdx], "iso") == 0) {
            pFlag->ConvMode = (int)query_con_codepage();
            if (pFlag->verbose) {
               D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
               D2U_UTF8_FPRINTF(stderr,_("active code page: %d\n"), pFlag->ConvMode);
            }
            if (pFlag->ConvMode < 2)
               pFlag->ConvMode = CONVMODE_437;
          }
          else if (strcmpi(argv[ArgIdx], "mac") == 0) {
            if (is_dos2unix(progname))
              pFlag->FromToMode = FROMTO_MAC2UNIX;
            else
              pFlag->FromToMode = FROMTO_UNIX2MAC;
          } else {
            D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
            D2U_UTF8_FPRINTF(stderr, _("invalid %s conversion mode specified\n"),argv[ArgIdx]);
            pFlag->error = 1;
            ShouldExit = 1;
            pFlag->stdio_mode = 0;
          }
        } else {
          ArgIdx--;
          D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
          D2U_UTF8_FPRINTF(stderr,_("option '%s' requires an argument\n"),argv[ArgIdx]);
          pFlag->error = 1;
          ShouldExit = 1;
          pFlag->stdio_mode = 0;
        }
      }

#ifdef D2U_UNIFILE
      else if ((strcmp(argv[ArgIdx],"-D") == 0) || (strcmp(argv[ArgIdx],"--display-enc") == 0)) {
        if (++ArgIdx < argc) {
          if (strcmpi(argv[ArgIdx],"ansi") == 0)
            d2u_display_encoding = D2U_DISPLAY_ANSI;
          else if (strcmpi(argv[ArgIdx], "unicode") == 0)
            d2u_display_encoding = D2U_DISPLAY_UNICODE;
          else if (strcmpi(argv[ArgIdx], "unicodebom") == 0)
            d2u_display_encoding = D2U_DISPLAY_UNICODEBOM;
          else if (strcmpi(argv[ArgIdx], "utf8") == 0)
            d2u_display_encoding = D2U_DISPLAY_UTF8;
          else if (strcmpi(argv[ArgIdx], "utf8bom") == 0) {
            d2u_display_encoding = D2U_DISPLAY_UTF8BOM;
          } else {
            D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
            D2U_UTF8_FPRINTF(stderr, _("invalid %s display encoding specified\n"),argv[ArgIdx]);
            pFlag->error = 1;
            ShouldExit = 1;
            pFlag->stdio_mode = 0;
          }
        } else {
          ArgIdx--;
          D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
          D2U_UTF8_FPRINTF(stderr,_("option '%s' requires an argument\n"),argv[ArgIdx]);
          pFlag->error = 1;
          ShouldExit = 1;
          pFlag->stdio_mode = 0;
        }
      }
#endif

      else if ((strcmp(argv[ArgIdx],"-o") == 0) || (strcmp(argv[ArgIdx],"--oldfile") == 0)) {
        /* last convert not paired */
        if (!CanSwitchFileMode) {
          D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
          D2U_UTF8_FPRINTF(stderr, _("target of file %s not specified in new-file mode\n"), argv[ArgIdx-1]);
          pFlag->error = 1;
          ShouldExit = 1;
          pFlag->stdio_mode = 0;
        }
        pFlag->NewFile = 0;
        pFlag->file_info = 0;
        pFlag->to_stdout = 0;
      }

      else if ((strcmp(argv[ArgIdx],"-n") == 0) || (strcmp(argv[ArgIdx],"--newfile") == 0)) {
        /* last convert not paired */
        if (!CanSwitchFileMode) {
          D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
          D2U_UTF8_FPRINTF(stderr, _("target of file %s not specified in new-file mode\n"), argv[ArgIdx-1]);
          pFlag->error = 1;
          ShouldExit = 1;
          pFlag->stdio_mode = 0;
        }
        pFlag->NewFile = 1;
        pFlag->file_info = 0;
      }
      else if ((strcmp(argv[ArgIdx],"-O") == 0) || (strcmp(argv[ArgIdx],"--to-stdout") == 0)) {
        /* last convert not paired */
        if (!CanSwitchFileMode) {
          D2U_UTF8_FPRINTF(stderr,"%s: ",progname);
          D2U_UTF8_FPRINTF(stderr, _("target of file %s not specified in new-file mode\n"), argv[ArgIdx-1]);
          pFlag->error = 1;
          ShouldExit = 1;
          pFlag->stdio_mode = 0;
        }
        pFlag->NewFile = 0;
        pFlag->to_stdout = 1;
      }
      else { /* wrong option */
        PrintUsage(progname);
        ShouldExit = 1;
        pFlag->error = 1;
        pFlag->stdio_mode = 0;
      }
    } else {
      /* not an option */
      int conversion_error;
      pFlag->stdio_mode = 0;
      if (pFlag->NewFile) {
        if (CanSwitchFileMode)
          CanSwitchFileMode = 0;
        else {
#ifdef D2U_UNICODE
          conversion_error = ConvertNewFile(argv[ArgIdx-1], argv[ArgIdx], pFlag, progname, Convert, ConvertW);
#else
          conversion_error = ConvertNewFile(argv[ArgIdx-1], argv[ArgIdx], pFlag, progname, Convert);
#endif
          if (pFlag->verbose)
            print_messages(pFlag, argv[ArgIdx-1], argv[ArgIdx], progname, conversion_error);
          CanSwitchFileMode = 1;
        }
      } else {
        if (pFlag->file_info) {
          conversion_error = GetFileInfo(argv[ArgIdx], pFlag, progname);
          print_messages_info(pFlag, argv[ArgIdx], progname);
        } else {
          /* Old file mode */
          if (pFlag->to_stdout) {
#ifdef D2U_UNICODE
            conversion_error = ConvertToStdout(argv[ArgIdx], pFlag, progname, Convert, ConvertW);
#else
            conversion_error = ConvertToStdout(argv[ArgIdx], pFlag, progname, Convert);
#endif
          } else {
#ifdef D2U_UNICODE
            conversion_error = ConvertNewFile(argv[ArgIdx], argv[ArgIdx], pFlag, progname, Convert, ConvertW);
#else
            conversion_error = ConvertNewFile(argv[ArgIdx], argv[ArgIdx], pFlag, progname, Convert);
#endif
          }
          if (pFlag->verbose)
            print_messages(pFlag, argv[ArgIdx], NULL, progname, conversion_error);
        }
      }
    }
  }

  /* no file argument, use stdin and stdout */
  if ( (argc > 0) && pFlag->stdio_mode) {
    if (pFlag->file_info) {
      GetFileInfoStdio(pFlag, progname);
      print_messages_info(pFlag, "stdin", progname);
    } else {
#ifdef D2U_UNICODE
      ConvertStdio(pFlag, progname, Convert, ConvertW);
#else
      ConvertStdio(pFlag, progname, Convert);
#endif
      if (pFlag->verbose)
        print_messages_stdio(pFlag, progname);
    }
    return pFlag->error;
  }

  return pFlag->error;
}

void d2u_getc_error(CFlag *ipFlag, const char *progname)
{
    ipFlag->error = errno;
    if (ipFlag->verbose) {
      const char *errstr = strerror(errno);
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_ANSI_FPRINTF(stderr, _("can not read from input file: %s\n"), errstr);
    }
}

void d2u_putc_error(CFlag *ipFlag, const char *progname)
{
    ipFlag->error = errno;
    if (ipFlag->verbose) {
      const char *errstr = strerror(errno);
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_ANSI_FPRINTF(stderr, _("can not write to output file: %s\n"), errstr);
    }
}

#ifdef D2U_UNICODE
void d2u_putwc_error(CFlag *ipFlag, const char *progname)
{
    if (!(ipFlag->status & UNICODE_CONVERSION_ERROR)) {
      ipFlag->error = errno;
      if (ipFlag->verbose) {
        const char *errstr = strerror(errno);
        D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
        D2U_ANSI_FPRINTF(stderr, _("can not write to output file: %s\n"), errstr);
      }
    }
}

wint_t d2u_getwc(FILE *f, int bomtype)
{
   int c_trail, c_lead;
   wint_t wc;

   if (((c_lead=fgetc(f)) == EOF)  || ((c_trail=fgetc(f)) == EOF))
      return(WEOF);

   if (bomtype == FILE_UTF16LE) { /* UTF16 little endian */
      c_trail <<=8;
      wc = (wint_t)(c_trail + c_lead) ;
   } else {                      /* UTF16 big endian */
      c_lead <<=8;
      wc = (wint_t)(c_trail + c_lead) ;
   }
   return(wc);
}

wint_t d2u_ungetwc(wint_t wc, FILE *f, int bomtype)
{
   int c_trail, c_lead;

   if (bomtype == FILE_UTF16LE) { /* UTF16 little endian */
      c_trail = (int)(wc & 0xff00);
      c_trail >>=8;
      c_lead  = (int)(wc & 0xff);
   } else {                      /* UTF16 big endian */
      c_lead = (int)(wc & 0xff00);
      c_lead >>=8;
      c_trail  = (int)(wc & 0xff);
   }

   /* push back in reverse order */
   if ((ungetc(c_trail,f) == EOF)  || (ungetc(c_lead,f) == EOF))
      return(WEOF);
   return(wc);
}

/* Put wide character */
wint_t d2u_putwc(wint_t wc, FILE *f, CFlag *ipFlag, const char *progname)
{
   static char mbs[8];
   static wchar_t lead=0x01;  /* lead get's invalid value */
   static wchar_t wstr[3];
   size_t len;
#if (defined(_WIN32) && !defined(__CYGWIN__))
   DWORD dwFlags;
#endif

   if (ipFlag->keep_utf16) {
     int c_trail, c_lead;
     if (ipFlag->bomtype == FILE_UTF16LE) { /* UTF16 little endian */
        c_trail = (int)(wc & 0xff00);
        c_trail >>=8;
        c_lead  = (int)(wc & 0xff);
     } else {                      /* UTF16 big endian */
        c_lead = (int)(wc & 0xff00);
        c_lead >>=8;
        c_trail  = (int)(wc & 0xff);
     }
     if ((fputc(c_lead,f) == EOF)  || (fputc(c_trail,f) == EOF))
       return(WEOF);
     return wc;
   }

   /* Note: In the new Unicode standard lead is named "high", and trail is name "low". */

   /* check for lead without a trail */
   if ((lead >= 0xd800) && (lead < 0xdc00) && ((wc < 0xdc00) || (wc >= 0xe000))) {
      D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
      D2U_UTF8_FPRINTF(stderr, _("error: Invalid surrogate pair. Missing low surrogate.\n"));
      ipFlag->status |= UNICODE_CONVERSION_ERROR ;
      return(WEOF);
   }

   if ((wc >= 0xd800) && (wc < 0xdc00)) {   /* Surrogate lead */
      /* fprintf(stderr, "UTF-16 lead %x\n",wc); */
      lead = (wchar_t)wc; /* lead (high) surrogate */
      return(wc);
   }
   if ((wc >= 0xdc00) && (wc < 0xe000)) {   /* Surrogate trail */
      static wchar_t trail;

      /* check for trail without a lead */
      if ((lead < 0xd800) || (lead >= 0xdc00)) {
         D2U_UTF8_FPRINTF(stderr, "%s: ", progname);
         D2U_UTF8_FPRINTF(stderr, _("error: Invalid surrogate pair. Missing high surrogate.\n"));
         ipFlag->status |= UNICODE_CONVERSION_ERROR ;
         return(WEOF);
      }
      /* fprintf(stderr, "UTF-16 trail %x\n",wc); */
      trail = (wchar_t)wc; /* trail (low) surrogate */
#if defined(_WIN32) || defined(__CYGWIN__)
      /* On Windows (including Cygwin) wchar_t is 16 bit */
      /* We cannot decode an UTF-16 surrogate pair, because it will
         not fit in a 16 bit wchar_t. */
      wstr[0] = lead;
      wstr[1] = trail;
      wstr[2] = L'\0';
      lead = 0x01; /* make lead invalid */
#else
      /* On Unix wchar_t is 32 bit */
      /* When we don't decode the UTF-16 surrogate pair, wcstombs() does not
       * produce the same UTF-8 as WideCharToMultiByte().  The UTF-8 output
       * produced by wcstombs() is bigger, because it just translates the wide
       * characters in the range 0xD800..0xDBFF individually to UTF-8 sequences
       * (although these code points are reserved for use only as surrogate
       * pairs in UTF-16).
       *
       * Some smart viewers can still display this UTF-8 correctly (like Total
       * Commander lister), however the UTF-8 is not readable by Windows
       * Notepad (on Windows 7).  When we decode the UTF-16 surrogate pairs
       * ourselves the wcstombs() UTF-8 output is identical to what
       * WideCharToMultiByte() produces, and is readable by Notepad.
       *
       * Surrogate halves in UTF-8 are invalid. See also
       * https://en.wikipedia.org/wiki/UTF-8#Invalid_code_points
       * https://tools.ietf.org/html/rfc3629#page-5
       * It is a bug in (some implementations of) wcstombs().
       * On Cygwin 1.7 wcstombs() produces correct UTF-8 from UTF-16 surrogate pairs.
       */
      /* Decode UTF-16 surrogate pair */
      wstr[0] = 0x10000;
      wstr[0] += (lead & 0x03FF) << 10;
      wstr[0] += (trail & 0x03FF);
      wstr[1] = L'\0';
      lead = 0x01; /* make lead invalid */
      /* fprintf(stderr, "UTF-32  %x\n",wstr[0]); */
#endif
   } else {
      wstr[0] = (wchar_t)wc;
      wstr[1] = L'\0';
   }

   if (wc == 0x0000) {
      if (fputc(0, f) == EOF)
         return(WEOF);
      return(wc);
   }

#if (defined(_WIN32) && !defined(__CYGWIN__))
/* The WC_ERR_INVALID_CHARS flag is available since Windows Vista (0x0600). It enables checking for
   invalid input characters. */
#if WINVER >= 0x0600
   dwFlags = WC_ERR_INVALID_CHARS;
#else
   dwFlags = 0;
#endif
   /* On Windows we convert UTF-16 always to UTF-8 or GB18030 */
   if (ipFlag->locale_target == TARGET_GB18030) {
     len = (size_t)(WideCharToMultiByte(54936, dwFlags, wstr, -1, mbs, sizeof(mbs), NULL, NULL) -1);
   } else {
     len = (size_t)(WideCharToMultiByte(CP_UTF8, dwFlags, wstr, -1, mbs, sizeof(mbs), NULL, NULL) -1);
   }
#else
   /* On Unix we convert UTF-16 to the locale encoding */
   len = wcstombs(mbs, wstr, sizeof(mbs));
   /* fprintf(stderr, "len  %d\n",len); */
#endif

   if ( len == (size_t)(-1) ) {
      /* Stop when there is a conversion error */
   /* On Windows we convert UTF-16 always to UTF-8 or GB18030 */
      if (ipFlag->verbose) {
#if (defined(_WIN32) && !defined(__CYGWIN__))
        d2u_PrintLastError(progname);
#else
        const char *errstr = strerror(errno);
        D2U_UTF8_FPRINTF(stderr, "%s:", progname);
        D2U_ANSI_FPRINTF(stderr, " %s\n", errstr);
#endif
      }
      ipFlag->status |= UNICODE_CONVERSION_ERROR ;
      return(WEOF);
   } else {
      size_t i;
      for (i=0; i<len; i++) {
         if (fputc(mbs[i], f) == EOF)
            return(WEOF);
      }
   }
   return(wc);
}
#endif
