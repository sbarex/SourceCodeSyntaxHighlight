# Author: Erwin Waterlander
# Copyright (C) 2009-2016 Erwin Waterlander
# This file is distributed under the same license as the dos2unix package.

include version.mk

d2u_os=$(shell uname -s)

# DJGPP 2.03
LINK = ln -sf
# DJGPP 2.05
# In DJGPP 2.05 linking with ln works differently. The links created
# with DJGPP 2.05 do not work.
#LINK = cp -f

# The install and dist targets can be run in MSYS. The OS variable must be
# forced to msdos, otherwise extra targets will get build in MSYS.

# On DOS we need to set SHELL to sh.exe or bash.exe, otherwise targets may fail
# (targets install and dist fail certainly). SHELL can't be overridden in this
# make level. It sticks to command.com (at least with DJGPP 2.03 make 3.79.1).
# SHELL has to be set in a parent process, so we pass it to the sub make instances.
D2U_MAKESHELL=$(shell which sh)

CROSS_COMP=0

ifeq ($(findstring CYGWIN,$(d2u_os)),CYGWIN)
	CROSS_COMP=1
endif

ifeq ($(CROSS_COMP),1)
	CROSS_COMPILE=i586-pc-msdosdjgpp-
	LINK = cp -f
endif

CC=$(CROSS_COMPILE)gcc
STRIP=$(CROSS_COMPILE)strip

prefix=c:/dos32
ENABLE_NLS=
VERSIONSUFFIX=-dos32

ifdef ENABLE_NLS
LIBS_EXTRA = -lintl -liconv
NLS_SUFFIX = -nls
endif
VERSIONSUFFIX = pm
ZIPFILE = d2u$(DOS2UNIX_VERSION_SHORT)$(VERSIONSUFFIX)$(NLS_SUFFIX).zip
ZIPOBJ_EXTRA = bin/cwsdpmi.exe
docsubdir = dos2unix

all:
	$(MAKE) all EXE=.exe ENABLE_NLS=$(ENABLE_NLS) LIBS_EXTRA="$(LIBS_EXTRA)" prefix=$(prefix) LINK="$(LINK)" LINK_MAN="cp -f" docsubdir=$(docsubdir) UCS= CC=$(CC) D2U_OS=msdos SHELL=$(D2U_MAKESHELL)

test: all
	cd test; $(MAKE) test UCS= SHELL=$(D2U_MAKESHELL) 

check: test

install:
	$(MAKE) install EXE=.exe ENABLE_NLS=$(ENABLE_NLS) LIBS_EXTRA="$(LIBS_EXTRA)" prefix=$(prefix) LINK="$(LINK)" LINK_MAN="cp -f" docsubdir=$(docsubdir) UCS= CC=$(CC) D2U_OS=msdos SHELL=$(D2U_MAKESHELL)

uninstall:
	$(MAKE) uninstall EXE=.exe prefix=$(prefix) docsubdir=$(docsubdir) SHELL=$(D2U_MAKESHELL)

clean:
	$(MAKE) clean EXE=.exe ENABLE_NLS=$(ENABLE_NLS) prefix=$(prefix) SHELL=$(D2U_MAKESHELL)

mostlyclean:
	$(MAKE) mostlyclean EXE=.exe ENABLE_NLS=$(ENABLE_NLS) prefix=$(prefix) SHELL=$(D2U_MAKESHELL)

dist:
	$(MAKE) dist-zip EXE=.exe prefix=$(prefix) VERSIONSUFFIX="$(VERSIONSUFFIX)" ZIPOBJ_EXTRA="${ZIPOBJ_EXTRA}" ENABLE_NLS=$(ENABLE_NLS) ZIPFILE=${ZIPFILE} docsubdir=$(docsubdir) SHELL=$(D2U_MAKESHELL)

strip:
	$(MAKE) strip LINK="$(LINK)" LINK_MAN="cp -f" EXE=.exe STRIP=$(STRIP) SHELL=$(D2U_MAKESHELL)
# Fix time stamps. Otherwise make install may rebuild mac2unix unix2mac.
	sleep 10
	touch mac2unix.exe
	touch unix2mac.exe

