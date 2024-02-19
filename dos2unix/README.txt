
dos2unix - DOS/Mac to Unix and vice versa text file format converter.


FILE LIST

        README.txt            : This file.
        INSTALL.txt           : How to build and install.
        COPYING.txt           : distribution license.
        NEWS.txt              : Basic change log for users.
        ChangeLog.txt         : Detailed change log for programmers.
        TODO.txt              : Things to do.
        BUGS.txt              : Known bugs and instructions on reporting new ones.
        DEVEL.txt             : Information about dos2unix' implementation choices.
        man/man1/dos2unix.txt : Dos2unix manual, text format.
        man/man1/dos2unix.htm : Dos2unix manual, HTML format.


PROJECT HOME PAGE

        https://waterlan.home.xs4all.nl/dos2unix.html
        https://dos2unix.sourceforge.io/


HISTORY

        This is an update of Benjamin Lin's implementations of dos2unix and
        unix2dos.  Benjamin Lin's implementations of dos2unix and unix2dos were
        distributed via SunSITE.unc.edu (later MetaLab.unc.edu, now ibiblio)
        and became part of several Linux distributions such as RedHat, Suse,
        Gentoo, and others. This update includes all RedHat patches and fixes
        several other problems. Internationalization has been added and ports
        to DOS, Windows, Cygwin and OS/2 Warp have been made.

        These implementations of dos2unix and unix2dos have been modelled after
        dos2unix/unix2dos under SunOS/Solaris. The first versions were made by
        John Birchfield in 1989, and in 1995 rewritten from scratch by Benjamin
        Lin. Mac to Unix conversion was added by Bernd Johannes Wuebben in
        1998, Unix to Mac conversion by Erwin Waterlander in 2010.

        In 2010 the two separate dos2unix and unix2dos packages have been
        bundled into a single dos2unix package (version 5.0). Support for
        Unicode UTF-16 was added in 2012 (version 6.0). Version 7.0, in 2014,
        was a major code cleanup and added a test suite. 


        Features

        * Native language support.
        * Automatically skips binary and non-regular files.
        * In-place, paired, or stdio mode conversion.
        * Keep original file dates option.
        * 7-bit and iso conversion modes like SunOS dos2unix.
        * Conversion of Unicode UTF-16 files.
        * Handles Unicode Byte Order Mark (BOM).
        * Display file information.
        * Secure.


AUTHORS

        Erwin Waterlander       version 3.2 - 7.5.2  2009-2024
        Christian Wurll         version 3.1          1998
        Bernd Johannes Wuebben  version 3.0          1998
        Benjamin Lin            version 1.1 - 2.3    1994-1995
        John Birchfield         version 1.0          1989

TRANSLATORS

        Since version 6.0.5 dos2unix is part of the Translation Project (TP).
        All translations go via the Translation Project.

        Translation of the messages.
        See https://translationproject.org/domain/dos2unix.html

        Brazilian Portuguese  Enrico Nicoletto             Version 6.0.5
        Brazilian Portuguese  Rafael Ferreira              Version 6.0.6 - 7.2
        Brazilian Portuguese  Rafael Fontenelle            Version 7.3.2 - 7.4.0
        Catalan               Jordi Mas i Hernàndez        Version 7.4.4
        Chinese (simplified)  Tianze Wang                  Version 7.3.1 - 7.4.0
                                                           7.5.1
        Chinese (simplified)  Boyuan Yang                  Version 7.5.0 - 7.5.2
        Chinese (traditional) mail6543210                  Version 6.0.5
        Chinese (traditional) Yi-Jyun Pan                  Version 7.4.2 - 7.5.1
        Danish                Thomas Pryds                 Version 6.0.5 - 6.0.6
        Danish                Joe Hansen                   Version 7.2.3 - 7.4.1
        Dutch                 Erwin Waterlander            Version 4.0   - 6.0.4
        Dutch                 Benno Schulenberg            Version 6.0.5 - 7.5.2
        Esperanto             Rugxulo                      Version 5.1   - 6.0.4
        Esperanto             Benno Schulenberg            Version 6.0.5 - 7.3
        Esperanto             Felipe Castro                Version 7.4.3
        French                Frédéric Marchal             Version 6.0.5 - 7.5.2
        Friulian              Fabio Tomat                  Version 7.4.2
        Georgian              Temuri Doghonadze            Version 7.4.4
        German                Philipp Thomas               Version 5.0   - 6.0.3, 7.0,
                                                           7.2.2 - 7.4.1
        German                Lars Wendler                 Version 6.0.4
        German                Mario Blättermann            Version 6.0.6, 7.1 - 7.2
        German                Roland Illig                 Version 7.4.2 - 7.5.2
        Hungarian             Balázs Úr                    Version 6.0.5 - 7.2.3,
                                                           7.4.0 - 7.4.1
        Hungarian             Gabor Kelemen                Version 7.3.4
        Japanese              Yasuaki Taniguchi            Version 7.1.1
        Japanese              Takeshi Hamasaki             Version 7.3.4 - 7.4.1
        Korean                Seong-ho Cho                 Version 7.4.4 - 7.5.2
        Norwegian Bokmaal     Åka Sikrom                   Version 6.0.6 - 7.4.0
        Norwegian Bokmaal     Johnny A. Solbu              Version 7.5.0 - 7.5.2
        Polish                Jakub Bogusz                 Version 6.0.5 - 7.5.2
        Romanian              Remus-Gabriel Chelu          Version 7.4.4 - 7.5.2
        Russian               Андрей Углик (Andrei Uhlik)  Version 6.0.4
        Russian               Yuri Kozlov                  Version 6.0.6 - 7.5.2
        Serbian               Мирослав Николић             Version 6.0.5 - 7.5.2
        Spanish               Julio A. Freyre-Gonzalez     Version 5.3.1 - 6.0.4
        Spanish               Enrique Lazcorreta Puigmartí Version 6.0.6 - 7.3.1
        Swedish               Sebastian Rasmussen          Version 7.3.2 - 7.5.2
        Swedish               Luna Jernberg                Version 7.5.2
        Ukrainian             Yuri Chornoivan              Version 6.0.5 - 7.5.2
        Vietnamese            Trần Ngọc Quân               Version 6.0.5 - 7.5.2

        Translation of the manual.
        See https://translationproject.org/domain/dos2unix-man.html

        Brazilian Portuguese  Rafael Ferreira              Version 6.0.5 - 7.2
        Brazilian Portuguese  Rafael Fontenelle            Version 7.3.2 - 7.4.0
        Chinese (simplified)  Tianze Wang                  Version 7.3.1 - 7.4.0
                                                           7.5.1
        Chinese (simplified)  Boyuan Yang, Tianze Wang     Version 7.4.4
        Chinese (simplified)  Boyuan Yang                  Version 7.5.0
        Dutch                 Erwin Waterlander            Version 5.1.1 - 6.0.4
        Dutch                 Benno Schulenberg            Version 6.0.5 - 7.3.3
        French                Frédéric Marchal             Version 6.0.5 - 7.5.2
        German                Mario Blättermann            Version 6.0.5 - 7.5.2
        German                Roland Illig                 Version 7.4.2
        Korean                Seong-ho Cho                 Version 7.4.4 - 7.5.2
        Polish                Jakub Bogusz                 Version 6.0.5 - 7.5.2
        Romanian              Remus-Gabriel Chelu          Version 7.4.4 - 7.5.2
        Serbian               Мирослав Николић             Version 7.4.3 - 7.5.1
        Spanish               Julio A. Freyre-Gonzalez     Version 5.3.1 - 6.0.4
        Spanish               Enrique Lazcorreta Puigmartí Version 6.0.6 - 7.2.1
        Swedish               Sebastian Rasmussen          Version 7.3.2 - 7.5.2
        Ukrainian             Yuri Chornoivan              Version 6.0.5 - 7.5.2


ACKNOWLEDGEMENTS

        Rugxulo               query_con_codepage(), code page detection in DOS.
        Rugxulo               DJGPP stubs for mac2unix and unix2mac.
        Jari Aalto            Improvements man page.
        Jari Aalto            Improvements Makefile.
        Ben Pfaff             Treat form feeds as valid text.
        Marc Gianzero         Darwin OS port.
        Elbert Pol            OS/2 port.
        Tim Waugh             Various patches.
        Mike Harris           Man page update.
        Bernard RosenKraenzer segfault patch.
        Tim Powers            mkstemp patch.
        Miloslav Trmac        safeconv patch.
        Charles Wilson        Follow symbolic links.
        Charles Wilson        Makefile and code cleanup for Cygwin.
        Christopher Williams  Maintain file ownership in old file mode.
        Steven H. Levine      Support wildcard expansion on OS/2.
        Steve Hay             Support wildcard expansion on win64.
        Michael Schindler     Fixed compiler warning.
        Somsak Pattanaprateep Print line number when binary symbol is found.
        Justin Lecher         Makefile improvement.
        F.J. Brandelik        Reported problems when win32 version processes
                              huge files on a network drive.
        Benno Schulenberg     Cleaning up the UI messages.
        Mario Blättermann     Generate pod files from gettext po files with po4a.
        Daniel Macks          Reported dependency on GNU sed.
        Alan S. Jones         Reported bug in UTF-16 conversion by mac2unix.
        Alan S. Jones         Idea for an info option, to list file statistics
                              about line breaks and byte order marks.
        Alan S. Jones         New flags h (print header) and p (show file names
                              without path) for option -i, --info
        Gary Johnson          Idea for an info option, to list only files which have
                              DOS line breaks, or only files with Unix line breaks.
        Helmut Karlowski      Makefile and PrintVersion() update for freeMiNT.
        Tom Christiansen      Fix for wrong title in HTML manuals.
        Armin Müller          Fixed typo in if condition in write_bom().
        Philip Rowlands       Reported that dos2unix was not checking for file I/O
                              errors while reading the input.
        Baruch Siach          Fix compilation error "'wchar_t' undeclared"
                              when Unicode support is disabled.
        Ulf-Dietrich Braumann Reported that the -iso option was misinterpreted
                              as a corrupted -i option.
        Hans Passant          Correct redirection of unicode UTF-16 screen output.
        anonymous             Don't install international man pages when NLS
                              is disabled.
        Beep6581              Improved example for recursive conversion.
        kirowata              Fixed a minor memory leak.
        Than Ngo              Fixed issues reported by Coverity Scan.
        Vladislav Glinsky     Reported typo in Ukrainian translation.        
        Philipp Klaus Krause  Assign strerror return value to const char.
        Victor                Reported that GB18030 conversion is not working on Darwin.
        Victor                Idea for 'to standard output' mode (option -O).
        anonymous             Idea for adding a newline to the last line if there isn't
                              one (option -e).
        fdamien12             Reported problem of converting  a symbolic link target
                              that is on another file system.
        Dimitry Andric        Aligned Dutch help text.


FINDUTILS

        Windows users who are looking for the Unix 'find' and 'xargs' commands
        can find them in the findutils package for Windows at the ezwinports
        project page at: https://sourceforge.net/projects/ezwinports/files/

        A DOS version of the findutils package can be obtained from the DJGPP
        project (https://www.delorie.com/djgpp/) at
        ftp://ftp.delorie.com/pub/djgpp/current/v2gnu/

CONTACT INFORMATION

        Project home page        : https://waterlan.home.xs4all.nl/dos2unix.html
        SourceForge project page : https://sourceforge.net/projects/dos2unix/

        Erwin Waterlander
        waterlan@xs4all.nl
        https://waterlan.home.xs4all.nl/

        If you need support you can email me directly or make a ticket on the
        SourceForge project page. Help in any form is appreciated. A problem
        report, a fix, or just a remark.
