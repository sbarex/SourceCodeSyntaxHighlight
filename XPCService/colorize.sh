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
        # create a temporary file
        tmpfile=$(mktemp -t colorize)
        echo "tempfile: $tmpfile"  >> ${err_device}
        
        # apply preprocessor
        ${reader} > "$tmpfile" 2>> ${err_device}
        
        # get file size
        bytes=$((`cat "$tmpfile" | wc -c` + 0))
        echo "Bytes: $bytes"  >> ${err_device}
        
        # Convert to number.
        bytes=$((bytes + 0))
        maxFileSize=$((maxFileSize + 0))
        
        if [ $bytes -gt $maxFileSize ]; then
            echo "Truncate data to ${maxFileSize} bytes."  >> ${err_device}
            comment1=""
            comment2=""
            case ${lang} in
                abap4 | abp | abc | express | exp | vimscript | vim | vimrc )
                    comment1="\""
                    ;;
                abnf | ascend | a4c | delphi | pas | dpr | ebnf | ebnf2 | innosetup | iss | lotos | mod2 | mod | def | mod3 | m3 | i3 | oberon | ooc | ocaml | ml | mli | pas | polygen | grm | tex | sty | cls | znn )
                    comment1="(* "
                    comment2=" *)"
                    ;;
                actionscript | as | assembler | asm | a51 | 29k | 68s | 68x | x86 | ballerina | bal | bcpl | biferno | bfr | bison | y | bnf | c | c++ | cpp | cxx | cc | h | hh | hxx | hpp | cu | ceylon | chpl | clean | icl | clipper | coldfusion | cfc | cfm | csharp | cs | d | dart | dylan | fame | frink | fsharp | fs | fsx | fx | go | graphviz | dot | haxe | hx | hugo | hug | idl | interlis | ili | java | groovy | grv | jenkinsfile | gradle | js | json | kotlin | kt | less | lindenscript | lsl | luban | lbn | maple | mpl | maya | mel | modelica | mo | nbc | nemerle | n | nxc | objc | m | os | php | php3 | php4 | php5 | php6 | pike | pmod | pov | pure | qml | rpg | rs | sas | scad | scilab | sci | sce | scss | small | sma | solidity | sol | squirrel | nut | styl | swift | ts | ttcn3 | vala | verilog | v | whiley | yang)
                    comment1="//"
                    ;;
                ada | adb | ads | a | gnad | agda | alan | i | applescript | eiffel | e | se | euphoria | ex | exw | wxu | ew | eu | haskell | hs | lua | ms | mssql | netrexx | nrx | oorexx | pl1 | ff | fp | pp | rpp | sf | sp | spb | spp | sps | wp | wf | wpp | wps | wpb | bdy | spe | rexx | rex | the | rx | snmp | mib | smisql | sybase | sp | tsql | vhd )
                    comment1="--"
                    ;;
                algol | alg | ampl | dat | run | amtrix | s4 | s4t | s4h | hnd | t4 | awk | bms | boo | cmake | conf | anacrontab | crk | crystal | cr | cs_block_regex | docker | dockerfile | dts | dtsi | elixir | ex | exs | fish | fstab | gdb | gdscript | gd | hcl | httpd | icon | icn | informix | 4gl | julia | jl | ldif | limbo | b | make | mak | mk | makefile | meson | n3 | ttl | nt | nasal | nas | nginx | nim | octave | perl | pl | cgi | pm | plx | plex | po | ps1 | psl | pyrex | pyx | python | py | q | qmake | pro | qu | r | rnc | ruby | rb | pp | rjs | gemfile | rakefile | s | sh | bash | zsh | ebuild | eclass | spec | tcl | wish | itcl | tcsh | terraform | toml | yaml | yml )
                    comment1="#"
                    ;;
                arc | aspect | was | wud | assembler | asm | a51 | 29k | 68s | 68x | x86 | autohotkey | ahk | autoit | au3 | blitzbasic | bb | clojure | clj | clp | exapunks | exa | fasm | asm | inc | felix | flx | idlang | ini | doxyfile | desktop | kdev3 | jasmin | j | lisp | cl | clisp | el | lsp | sbcl | scom | fas | scm | msl | nbs | nsis | nsi | nsh | paradox | sc | purebasic | pb | pbi | pbf | rebol )
                    comment1=";"
                    ;;
                arm | bat | cmd | vb | bas | basic | bi | vbs )
                    comment1="rem"
                    ;;
                asciidoc )
                    comment1="////"
                    comment2="////"
                    ;;
                asp | aspx | ashx | ascx | html | xhtml | twig | jinja | mxml | slim | svg | xml | sgm | sgml | nrm | ent | hdr | hub | dtd | glade | wml | vxml | wml | tld | csproj | xsl | ecf | jnlp | xsd | resx)
                    comment1='<!--'
                    comment2='-->'
                    ;;
                avenue | clearbasic | cb | gambas | class | lotus | ls )
                    comment1="'"
                    ;;
                bibtex | bib | erlang | hrl | erl | inc_luatex | logtalk | lgt | matlab | mercury | oz | pro | ps | )
                    comment1="%"
                    ;;
                charmm | inp | fortran90 | f95 | f90 )
                    comment1="!"
                    ;;
                chill | chl | css | io | pony | spn )
                    comment1="/*"
                    comment2="*/"
                    ;;
                cobol | cob | cbl )
                    comment1="*"
                    ;;
                coffee )
                    comment1="###"
                    comment2="###"
                    ;;
                diff | patch )
                    comment1="---"
                    ;;
                fortran77 | f | for | ftn )
                    comment1="c."
                    ;;
                jsp )
                    comment1="<%--"
                    comment2="--%>"
                    ;;
                miranda )
                    comment1="\\"
                    ;;
                smalltalk | st | gst | sq)
                    comment1="\""
                    comment2="\""
                    ;;
                snobol | sno)
                    comment1="*"
                    ;;
            esac

            {head -c ${maxFileSize} "$tmpfile" ; printf "\n\n${comment1} Output truncated: the file ($bytes bytes) exceed the $maxFileSize bytes limit. ${comment2}\n\n" } | "${cmd}" -T "${target}" ${cmdOpts} 2>> ${err_device}
        else
            echo "No need to truncate the data."  >> ${err_device}
            cat "$tmpfile" | "${cmd}" -T "${target}" ${cmdOpts} 2>> ${err_device}
        fi
        # ${reader} 2>> ${err_device} | head -c ${maxFileSize} | "${cmd}" -T "${target}" ${cmdOpts} 2>> ${err_device} && exit 0
        # delete the temporary file.
        rm "$tmpfile"
        exit 0
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
