#!/usr/bin/env zsh -f

###############################################################################
# This code is licensed under the GPL v3.  See LICENSE.txt for details.
#
# Copyright 2007 Nathaniel Gray.
# Copyright 2012-2018 Anthony Gelibert.
#
# Expects   $1 = name of file to colorize
#           $2 = 1 if you want enough for a thumbnail, 0 for the full file
#
# Produces HTML on stdout with exit code 0 on success
###############################################################################

# Fail immediately on failure of sub-command
setopt err_exit

# Set the read-only variables
target="$1"
thumb="$2"
cmd="$pathHL"

function debug() {
    if [ "x$qlcc_debug" != "x" ]; then
        echo "$@" >> ~/Desktop/colorize.log
    fi
}

if [ "x$qlcc_debug" != "x" ]; then
    echo `date +"%Y-%m-%d %H:%M:%S"` > ~/Desktop/colorize.log
    # file to store stderr
    err_device=~/Desktop/colorize.log
else
    err_device=/dev/stderr
fi

debug "Starting colorize.sh by setting reader"
#debug "target: ${target}"
#debug "thumb: ${thumb}"
#debug "cmd: ${cmd}"

reader=(cat "${target}")

debug "Handling special cases"
case ${target} in
    *.graffle | *.ps )
        exit 1
        ;;
    *.iml )
        lang=xml
        ;;
    *.d )
        lang=make
        ;;
    *.fxml )
        lang=fx
        ;;
    *.s | *.s79 )
        lang=assembler
        ;;
    *.sb )
        lang=lisp
        ;;
    *.java )
        lang=java
        plugin=(--plug-in java_library)
        ;;
    *.class )
        lang=java
        reader=(/usr/local/bin/jad -ff -dead -noctor -p -t "${target}")
        plugin=(--plug-in java_library)
        ;;
    *.pde | *.ino )
        lang=c
        ;;
    *.c | *.cpp | *.ino )
        lang=${target##*.}
        # plugin=(--plug-in cpp_syslog --plug-in cpp_ref_cplusplus_com --plug-in cpp_ref_local_includes)
        plugin=(--plug-in cpp_syslog)
        ;;
    *.rdf | *.xul | *.ecore )
        lang=xml
        ;;
    *.ascr | *.scpt )
        lang=applescript
        reader=(/usr/bin/osadecompile "${target}")
        ;;
    *.plist )
        lang=xml
        reader=(/usr/bin/plutil -convert xml1 -o - "${target}")
        ;;
    *.sql )
        if grep -q -E "SQLite .* database" <(file -b "${target}"); then
            exit 1
        fi
        lang=sql
        ;;
    *.m )
        lang=objc
        ;;
    *.pch | *.h )
        if grep -q "@interface" <(${target}) &> /dev/null; then
            lang=objc
        else
            lang=h
        fi
        ;;
    *.pl )
        lang=pl
        # plugin=(--plug-in perl_ref_perl_org)
        ;;
    *.py )
        lang=py
        # plugin=(--plug-in python_ref_python_org)
        ;;
    *.sh | *.zsh | *.bash | *.csh | *.fish | *.bashrc | *.zshrc )
        lang=sh
        plugin=(--plug-in bash_functions)
        ;;
    *.scala )
        lang=scala
        # plugin=(--plug-in scala_ref_scala_lang_org)
        ;;
    *.cfg | *.properties | *.conf )
        lang=ini
        ;;
    *.kmt )
        lang=scala
        ;;
    * )
        lang=${target##*.}
        ;;
esac

if [[ ${preprocessorHL} != "" ]]; then
    # Split preprocessorHL to an array of arguments using '•' as separator.
    reader=("${(@s/•/)preprocessorHL}")
    # append the target name.
    reader+=("${target}")
fi

debug "Resolved ${target} to language $lang"

go4it () {
    theme="--style=${hlTheme}"
    
    # Split extraHLFlags to an array of arguments using '•' as separator.
    #
    # Do not use zsh {= expansion because it split the string on all space ignoring quotes and causing error.
    cmdExtra=("${(@s/•/)extraHLFlags}")
    
    cmdOpts=(${plugin} --syntax=${lang} --quiet --include-style ${=theme} --encoding=${textEncoding} ${cmdExtra} --validate-input)
    
    function join_by { local IFS="$1"; shift; echo "$*"; }
    
    debug "# command line: "
    debug "${reader} | \"${cmd}\" -T \"${target}\" ${cmdOpts}"
    debug ""
    debug "# environments:"
    env=`set`
    debug join_by ${env}
    debug ""
    
    debug "# generating the preview…"
    if [ "${thumb}" = "1" ]; then
        ${reader} 2>> ${err_device} | head -n 100 | head -c 20000 | "${cmd}" ${cmdOpts} 2>> ${err_device} && exit 0
    elif [ -n "${maxFileSize}" ]; then
        ${reader} 2>> ${err_device} | head -c ${maxFileSize} | "${cmd}" -T "${target}" ${cmdOpts} 2>> ${err_device} && exit 0
    else
        ${reader} 2>> ${err_device} | "${cmd}" -T "${target}" ${cmdOpts} 2>> ${err_device} && exit 0
    fi
}

setopt no_err_exit

go4it
# Uh-oh, it didn't work.  Fall back to rendering the file as plain
debug "# First try failed, second try..."
lang=txt
go4it

debug "# Reached the end of the file. That should not happen."

exit 101
