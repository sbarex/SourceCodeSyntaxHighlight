!include version.mk

CC      = wcc
SRCDIR = .
DEFINES = -DVER_REVISION="$(DOS2UNIX_VERSION)" -DVER_DATE="$(DOS2UNIX_DATE)" -DVER_AUTHOR="$(DOS2UNIX_AUTHOR)"
CFLAGS  = $(DEFINES) -i=$(SRCDIR) -w4 -e25 -zq -od -d2 -bt=dos -ml
WATCOMSRC = $(%WATCOM)\src\startup
PROGRAMS = dos2unix.exe unix2dos.exe mac2unix.exe unix2mac.exe
HTMLEXT = htm
PACKAGE = dos2unix
DOCFILES = man\man1\$(PACKAGE).txt man\man1\$(PACKAGE).$(HTMLEXT)
VERSIONSUFFIX = b
ZIPFILE = d2u$(DOS2UNIX_VERSION_SHORT)$(VERSIONSUFFIX).zip
docsubdir = dos2unix

prefix = c:\dos

TARGET = dos

all: $(PROGRAMS) $(DOCFILES) .SYMBOLIC

dos2unix.exe: dos2unix.obj querycp.obj common.obj wildargv.obj
	@%create dos2unix.lnk
	@%append dos2unix.lnk FIL dos2unix.obj,querycp.obj,common.obj,wildargv.obj
	wlink name dos2unix d all SYS $(TARGET) op m op st=32k op maxe=25 op q op symf @dos2unix.lnk
	del dos2unix.lnk

unix2dos.exe: unix2dos.obj querycp.obj common.obj wildargv.obj
	@%create unix2dos.lnk
	@%append unix2dos.lnk FIL unix2dos.obj,querycp.obj,common.obj,wildargv.obj
	wlink name unix2dos d all SYS $(TARGET) op m op st=32k op maxe=25 op q op symf @unix2dos.lnk
	del unix2dos.lnk

!include wcc.mif

