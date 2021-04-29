/* querycp.c is in the public domain */

#if (defined(__WATCOMC__) && defined(__NT__))
#  define _WIN32 1
#endif

#ifdef __DJGPP__

#include <dpmi.h>
#include <go32.h>
#include <stdio.h>

/*
 ----------------------------------------------------------------------
 Tuesday, May 5, 2009    1:40pm
 rugxulo _AT_ gmail _DOT_ com

 This file is (obviously?) not copyrighted, "nenies proprajxo" !!

 Tested successfully on DR-DOS 7.03, FreeDOS 1.0++, and MS-DOS 6.22.
 (Doesn't work on XP or Vista, though.)
 ----------------------------------------------------------------------

 unsigned short query_con_codepage(void);

 gets currently selected display CON codepage

 int 21h, 6601h ("chcp") needs NLSFUNC.EXE + COUNTRY.SYS, but many
    obscure codepages (e.g. FD's cp853 from EGA.CPX (CPIX.ZIP) or
    Kosta Kostis' cp913 from ISOLATIN.CPI (ISOCP101.ZIP) have no
    relevant data inside COUNTRY.SYS.

 int 21h, 440Ch 6Ah only works in MS-DOS and DR-DOS (not FreeDOS) because
    FreeDOS DISPLAY is an .EXE TSR, not a device driver, and hence doesn't
    fully support IOCTL, so they use the undocumented int 2Fh, 0AD02h
    (which doesn't work in DR-DOS!). But DR-DOS' DISPLAY doesn't respond
    to the typical install check i.d. anyways. FreeDOS currently only
    supports COUNTRY.SYS in their "unstable" kernel 2037, but at least
    their KEYB, "gxoje", supports cp853 too (thanks, Henrique!).

 P.S. For MS or DR: ren ega.cpx *.com ; upx -d ega.com ; ren ega.com *.cpi

 ADDENDUM (2011):
 Latest "stable" FreeDOS kernel is 2040, it now includes COUNTRY.SYS
 support by default, but NLSFUNC (CHCP) 'system code page' support is
 partially unimplemented (lacking some int 2Fh calls, yet Eduardo
 Casino didn't seem too worried, so I dunno, nag him if necessary,
 heh).
 ----------------------------------------------------------------------
*/

unsigned short query_con_codepage(void) {
   __dpmi_regs regs;

   unsigned short param_block[2] = { 0, 437 };

   regs.d.eax = 0x440C;                /* GENERIC IO FOR HANDLES */
   regs.d.ebx = 1;                     /* STDOUT */
   regs.d.ecx = 0x036A;                /* 3 = CON, 0x6A = QUERY SELECTED CP */
   regs.x.ds = __tb >> 4;              /* using transfer buffer for low mem. */
   regs.x.dx = __tb & 0x0F;            /* (suggested by DJGPP FAQ, hi Eli!) */
   regs.x.flags |= 1;                  /* preset carry for potential failure */
   __dpmi_int (0x21, &regs);

   if (!(regs.x.flags & 1))            /* if succeed (carry flag not set) */
     dosmemget( __tb, 4, param_block);
   else {                              /* (undocumented method) */
     regs.x.ax = 0xAD02;               /* 440C -> MS-DOS or DR-DOS only */
     regs.x.bx = 0xFFFE;               /* AD02 -> MS-DOS or FreeDOS only */
     regs.x.flags |= 1;
     __dpmi_int(0x2F, &regs);

     if ((!(regs.x.flags & 1)) && (regs.x.bx < 0xFFFE))
       param_block[1] = regs.x.bx;
   }

   return param_block[1];
}
#elif defined(__WATCOMC__) && defined(__I86__) /* Watcom C, 16 bit Intel */

/* rugxulo _AT_ gmail _DOT_ com */

#include <stdio.h>
#include <dos.h>
#include <i86.h>

unsigned short query_con_codepage(void) {
   union REGS regs;
   unsigned short param_block[2] = { 0, 437 };

   regs.x.ax = 0x440C;           /* GENERIC IO FOR HANDLES */
   regs.x.bx = 1;                /* STDOUT */
   regs.x.cx = 0x036A;           /* 3 = CON, 0x6A = QUERY SELECTED CP */
   regs.x.dx = (unsigned short)param_block;
   regs.x.cflag |= 1;            /* preset carry for potential failure */
   int86(0x21, &regs, &regs);

   if (regs.x.cflag)             /* if not succeed (carry flag set) */
   {
     regs.x.ax = 0xAD02;         /* 440C -> MS-DOS or DR-DOS only */
     regs.x.bx = 0xFFFE;         /* AD02 -> MS-DOS or FreeDOS only */
     regs.x.cflag |= 1;
     int86(0x2F, &regs, &regs);
   }

     if ((!(regs.x.cflag)) && (regs.x.bx < 0xFFFE))
       param_block[1] = regs.x.bx;

   return param_block[1];

}

#elif defined(__WATCOMC__) && defined(__DOS__) /* Watcom C, 32 bit DOS */

/* rugxulo _AT_ gmail _DOT_ com */

#include <stdio.h>
#include <dos.h>
#include <i86.h>

unsigned short query_con_codepage(void) {
   union REGS regs;
   unsigned short param_block[2] = { 0, 437 };

   regs.x.eax = 0x440C;           /* GENERIC IO FOR HANDLES */
   regs.x.ebx = 1;                /* STDOUT */
   regs.x.ecx = 0x036A;           /* 3 = CON, 0x6A = QUERY SELECTED CP */
   regs.x.edx = (unsigned short)param_block;
   regs.x.cflag |= 1;             /* preset carry for potential failure */
   int386(0x21, &regs, &regs);

   if (regs.x.cflag)              /* if not succeed (carry flag set) */
   {
     regs.x.eax = 0xAD02;         /* 440C -> MS-DOS or DR-DOS only */
     regs.x.ebx = 0xFFFE;         /* AD02 -> MS-DOS or FreeDOS only */
     regs.x.cflag |= 1;
     int386(0x2F, &regs, &regs);
   }

     if ((!(regs.x.cflag)) && (regs.x.ebx < 0xFFFE))
       param_block[1] = regs.x.ebx;

   return param_block[1];

}


#elif defined (_WIN32) && !defined(__CYGWIN__) /* Windows, not Cygwin */

/* Erwin Waterlander */

#include <windows.h>
unsigned short query_con_codepage(void) {

  /* Dos2unix is modelled after dos2unix under SunOS/Solaris.
   * The original dos2unix ISO mode on SunOS supported code
   * pages CP437, CP850, CP860, CP863, and CP865, which
   * are DOS code pages. Therefore we request here the DOS
   * code page of the Console. The DOS code page is used
   * by DOS programs, for instance text editor 'edit'.
   */

  /* Get the console's DOS code page */
   return((unsigned short)GetConsoleOutputCP());

   /* Get the system's ANSI code page */
   /* return((unsigned short)GetACP()); */

}

#elif defined (__OS2__) /* OS/2 Warp */

#define INCL_DOS
#include <os2.h>

unsigned short query_con_codepage(void) {
  ULONG cp[3];
  ULONG cplen;

  DosQueryCp(sizeof(cp), cp, &cplen);
  return((unsigned short)cp[0]);
}

#else  /* Unix, other */
unsigned short query_con_codepage(void) {
   return(0);
}
#endif

#ifdef TEST
int main() {
  printf("\nCP%u\n",query_con_codepage() );  /* should be same result as */
  return 0;                                  /*   "mode con cp /status" */
}
#endif

