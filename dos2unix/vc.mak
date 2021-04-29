# Makefile for Microsoft Visual C++
#

!include version.mk

UNIFILE = 1

CC = cl.exe /nologo
LINK = link.exe /nologo
SRCDIR = .

DEFINES = /DVER_REVISION=\"$(DOS2UNIX_VERSION)\" /DVER_DATE=\"$(DOS2UNIX_DATE)\" /DVER_AUTHOR=\""$(DOS2UNIX_AUTHOR)"\"
CFLAGS = $(DEFINES)

!ifdef DEBUG
LDFLAGS = -debug
!else
LDFLAGS =
!endif

PROGRAMS = dos2unix.exe unix2dos.exe mac2unix.exe unix2mac.exe
HTMLEXT = htm
PACKAGE = dos2unix
DOCFILES = man\man1\$(PACKAGE).txt man\man1\$(PACKAGE).$(HTMLEXT)
VERSIONSUFFIX = -win32
UCS = 1

prefix = c:\usr\local

# We only build and install the English manuals, because wildcards on
# directory names are not supported in Windows CMD. Like man\*\man1\*.txt will
# give a syntax error. It could be done with more scripting, but for simplicity
# we stick to English.

all: $(PROGRAMS) $(DOCFILES)


dos2unix.exe: dos2unix.obj querycp.obj common.obj
	$(LINK) $(LDFLAGS) dos2unix.obj querycp.obj common.obj setargv.obj mpr.lib shell32.lib

unix2dos.exe: unix2dos.obj querycp.obj common.obj
	$(LINK) $(LDFLAGS) unix2dos.obj querycp.obj common.obj setargv.obj mpr.lib shell32.lib


!if "$(UCS)" == "1"
CFLAGS = $(CFLAGS) -DD2U_UNICODE
!endif
!if "$(UNIFILE)" == "1"
CFLAGS = $(CFLAGS) -DD2U_UNIFILE
!endif
!if "$(DEBUGMSG)" == "1"
CFLAGS = $(CFLAGS) -DDEBUG
!endif

dos2unix.obj :  $(SRCDIR)\dos2unix.c $(SRCDIR)\querycp.h $(SRCDIR)\common.h
	$(CC) -c $(CFLAGS) $(SRCDIR)\dos2unix.c

unix2dos.obj :  $(SRCDIR)\unix2dos.c $(SRCDIR)\querycp.h $(SRCDIR)\common.h
	$(CC) -c $(CFLAGS) $(SRCDIR)\unix2dos.c

querycp.obj :  $(SRCDIR)\querycp.c $(SRCDIR)\querycp.h
	$(CC) -c $(CFLAGS) $(SRCDIR)\querycp.c

common.obj :  $(SRCDIR)\common.c $(SRCDIR)\common.h
	$(CC) -c $(CFLAGS) $(SRCDIR)\common.c

mac2unix.exe : dos2unix.exe
	copy /v dos2unix.exe mac2unix.exe

unix2mac.exe : unix2dos.exe
	copy /v unix2dos.exe unix2mac.exe

exec_prefix = $(prefix)
bindir      = $(exec_prefix)\bin
datarootdir = $(prefix)\share
datadir     = $(datarootdir)
!ifndef docsubdir
docsubdir   = $(PACKAGE)-$(DOS2UNIX_VERSION)
!endif
docdir      = $(datarootdir)\doc\$(docsubdir)
INSTALL_OBJS_DOC = README.txt NEWS.txt ChangeLog.txt COPYING.txt TODO.txt BUGS.txt $(DOCFILES)


$(prefix):
	if not exist $@ mkdir $@

$(bindir): $(prefix)
	if not exist $@ mkdir $@

$(datarootdir): $(prefix)
	if not exist $@ mkdir $@

$(datarootdir)\doc: $(datarootdir)
	if not exist $@ mkdir $@

$(docdir): $(datarootdir)\doc
	if not exist $@ mkdir $@

install: $(PROGRAMS) $(DOCFILES) $(bindir) $(docdir)
	copy dos2unix.exe $(bindir)
	copy mac2unix.exe $(bindir)
	copy unix2dos.exe $(bindir)
	copy unix2mac.exe $(bindir)
	copy README.txt $(docdir)
	copy NEWS.txt $(docdir)
	copy ChangeLog.txt $(docdir)
	copy COPYING.txt $(docdir)
	copy TODO.txt $(docdir)
	copy BUGS.txt $(docdir)
	copy man\man1\$(PACKAGE).txt $(docdir)
	copy man\man1\$(PACKAGE).$(HTMLEXT) $(docdir)

man\man1\dos2unix.txt : man\man1\dos2unix.pod
	pod2text $** > $@

man\man1\dos2unix.$(HTMLEXT) : man\man1\dos2unix.pod
	pod2html --title="$(PACKAGE) $(DOS2UNIX_VERSION) - DOS/MAC to UNIX and vice versa text file format converter" $** > $@

TXTFILES = man\man1\$(PACKAGE).txt
HTMLFILES = man\man1\$(PACKAGE).$(HTMLEXT)

txt : $(TXTFILES)

html : $(HTMLFILES)

doc : $(DOCFILES)

uninstall:
	-del $(bindir)\dos2unix.exe
	-del $(bindir)\mac2unix.exe
	-del $(bindir)\unix2dos.exe
	-del $(bindir)\unix2mac.exe
	-rmdir /s /q $(docdir)

!ifndef VERSIONSUFFIX
VERSIONSUFFIX	= -bin
!endif

!ifndef ZIPFILE
ZIPFILE = $(PACKAGE)$(DOS2UNIX_VERSION)$(VERSIONSUFFIX).zip
!endif
ZIPOBJ = bin\dos2unix.exe bin\mac2unix.exe bin\unix2dos.exe bin\unix2mac.exe share\doc\$(docsubdir) $(ZIPOBJ_EXTRA)

DISTCMD = dist.bat

dist :
	@echo cd /d $(prefix) > $(DISTCMD)
	@echo unix2dos -k share\doc\$(docsubdir)\*.txt >> $(DISTCMD)
	@echo unix2dos -k share\doc\$(docsubdir)\*.$(HTMLEXT) >> $(DISTCMD)
	@echo zip -r $(ZIPFILE) $(ZIPOBJ) >> $(DISTCMD)
	@echo cd /d $(MAKEDIR) >> $(DISTCMD)
	@echo move $(prefix)\$(ZIPFILE) .. >> $(DISTCMD)
	.\$(DISTCMD)


mostlyclean :
	-del *.obj
	-del *.exe
	-del *.tmp

clean : mostlyclean
	-del $(DISTCMD)

maintainer-clean : clean
	-del $(DOCFILES)
