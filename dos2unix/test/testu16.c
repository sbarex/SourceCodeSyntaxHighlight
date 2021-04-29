#include <stdio.h>
#include <windows.h>
#include <fcntl.h>
#include <io.h>

/* This program demonstrates Unicode UTF-16 printed text redirected to a
   correct UTF-16 file.

   .\testu16.exe > out.txt

*/

int main () {

  int prevmode;


  prevmode = _setmode(_fileno(stdout), _O_U16TEXT);
  /* We need to print an UTF-16 BOM for correct redirection in PowerShell. */
  fwprintf(stdout, L"\xfeff");
  fwprintf(stdout,L"one\n");
  fwprintf(stdout,L"two\n");
  fwprintf(stdout,L"three\n");
  /* Flushing stdout is required to get correct UTF-16.
     This is required for both CMD.exe and PowerShell. */
  fflush(stdout);
  _setmode(_fileno(stdout), prevmode);


  return 0;
}
