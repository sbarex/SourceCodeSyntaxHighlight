# Author: Erwin Waterlander
#
#   Copyright (C) 2009-2020 Erwin Waterlander
#   All rights reserved.
#
#   Redistribution and use in source and binary forms, with or without
#   modification, are permitted provided that the following conditions
#   are met:
#   1. Redistributions of source code must retain the above copyright
#      notice, this list of conditions and the following disclaimer.
#   2. Redistributions in binary form must reproduce the above copyright
#      notice in the documentation and/or other materials provided with
#      the distribution.
#
#   THIS SOFTWARE IS PROVIDED BY THE AUTHOR ``AS IS'' AND ANY
#   EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
#   IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#   PURPOSE ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR BE LIABLE
#   FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
#   CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT
#   OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR
#   BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#   WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
#   OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN
#   IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
#   Description
#
#       This is a GNU Makefile that uses GNU compilers, linkers and cpp. The
#       platform specific issues are determined by the various OS teets that
#       rely on the uname(1) command and directory locations.
#
#       Set additional flags for the build with variables CFLAGS_USER,
#       DEFS_USER and LDFLAGS_USER.

include version.mk

.PHONY: doc man txt html pdf mofiles tags merge test check

.PRECIOUS: %.1 %.pod

CC              ?= gcc
CPP             ?= cpp
CPP_FLAGS_POD   = ALL
STRIP           = strip

PACKAGE         = dos2unix
UNIX2DOS        = unix2dos
MAC2UNIX        = mac2unix
UNIX2MAC        = unix2mac

# Native Language Support (NLS)
ENABLE_NLS      = 1
# Large File Support (LFS)
LFS             = 1
# DEBUG=1 adds the -g option to CFLAGS, for adding debug symbols.
DEBUG = 0
# DEBUGMSG=1 adds -DDEBUG=1 to CFLAGS, for extra verbose messages.
DEBUGMSG = 0
UCS = 1
DIST_TARGET = dist-tgz

EXE=

BIN             = $(PACKAGE)$(EXE)
UNIX2DOS_BIN    = $(UNIX2DOS)$(EXE)
MAC2UNIX_BIN    = $(MAC2UNIX)$(EXE)
UNIX2MAC_BIN    = $(UNIX2MAC)$(EXE)

LINK            = ln -sf
LINK_MAN        = $(LINK)

prefix          = /usr
exec_prefix     = $(prefix)
bindir          = $(exec_prefix)/bin
datarootdir     = $(prefix)/share
datadir         = $(datarootdir)

docsubdir       = $(PACKAGE)-$(DOS2UNIX_VERSION)
docdir          = $(datarootdir)/doc/$(docsubdir)
localedir       = $(datarootdir)/locale
mandir          = $(datarootdir)/man
man1dir         = $(mandir)/man1
manext          = .1
man1ext         = .1

ifdef ENABLE_NLS
        POT             = po/$(PACKAGE).pot
        POFILES         = $(wildcard po/*.po)
        MOFILES         = $(patsubst %.po,%.mo,$(POFILES))
        NLSSUFFIX       = -nls
endif

HTMLEXT = htm
# English only documents.
INSTALL_OBJS_DOC = README.txt INSTALL.txt NEWS.txt ChangeLog.txt COPYING.txt TODO.txt BUGS.txt

# English manual
MANFILES_EN = man/man1/$(PACKAGE).1
TXTFILES_EN = man/man1/$(PACKAGE).txt
HTMLFILES_EN = man/man1/$(PACKAGE).$(HTMLEXT)
PSFILES_EN = man/man1/$(PACKAGE).ps
PDFFILES_EN = man/man1/$(PACKAGE).pdf

# International manuals
ifdef ENABLE_NLS
        MANPOTFILE      = po-man/dos2unix-man.pot
        MANPOFILES      = $(wildcard po-man/*.po)
        MANPODFILES     = $(patsubst po-man/%.po,man/%/man1/dos2unix.pod,$(MANPOFILES))
endif
MANFILES        = $(patsubst %.pod,%.1,$(MANPODFILES))
TXTFILES        = $(patsubst %.pod,%.txt,$(MANPODFILES))
HTMLFILES       = $(patsubst %.pod,%.$(HTMLEXT),$(MANPODFILES))
PSFILES         = $(patsubst %.pod,%.ps,$(MANPODFILES))
PDFFILES        = $(patsubst %.pod,%.pdf,$(MANPODFILES))

# On some systems (e.g. FreeBSD 4.10) GNU install is installed as `ginstall'.
INSTALL         = install
INSTALL_PROGRAM = $(INSTALL) -m 755
INSTALL_DATA    = $(INSTALL) -m 644

# On some systems (e.g. GNU Win32) GNU mkdir is installed as `gmkdir'.
MKDIR           = mkdir

ifdef ENABLE_NLS
        DOS2UNIX_NLSDEFS = -DENABLE_NLS -DLOCALEDIR=\"$(localedir)\" -DPACKAGE=\"$(PACKAGE)\"
endif

VERSIONSUFFIX   = -bin

# ......................................................... OS flags ...


ifndef D2U_OS
        d2u_os=$(shell uname -s)

ifeq ($(findstring CYGWIN,$(d2u_os)),CYGWIN)
        D2U_OS = cygwin
endif

ifndef D2U_OS
ifeq ($(findstring MSYS,$(d2u_os)),MSYS)
        D2U_OS = msys
endif
endif

ifndef D2U_OS
ifeq ($(findstring MINGW32,$(d2u_os)),MINGW32)
        D2U_OS = mingw32
endif
endif

ifndef D2U_OS
ifeq ($(findstring MINGW64,$(d2u_os)),MINGW64)
        D2U_OS = mingw64
endif
endif

ifndef D2U_OS
ifneq ($(DJGPP),)
        D2U_OS = msdos
endif
endif

ifndef D2U_OS
ifneq (, $(wildcard /opt/csw))
        D2U_OS = sun
endif
endif

ifndef D2U_OS
        D2U_OS=$(shell echo $(d2u_os) | tr [A-Z] [a-z])
endif

endif

ifeq (cygwin,$(D2U_OS))
ifdef ENABLE_NLS
        LIBS_EXTRA = -lintl -liconv
endif
        LDFLAGS_EXTRA = -Wl,--enable-auto-import
        EXE = .exe
        # allow non-cygwin clients which do not understand cygwin
        # symbolic links to launch applications...
        LINK = ln -f
        # but use symbolic links for man pages, since man client
        # IS a cygwin app and DOES understand symlinks.
        LINK_MAN = ln -fs
        # Cygwin packaging standard avoids version numbers on
        # documentation directories.
        docsubdir       = $(PACKAGE)
        MACHINE := $(subst -pc-cygwin,,$(shell gcc -dumpmachine))
        VERSIONSUFFIX   = -cygwin-$(MACHINE)
endif

ifeq (msys,$(D2U_OS))
        CC=gcc
        EXE = .exe
        MACHINE := $(subst -pc-msys,,$(shell gcc -dumpmachine))
# MSYS 1 does not support locales and no Unicode.
ifeq ($(shell ./test/chk_loc.sh en_US.utf8),no)
        UCS =
        VERSIONSUFFIX = -msys1-$(MACHINE)
else
        VERSIONSUFFIX = -msys2-$(MACHINE)
endif
ifdef ENABLE_NLS
        LIBS_EXTRA = -lintl -liconv
endif
endif

ifeq (mingw32,$(D2U_OS))
        CC=gcc
        prefix=c:/usr/local
        EXE = .exe
        VERSIONSUFFIX = -win32
        LINK = cp -f
        UNIFILE=1
        DIST_TARGET = dist-zip
ifdef ENABLE_NLS
        LIBS_EXTRA = -lintl -liconv
        ZIPOBJ_EXTRA = bin/libintl-8.dll bin/libiconv-2.dll
endif
ifeq ($(findstring w64-mingw32,$(shell gcc -dumpmachine)),w64-mingw32)
# Mingw-w64
        CFLAGS_COMPILER = -DD2U_COMPILER=MINGW32_W64
ifdef ENABLE_NLS
        ZIPOBJ_EXTRA += bin/libgcc_s_dw2-1.dll bin/libwinpthread-1.dll
endif
        CRT_GLOB_OBJ = /mingw32/i686-w64-mingw32/lib/CRT_glob.o
        LIBS_EXTRA += $(CRT_GLOB_OBJ)
        CFLAGS_OS=-I/mingw32/include
else
        CFLAGS_OS=-D_O_U16TEXT=0x20000
endif
endif

ifeq (mingw64,$(D2U_OS))
        CC=gcc
        prefix=c:/usr/local64
        EXE = .exe
        VERSIONSUFFIX = -win64
        LINK = cp -f
        UNIFILE=1
        DIST_TARGET = dist-zip
ifdef ENABLE_NLS
        LIBS_EXTRA = -lintl -liconv
        ZIPOBJ_EXTRA = bin/libintl-8.dll bin/libiconv-2.dll
endif
        CRT_GLOB_OBJ = /mingw64/x86_64-w64-mingw32/lib/CRT_glob.o
        LIBS_EXTRA += $(CRT_GLOB_OBJ)
        CFLAGS_OS=-I/mingw64/include
endif

ifeq (msdos,$(D2U_OS))
        prefix=c:/dos32
        EXE = .exe
        VERSIONSUFFIX = pm
        LINK_MAN = cp -f
        docsubdir = dos2unix
        UCS =
        ZIPOBJ_EXTRA = bin/cwsdpmi.exe
ifdef ENABLE_NLS
        LIBS_EXTRA = -lintl -liconv
endif
endif

ifeq (os/2,$(D2U_OS))
        prefix=c:/usr
        EXE = .exe
        VERSIONSUFFIX = -os2
        LINK_MAN = cp -f
        UCS =
        LDFLAGS_EXTRA = -Zargs-wild
        DIST_TARGET = dist-zip
ifdef ENABLE_NLS
        LIBS_EXTRA += -lintl -liconv
endif
endif

ifeq (freemint,$(D2U_OS))
        prefix=/usr
        EXE =
        VERSIONSUFFIX = -freemint
        UCS=
        ENABLE_NLS=
ifdef ENABLE_NLS
        LIBS_EXTRA += -lintl -liconv
endif
        EXTRA_DEFS += -Dfreemint -D__OS=\"freemint\"
endif

ifeq (freebsd,$(D2U_OS))
ifdef ENABLE_NLS
        CFLAGS_OS     = -I/usr/local/include
        LDFLAGS_EXTRA = -L/usr/local/lib
        LIBS_EXTRA    = -lintl
endif
endif

ifeq (darwin,$(D2U_OS))
ifdef ENABLE_NLS
        CFLAGS_OS     = -I/usr/local/include
        LDFLAGS_EXTRA = -L/usr/local/lib
        LIBS_EXTRA    = -lintl
endif
endif

ifeq (sun,$(D2U_OS))
        # Running under SunOS/Solaris
        LIBS_EXTRA = -lintl
endif

ifeq (hp-ux,$(D2U_OS))
        # Running under HP-UX
        EXTRA_DEFS += -Dhpux -D_HPUX_SOURCE
endif


# ............................................................ flags ...

# PostScript and PDF generation from UTF-8 manuals is not working,
# or I don't know how to do it.

CFLAGS_USER     =
ifeq ($(DEBUG), 1)
CFLAGS          ?= -O0
else
CFLAGS          ?= -O2
endif
CFLAGS          += -Wall -Wextra -Wconversion $(RPM_OPT_FLAGS) $(CPPFLAGS) $(CFLAGS_USER)

EXTRA_CFLAGS    = -DVER_REVISION=\"$(DOS2UNIX_VERSION)\" \
                  -DVER_DATE=\"$(DOS2UNIX_DATE)\" \
                  -DVER_AUTHOR=\"$(DOS2UNIX_AUTHOR)\" \
                  -DDEBUG=$(DEBUGMSG) \
                  $(CFLAGS_OS) \
                  $(CFLAGS_COMPILER)

ifeq ($(DEBUG), 1)
        EXTRA_CFLAGS += -g
endif

ifdef STATIC
        EXTRA_CFLAGS += -static
endif

ifdef UCS
        EXTRA_CFLAGS += -DD2U_UNICODE
endif
ifdef UNIFILE
        EXTRA_CFLAGS += -DD2U_UNIFILE
endif


ifdef LFS
        EXTRA_CFLAGS += -D_LARGEFILE_SOURCE -D_FILE_OFFSET_BITS=64
endif

LDFLAGS_USER    =
LDFLAGS = $(RPM_LD_FLAGS) $(LDFLAGS_EXTRA) $(LDFLAGS_USER)
LIBS    = $(LIBS_EXTRA)

DEFS_USER       =
DEFS            = $(EXTRA_DEFS) $(DEFS_USER)

# .......................................................... targets ...

all: $(BIN) $(MAC2UNIX_BIN) $(UNIX2DOS_BIN) $(UNIX2MAC_BIN) doc \
     mofiles man

status:
	@echo "D2U_OS       = $(D2U_OS)"
	@echo "UCS          = $(UCS)"
	@echo "CFLAGS       = $(CFLAGS)"
	@echo "EXTRA_CFLAGS = $(EXTRA_CFLAGS)"
	@echo "LDFLAGS      = $(LDFLAGS)"
	@echo "LIBS         = $(LIBS)"

common.o : common.c common.h dos2unix.h unix2dos.h version.mk
	$(CC) $(DEFS) $(EXTRA_CFLAGS) $(DOS2UNIX_NLSDEFS) $(CFLAGS) -c $< -o $@

querycp.o : querycp.c querycp.h
	$(CC) $(DEFS) $(EXTRA_CFLAGS) $(DOS2UNIX_NLSDEFS) $(CFLAGS) -c $< -o $@

dos2unix.o : dos2unix.c dos2unix.h querycp.h common.h
	$(CC) $(DEFS) $(EXTRA_CFLAGS) $(DOS2UNIX_NLSDEFS) $(CFLAGS) -c $< -o $@

unix2dos.o : unix2dos.c unix2dos.h querycp.h common.h
	$(CC) $(DEFS) $(EXTRA_CFLAGS) $(DOS2UNIX_NLSDEFS) $(CFLAGS) -c $< -o $@

$(BIN): dos2unix.o querycp.o common.o
	$(CC) $+ $(LDFLAGS) $(LIBS) -o $@

$(UNIX2DOS_BIN): unix2dos.o querycp.o common.o
	$(CC) $+ $(LDFLAGS) $(LIBS) -o $@

# DJGPP supports linking of .EXEs via 'stubify'.
# See djgpp.mak and http://www.delorie.com/djgpp/v2faq/faq22_5.html
# ln -s does automatic stubify in DJGPP 2.03.
# This changed in DJGPP 2.05. DJGPP 2.05 emulates symbolic links.

$(MAC2UNIX_BIN) : $(BIN)
ifneq ($(DJGPP),)
	stubify -g $@ ; stubedit $@ runfile=$<
else
	$(LINK) $< $@
endif


$(UNIX2MAC_BIN) : $(UNIX2DOS_BIN)
ifneq ($(DJGPP),)
	stubify -g $@ ; stubedit $@ runfile=$<
else
	$(LINK) $< $@
endif

$(MANPOTFILE) : man/man1/dos2unix.pod
	$(MAKE) -C man/man1 ../../po-man/$(notdir $@)

#  WARNING: Backward-incompatibility since GNU make 3.82.
#  The pattern-specific variables and pattern rules are now applied in the
#  shortest stem first order instead of the definition order (variables
#  and rules with the same stem length are still applied in the definition
#  order).
#  In order to stay compatible with GNU make < 3.82 we put the rule with
#  the shortest stem first.

po/%.po : $(POT)
	msgmerge --no-wrap -U $@ $(POT) --backup=numbered
	# change timestamp in case .po file was not updated.
	touch $@

%.po : man/man1/dos2unix.pod
	$(MAKE) -C man/man1 $(subst po-man/,../../po-man/,$@)

man/%/man1/dos2unix.pod : po-man/%.po
	$(MAKE) -C man/man1 $(subst man/,../,$@)

# empty recipe to break circular dependency
man/man1/dos2unix.pod : ;

%.1 : %.pod
	$(MAKE) -C man/man1 PODCENTER=$(DOS2UNIX_DATE) $(subst man/,../,$@)

mofiles: $(MOFILES)

html: $(HTMLFILES_EN) $(HTMLFILES)

txt: $(TXTFILES_EN) $(TXTFILES)

ps: $(PSFILES_EN) $(PSFILES)

pdf: $(PDFFILES_EN) $(PDFFILES)

man: $(MANFILES_EN) $(MANFILES) $(MANPOTFILE)

doc: txt html

tags: $(POT)

merge: $(POFILES)

# Get new po files from the Translation Project.
getpo:
	rsync -Lrtvz  translationproject.org::tp/latest/dos2unix/  po/incoming/

getpoman:
	rsync -Lrtvz  translationproject.org::tp/latest/dos2unix-man/  po-man/incoming/

%.mo : %.po
	msgfmt -c $< -o $@

$(POT) : dos2unix.c unix2dos.c common.c
	xgettext -C -cTRANSLATORS: --no-wrap --keyword=_ $+ -o $(POT)

%.txt : %.pod
	pod2text $< > $@

README.txt INSTALL.txt NEWS.txt ChangeLog.txt COPYING.txt TODO.txt BUGS.txt: ;

%.ps : %.1
	groff -man $< -T ps > $@

%.pdf: %.ps
	ps2pdf $< $@

# Since perl 5.18 pod2html generates HTML with all non-ASCII characters encoded
# with HTML Ampersand Character Codes. This seems to be better browser compatible
# than HTML in UTF-8 format. PERL_UNICODE=SDA is needed to get a correct UTF-8
# encoded title.
# With perl < 5.18 you have to remove PERL_UNICODE=SDA, and then you get HTML pages
# in UTF-8 format.

# Generic rule.
%.$(HTMLEXT) : %.pod
	PERL_UNICODE=SDA pod2html --title="$(PACKAGE) $(DOS2UNIX_VERSION) - DOS/MAC to UNIX and vice versa text file format converter" $< > $@

man/de/man1/$(PACKAGE).$(HTMLEXT) : man/de/man1/$(PACKAGE).pod
	PERL_UNICODE=SDA pod2html --title="$(PACKAGE) $(DOS2UNIX_VERSION) - Formatumwandlung für Textdateien von DOS/Mac nach Unix und umgekehrt" $< > $@

man/es/man1/$(PACKAGE).$(HTMLEXT) : man/es/man1/$(PACKAGE).pod
	PERL_UNICODE=SDA pod2html --title="$(PACKAGE) $(DOS2UNIX_VERSION) - Convertidor de archivos de texto de formato DOS/Mac a Unix y viceversa" $< > $@

man/fr/man1/$(PACKAGE).$(HTMLEXT) : man/fr/man1/$(PACKAGE).pod
	PERL_UNICODE=SDA pod2html --title="$(PACKAGE) $(DOS2UNIX_VERSION) - Convertit les fichiers textes du format DOS/Mac vers Unix et inversement" $< > $@

man/nl/man1/$(PACKAGE).$(HTMLEXT) : man/nl/man1/$(PACKAGE).pod
	PERL_UNICODE=SDA pod2html --title="$(PACKAGE) $(DOS2UNIX_VERSION) - DOS/Mac naar Unix en vice versa tekstbestand formaat omzetter" $< > $@

man/pl/man1/$(PACKAGE).$(HTMLEXT) : man/pl/man1/$(PACKAGE).pod
	PERL_UNICODE=SDA pod2html --title="$(PACKAGE) $(DOS2UNIX_VERSION) - konwerter formatu plików tekstowych między systemami DOS/Mac a Uniksem" $< > $@

man/pt_BR/man1/$(PACKAGE).$(HTMLEXT) : man/pt_BR/man1/$(PACKAGE).pod
	PERL_UNICODE=SDA pod2html --title="$(PACKAGE) $(DOS2UNIX_VERSION) - Conversor de formato de arquivo texto de DOS/Mac para Unix e vice-versa" $< > $@

man/uk/man1/$(PACKAGE).$(HTMLEXT) : man/uk/man1/$(PACKAGE).pod
	PERL_UNICODE=SDA pod2html --title="$(PACKAGE) $(DOS2UNIX_VERSION) - програма для перетворення даних у текстовому форматі DOS/Mac у формат Unix, і навпаки" $< > $@

man/zh_CN/man1/$(PACKAGE).$(HTMLEXT) : man/zh_CN/man1/$(PACKAGE).pod
	PERL_UNICODE=SDA pod2html --title="$(PACKAGE) $(DOS2UNIX_VERSION) - DOS/Mac - Unix文件格式转换器" $< > $@

man/sv/man1/$(PACKAGE).$(HTMLEXT) : man/sv/man1/$(PACKAGE).pod
	PERL_UNICODE=SDA pod2html --title="$(PACKAGE) $(DOS2UNIX_VERSION) - textfilsformatskonverterare från DOS/Mac till Unix och vice versa" $< > $@

test: all
ifneq ($(DJGPP),)
	cd test; $(MAKE) test UCS= SHELL=$(shell which sh)
else
	cd test; $(MAKE) test UCS=$(UCS)
endif

check: test

install-bin: $(BIN) $(MAC2UNIX_BIN) $(UNIX2DOS_BIN) $(UNIX2MAC_BIN)
	$(MKDIR) -p -m 755 $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) $(BIN) $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) $(UNIX2DOS_BIN) $(DESTDIR)$(bindir)
ifneq ($(DJGPP),)
	cd $(DESTDIR)$(bindir); stubify -g $(MAC2UNIX_BIN) ; stubedit $(MAC2UNIX_BIN) runfile=$(BIN)
	cd $(DESTDIR)$(bindir); stubify -g $(UNIX2MAC_BIN) ; stubedit $(UNIX2MAC_BIN) runfile=$(UNIX2DOS_BIN)
else
ifeq ($(LINK),cp -f)
	$(INSTALL_PROGRAM) $(MAC2UNIX_BIN) $(DESTDIR)$(bindir)
	$(INSTALL_PROGRAM) $(UNIX2MAC_BIN) $(DESTDIR)$(bindir)
else
	cd $(DESTDIR)$(bindir); $(LINK) $(BIN) $(MAC2UNIX_BIN)
	cd $(DESTDIR)$(bindir); $(LINK) $(UNIX2DOS_BIN) $(UNIX2MAC_BIN)
endif
endif


install-man: man
	$(MKDIR) -p -m 755 $(DESTDIR)$(man1dir)
	$(INSTALL_DATA) $(MANFILES_EN) $(DESTDIR)$(man1dir)
ifeq ($(LINK_MAN),cp -f)
	$(INSTALL_DATA) $(MANFILES_EN) $(DESTDIR)$(man1dir)/$(MAC2UNIX).1
	$(INSTALL_DATA) $(MANFILES_EN) $(DESTDIR)$(man1dir)/$(UNIX2DOS).1
	$(INSTALL_DATA) $(MANFILES_EN) $(DESTDIR)$(man1dir)/$(UNIX2MAC).1
else
	cd $(DESTDIR)$(man1dir); $(LINK_MAN) $(PACKAGE).1 $(MAC2UNIX).1
	cd $(DESTDIR)$(man1dir); $(LINK_MAN) $(PACKAGE).1 $(UNIX2DOS).1
	cd $(DESTDIR)$(man1dir); $(LINK_MAN) $(PACKAGE).1 $(UNIX2MAC).1
endif
ifdef ENABLE_NLS
	$(foreach manfile, $(MANFILES), $(MKDIR) -p -m 755 $(DESTDIR)$(datarootdir)/$(dir $(manfile)) ;)
	$(foreach manfile, $(MANFILES), $(INSTALL_DATA) $(manfile) $(DESTDIR)$(datarootdir)/$(dir $(manfile)) ;)
	$(foreach manfile, $(MANFILES), cd $(DESTDIR)$(datarootdir)/$(dir $(manfile)) ; $(LINK_MAN) $(PACKAGE).1 $(MAC2UNIX).1 ;)
	$(foreach manfile, $(MANFILES), cd $(DESTDIR)$(datarootdir)/$(dir $(manfile)) ; $(LINK_MAN) $(PACKAGE).1 $(UNIX2DOS).1 ;)
	$(foreach manfile, $(MANFILES), cd $(DESTDIR)$(datarootdir)/$(dir $(manfile)) ; $(LINK_MAN) $(PACKAGE).1 $(UNIX2MAC).1 ;)
endif

install-mo: mofiles
ifdef ENABLE_NLS
	@echo "-- install-mo"
	$(foreach mofile, $(MOFILES), $(MKDIR) -p -m 755 $(DESTDIR)$(localedir)/$(basename $(notdir $(mofile)))/LC_MESSAGES ;)
	$(foreach mofile, $(MOFILES), $(INSTALL_DATA) $(mofile) $(DESTDIR)$(localedir)/$(basename $(notdir $(mofile)))/LC_MESSAGES/$(PACKAGE).mo ;)
endif

install-doc: doc
	@echo "-- install-doc"
	$(MKDIR) -p -m 755 $(DESTDIR)$(docdir)
	$(INSTALL_DATA) $(INSTALL_OBJS_DOC) $(DESTDIR)$(docdir)
	$(INSTALL_DATA) $(TXTFILES_EN) $(DESTDIR)$(docdir)
	$(INSTALL_DATA) $(HTMLFILES_EN) $(DESTDIR)$(docdir)
ifdef ENABLE_NLS
	$(foreach txtfile, $(TXTFILES), $(MKDIR) -p -m 755 $(DESTDIR)$(docdir)/$(word 2,$(subst /, ,$(txtfile),)) ;)
	$(foreach txtfile, $(TXTFILES), $(INSTALL_DATA) $(txtfile) $(DESTDIR)$(docdir)/$(word 2,$(subst /, ,$(txtfile),)) ;)
	$(foreach htmlfile, $(HTMLFILES), $(MKDIR) -p -m 755 $(DESTDIR)$(docdir)/$(word 2,$(subst /, ,$(htmlfile),)) ;)
	$(foreach htmlfile, $(HTMLFILES), $(INSTALL_DATA) $(htmlfile) $(DESTDIR)$(docdir)/$(word 2,$(subst /, ,$(htmlfile),)) ;)
endif

# No dependency. Install pdf/ps only when they have been manually generated.
install-pdf:
	@echo "-- install-pdf"
	$(MKDIR) -p -m 755 $(DESTDIR)$(docdir)
	$(foreach pdffile, $(wildcard man/man1/*.pdf), $(INSTALL_DATA) $(pdffile) $(DESTDIR)$(docdir) ;)
	$(foreach psfile, $(wildcard man/man1/*.ps), $(INSTALL_DATA) $(psfile) $(DESTDIR)$(docdir) ;)
ifdef ENABLE_NLS
	$(foreach pdffile, $(wildcard man/*/man1/*.pdf), $(MKDIR) -p -m 755 $(DESTDIR)$(docdir)/$(word 2,$(subst /, ,$(pdffile),)) ;)
	$(foreach pdffile, $(wildcard man/*/man1/*.pdf), $(INSTALL_DATA) $(pdffile) $(DESTDIR)$(docdir)/$(word 2,$(subst /, ,$(pdffile),)) ;)
	$(foreach psfile, $(wildcard man/*/man1/*.ps), $(MKDIR) -p -m 755 $(DESTDIR)$(docdir)/$(word 2,$(subst /, ,$(psfile),)) ;)
	$(foreach psfile, $(wildcard man/*/man1/*.ps), $(INSTALL_DATA) $(psfile) $(DESTDIR)$(docdir)/$(word 2,$(subst /, ,$(psfile),)) ;)
endif

install: install-bin install-man install-mo install-doc
	# Run a new instance of 'make' otherwise the $$(wildcard ) function my not have been expanded,
	# because the files may not have been there when make was started.
	$(MAKE) install-pdf

uninstall:
	@echo "-- target: uninstall"
	-rm -f $(DESTDIR)$(bindir)/$(BIN)
	-rm -f $(DESTDIR)$(bindir)/$(MAC2UNIX_BIN)
	-rm -f $(DESTDIR)$(bindir)/$(UNIX2DOS_BIN)
	-rm -f $(DESTDIR)$(bindir)/$(UNIX2MAC_BIN)
	-rm -f $(DESTDIR)$(mandir)/man1/$(PACKAGE).1
	-rm -f $(DESTDIR)$(mandir)/man1/$(MAC2UNIX).1
	-rm -f $(DESTDIR)$(mandir)/man1/$(UNIX2DOS).1
	-rm -f $(DESTDIR)$(mandir)/man1/$(UNIX2MAC).1
	-rm -rf $(DESTDIR)$(docdir)
ifdef ENABLE_NLS
	$(foreach mofile, $(MOFILES), rm -f $(DESTDIR)$(localedir)/$(basename $(notdir $(mofile)))/LC_MESSAGES/$(PACKAGE).mo ;)
	$(foreach manfile, $(MANFILES), rm -f $(DESTDIR)$(datarootdir)/$(manfile) ;)
	$(foreach manfile, $(MANFILES), rm -f $(DESTDIR)$(datarootdir)/$(dir $(manfile))$(MAC2UNIX).1 ;)
	$(foreach manfile, $(MANFILES), rm -f $(DESTDIR)$(datarootdir)/$(dir $(manfile))$(UNIX2DOS).1 ;)
	$(foreach manfile, $(MANFILES), rm -f $(DESTDIR)$(datarootdir)/$(dir $(manfile))$(UNIX2MAC).1 ;)
endif

mostlyclean:
	rm -f *.o
	rm -f $(BIN) $(UNIX2DOS_BIN) $(MAC2UNIX_BIN) $(UNIX2MAC_BIN)
	rm -f *.bak *~
	rm -f *.tmp
	rm -f man/man1/*.bak man/man1/*~
	rm -f man/*/man1/*.bak man/*/man1/*~
	rm -f po/*.bak po/*~
	rm -f po/*.mo po-man/*~
	cd test; $(MAKE) clean

# Don't distribute PostScript and PDF manuals in the source package.
# We don't want binary PDF files in the source package, because
# some packagers check in the source files. PostScript is not used
# a lot.

clean: mostlyclean
	rm -f man/man1/*.ps
	rm -f man/man1/*.pdf
	rm -f man/*/man1/*.ps
	rm -f man/*/man1/*.pdf

distclean: clean

# Because there is so much trouble with generating man pages with
# pod2man, due to old Perl versions (< 5.10.1) on many systems, I include the
# man pages in the source tar file.
# Old pod2man versions do not have the --utf8 option. Old pod2man, pod2text,
# and pod2html do not support the =encoding command.
# Perl 5.18 pod2man demands an =encoding command for Latin-1 encoded POD files.
#
# Newer perl/pod2man versions produce better output. It is better to include
# man pages in the source package, than that people generate them themselves
# with old perl versions.

maintainer-clean: distclean
	@echo 'This command is intended for maintainers to use; it'
	@echo 'deletes files that may need special tools to rebuild.'
	rm -f man/man1/*.1
	rm -f man/man1/*.txt
	rm -f man/man1/*.$(HTMLEXT)
	rm -f po-man/dos2unix-man.pot
	rm -f man/*/man1/*.1
	rm -f man/*/man1/*.txt
	rm -f man/*/man1/*.pod
	rm -f man/*/man1/*.$(HTMLEXT)

realclean: maintainer-clean


ZIPOBJ  = bin/$(BIN) \
          bin/$(MAC2UNIX_BIN) \
          bin/$(UNIX2DOS_BIN) \
          bin/$(UNIX2MAC_BIN) \
          share/man/man1/$(PACKAGE).1 \
          share/man/man1/$(MAC2UNIX).1 \
          share/man/man1/$(UNIX2DOS).1 \
          share/man/man1/$(UNIX2MAC).1 \
          share/doc/$(docsubdir)/*.* \
          $(ZIPOBJ_EXTRA)

ifdef ENABLE_NLS
ZIPOBJ += share/locale/*/LC_MESSAGES/$(PACKAGE).mo
ZIPOBJ += share/man/*/man1/$(PACKAGE).1 \
          share/man/*/man1/$(MAC2UNIX).1 \
          share/man/*/man1/$(UNIX2DOS).1 \
          share/man/*/man1/$(UNIX2MAC).1
ZIPOBJ += share/doc/$(docsubdir)/*/*
endif

ZIPFILE = $(PACKAGE)-$(DOS2UNIX_VERSION)$(VERSIONSUFFIX)$(NLSSUFFIX).zip
TGZFILE = $(PACKAGE)-$(DOS2UNIX_VERSION)$(VERSIONSUFFIX)$(NLSSUFFIX).tar.gz
TBZFILE = $(PACKAGE)-$(DOS2UNIX_VERSION)$(VERSIONSUFFIX)$(NLSSUFFIX).tar.bz2

dist-convert/%:
	rm -f $(prefix)/$(ZIPFILE)
	cd $(prefix) ; $* --keepdate share/man/man1/$(PACKAGE).1 share/man/man1/$(MAC2UNIX).1 share/man/man1/$(UNIX2DOS).1 share/man/man1/$(UNIX2MAC).1
	cd $(prefix) ; $* --keepdate --add-bom share/doc/$(docsubdir)/*.txt
	cd $(prefix) ; $* --keepdate share/doc/$(docsubdir)/*.$(HTMLEXT)
ifdef ENABLE_NLS
	cd $(prefix) ; $* --keepdate share/man/*/man1/$(PACKAGE).1 share/man/*/man1/$(MAC2UNIX).1 share/man/*/man1/$(UNIX2DOS).1 share/man/*/man1/$(UNIX2MAC).1
	cd $(prefix) ; $* --keepdate --add-bom share/doc/$(docsubdir)/*/*.txt
	cd $(prefix) ; $* --keepdate share/doc/$(docsubdir)/*/*.$(HTMLEXT)
endif

dist-zip: dist-convert/unix2dos
	cd $(prefix) ; zip -r $(ZIPFILE) $(ZIPOBJ)
	mv -f $(prefix)/$(ZIPFILE) ..

dist-tgz: dist-convert/dos2unix
	cd $(prefix) ; tar cvzf $(TGZFILE) $(ZIPOBJ)
	mv $(prefix)/$(TGZFILE) ..

dist-tbz: dist-convert/dos2unix
	cd $(prefix) ; tar cvjf $(TBZFILE) $(ZIPOBJ)
	mv $(prefix)/$(TBZFILE) ..

dist: $(DIST_TARGET)

strip:
	$(STRIP) $(BIN)
	$(STRIP) $(UNIX2DOS_BIN)
ifeq ($(LINK),cp -f)
	$(STRIP) $(MAC2UNIX_BIN)
	$(STRIP) $(UNIX2MAC_BIN)
endif

# End of file
