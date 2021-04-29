Although locale -a says on FreeBSD 10.1 that zh_CN.GB18030 is supported,
the conversion of CJK characters fails.
This makes the gb18030 test of dos2unix fail on FreeBSD.


The problem is wcstombs(), and this is demonstrated with wcstombs_test.c.

Run the test with the command: gmake wcstombs

This is correct output:

cc -Wall -Wextra wcstombs_test.c -o wcstombs_test
====> test wcstombs() UTF-8
LC_ALL=en_US.UTF-8 ./wcstombs_test
E8 90 A8 00 00 
PASS
====> test wcstombs() GB18030
LC_ALL=zh_CN.GB18030 ./wcstombs_test
C8 F8 00 00 00 
PASS

