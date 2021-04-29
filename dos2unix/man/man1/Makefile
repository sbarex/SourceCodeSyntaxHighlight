# pod2man.mk -- Makefile portion to convert *.pod files to manual pages
#
#   Copyright information
#
#       Copyright (C) 2010 Jari Aalto
#       Copyright (C) 2010-2017 Erwin Waterlander
#
#   License
#
#       Redistribution and use in source and binary forms, with or
#       without modification, are permitted provided that the
#       following conditions are met:
#
#       1. Redistributions of source code must retain the above
#          copyright notice, this list of conditions and the following
#          disclaimer.
#
#       2. Redistributions in binary form must reproduce the above
#          copyright notice, this list of conditions and the following
#          disclaimer in the documentation and/or other materials
#          provided with the distribution.
#
#       THIS SOFTWARE IS PROVIDED "AS IS" AND ANY EXPRESS OR
#       IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
#       WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
#       PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR(S) OF THIS
#       FILE OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
#       INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
#       (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
#       GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
#       INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
#       WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
#       NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF
#       THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH
#       DAMAGE.
#
#       The license text is copy of the FreeBSD License available at
#       <http://www.gnu.org/copyleft/gpl.html> with following
#       modifications: wording "THIS SOFTWARE IS PROVIDED BY THE
#       FREEBSD PROJECT" was changed to "THIS SOFTWARE IS PROVIDED 'AS
#       IS'" and wording "IN NO EVENT SHALL THE FREEBSD PROJECT" was
#       changed to "IN NO EVENT SHALL THE AUTHOR(S)"
#
#   Description
#
#       Convert *.pod files to manual pages.

ifneq (,)
    This makefile requires GNU Make.
endif

include ../../version.mk

.PRECIOUS: %.pod

# This variable *must* be set when calling
PACKAGE         ?= dos2unix

# Optional variables to set
MANSECT         ?= 1
PODCENTER       ?= $(DOS2UNIX_DATE)

# Directories
MANSRC          =
MANDEST         = $(MANSRC)

MANPOD          = $(MANSRC)$(PACKAGE).pod
MANPAGE         = $(MANDEST)$(PACKAGE).$(MANSECT)

POD2MAN         = pod2man
POD2MAN_FLAGS   =

POFILES = $(wildcard ../../po-man/*.po)
PODFILES = $(patsubst ../../po-man/%.po,../%/man1/dos2unix.pod,$(POFILES))
MAN_OBJECTS = dos2unix.1 $(patsubst %.pod,%.1,$(PODFILES))

MKDIR = mkdir

all: $(MAN_OBJECTS) ../../po-man/dos2unix-man.pot

# Issues:

# The perl version of MinGW and DJGPP is 5.8.8. The pod2man command of perl
# 5.8.8 does not yet have the options -u, --utf8, and does support the
# =encoding command.  The =encoding command and the --utf8 option are supported
# since perl 5.10.1.
# Erwin W.

# Dos2unix 6.0.5: Forget Latin-1, we do now only UTF-8.

../../po-man/dos2unix-man.pot : dos2unix.pod
	po4a-updatepo -f pod -m $< -p $@ --msgmerge-opt --no-wrap

%.po : dos2unix.pod
	po4a-updatepo -f pod -m $< -p $@ --msgmerge-opt "--backup=numbered --no-wrap"
	# change timestamp in case .po file was not updated.
	touch $@

# Create pod files from po.
# Fix problem that =encoding is before =pod command.
../%/man1/dos2unix.pod : ../../po-man/%.po
	$(MKDIR) -p $(dir $@)
	po4a-translate -f pod -m dos2unix.pod -k 70 -p $< > $@
	perl -ni.bak -e 'print unless /=encoding UTF-8/' $@
	perl -pli.bak -e 's/=pod/=pod\n\n=encoding UTF-8/' $@

# An empty recipe for dos2unix.pod to break circular dependency.
dos2unix.pod : ;

%.1 : %.pod
	# make target - create manual page from a *.pod page
	podchecker $<
	$(POD2MAN) $(POD2MAN_FLAGS) \
		--utf8 \
		--center="$(PODCENTER)" \
		--name="$(PACKAGE)" \
		--section="$(MANSECT)" \
		$< \
	| perl -p -e 's/[Pp]erl v[0-9.]+/$(PACKAGE)/;' \
	  > $@ && \
	rm -f pod*.tmp



clean:
	rm -f $(MAN_OBJECTS)
	rm -f ../../po-man/dos2unix-man.pot
	rm -f $(PODFILES)

# End of of Makefile part
