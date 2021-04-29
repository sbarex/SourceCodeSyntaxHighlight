#include <stdio.h>
#include <fcntl.h>
#include <windows.h>
#include <locale.h>

/*

 This program proves that when you set the locale to "", the Chinese ANSI CP936
 encoded text is printed wrongly in a simplified Chinese regional setting.
 UTF-8 is also printed wrongly.

To test this program you first need to change the Windows locale setting to
simplified Chinese. There is no problem doing that, because the "display
language" will stay the original language, and you can still use your Windows.

Control Panel > Region and Language > Administrative > Change system locale

Select simplified Chinese and reboot your PC.

For example output see setlocale.png.

 */

print_string(const char* str, const char* ustr, const wchar_t *wstr) {
  int prevmode;
  UINT outputCP;
  int utf8 = 0;

  /* Set utf8 to 1 to print UTF-8 text.
     If you print both UTF-16 en UTF-8 in one program the console gets
     mixed up. When the UTF-8 is printed after UTF-16 the UTF-16 text
     is displayed wrongly.
   */ 

  if ( ! utf8 ) {
    /* When the locale is set to "" the following line will produce wrong output */
      printf ("ANSI CP936 %s\n",str);

    /* UTF-16 will produce correct output in all cases. */
      prevmode = _setmode(_fileno(stdout), _O_U16TEXT);
      wprintf(L"UTF-16    %ls\n",wstr);
      _setmode(_fileno(stdout), prevmode);
   } else {

    /* UTF-8 will produce wrong output when the locale is "".
       When the locale is "C" wrong output with raster font, and correct output
       with TrueType font. */
      outputCP = GetConsoleOutputCP();
      SetConsoleOutputCP(CP_UTF8);
      wprintf(L"UTF-8     %S\n",ustr);
      SetConsoleOutputCP(outputCP);

    /* The code below produces wrong output in all cases */
    //  prevmode = _setmode(_fileno(stdout), _O_U8TEXT);
    //  wprintf(L"UTF-8     %S",ustr);
    //  _setmode(_fileno(stdout), prevmode);
   }

}

int main() {

  char str[5];      /* ANSI CP936 */
  char ustr[15];    /* UTF-8 */
  wchar_t wstr[10]; /* UTF-16 */

/* Create ANSI CP936 string (meaning: Western-European). */
  str[0] = 0xce;
  str[1] = 0xf7;
  str[2] = 0xc5;
  str[3] = 0xb7;
  str[4] = '\0';
/* Convert CP936 to UTF-16. */
  MultiByteToWideChar(936, 0, str, -1, wstr, sizeof(wstr));
/* Convert UTF-16 to UTF-8 */
  WideCharToMultiByte(CP_UTF8, 0, wstr, -1, ustr, sizeof(ustr), NULL, NULL);



  setlocale (LC_ALL, "");
  printf("==> setlocale (LC_ALL, \"\");\n");
  print_string(str, ustr, wstr);

  setlocale (LC_ALL, "C");
  printf("\n==> setlocale (LC_ALL, \"C\");\n");
  print_string(str, ustr, wstr);

  return  0;
}
