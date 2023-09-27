#include <stdio.h>
#include <stdlib.h>
#include <wchar.h>
#include <errno.h>
#include <string.h>
#include <locale.h>

int main() {

  wchar_t wstr[2];
  char str[5];
  size_t i;

  setlocale(LC_ALL, "");

  wstr[0] = 0x8428; /* Unicode CJK U+8428 */
  wstr[1] = 0x0;

  for (i=0;i<sizeof(str);i++)
    str[i]='\0';

  if (wcstombs(str, wstr, sizeof(str)) != (size_t)-1) {
    for (i=0;i<sizeof(str);i++)
      fprintf(stdout,"%02X ",(unsigned char)str[i]);
    fprintf(stdout,"\n");
    /* fprintf(stdout,"%s\n",str); */
    fprintf(stdout,"PASS\n");
    return 0;
  } else {
    const char *errstr = strerror(errno);
    fprintf(stdout,"%s\n",errstr);
    fprintf(stdout,"FAIL\n");
    return 1;
  }

}
