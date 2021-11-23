#!/usr/bin/env zsh -f

###############################################################################
# This code is licensed under the GPL v3.  See LICENSE.txt for details.
#
# Copyright 2007 Nathaniel Gray.
# Copyright 2012-2018 Anthony Gelibert.
#
# Expects   $1 = name of file to colorize
#
# Produces HTML on stdout with exit code 0 on success
###############################################################################

# Fail immediately on failure of sub-command
setopt err_exit

# Output a message to the standard log file.

if hash gdate 2>/dev/null; then
    # use gnu date that support %N placeholder for the nanoseconds.
    date=gdate
    date_format="%Y-%m-%d %T.%N"
else
    date=date
    date_format="%Y-%m-%d %T"
fi

function debug() {
    if [ "x$logHL" != "x" ]; then
        echo "`$date +"$date_format"` $@" >> "$logHL"
    fi
}

if [ "x$logHL" != "x" ]; then
    # Clear the log.
    #echo "" > "$logHL"
    #debug "-------------------------------------------------"
    # file to store stderr
    err_device="$logHL"
else
    err_device=/dev/stderr
fi

# Set the read-only variables

# Target file to colorize.
export targetHL="$1"
# Path of the highlight.
cmd="$pathHL"
dos2unix="$pathDos2unix"

if [ "x${targetHL}" = "x" ]; then
    echo "Error: missing target env!" >> ${err_device}
    exit 1
fi

if [[ ! -a "$targetHL" ]]; then
    echo "Error: missing target file!" >> ${err_device}
    exit 1
fi

if [ "x${cmd}" = "x" ]; then
    cmd=`which highlight`
fi
if [ "x${cmd}" = "x" ]; then
    echo "Error: missing highlight path env (\$pathHL)!" >> ${err_device}
    exit 1
fi

if [ "x${textEncoding}" = "x" ]; then
    textEncoding="UTF-8"
fi

debug "Starting colorize.sh"
if hash gdate 2>/dev/null; then
else
    debug "# install gdate with \`brew install coreutils\` to show the nanoseconds time stamp #"
fi

# Reader used to get the contents of the target file.
if [[ ${convertEOL} != "" ]]; then
    #reader=(cat "\"${targetHL}\"" \| perl -p -e 's/\\r\\n/\\n/' \| tr '\\r' '\\n')
    reader=(cat "\"${targetHL}\"" \| "\"${dos2unix}\"" -c mac \| "\"${dos2unix}\"")
else
    reader=(cat "\"${targetHL}\"")
fi

# debug "Handling special cases"
case ${targetHL} in
    *.graffle | *.ps )
        exit 1
        ;;
    *.d )
        lang=make
        ;;
    # *.class )
    #     lang=java
    #     reader=(/usr/local/bin/jad -ff -dead -noctor -p -t "${targetHL}")
    #     plugin=(--plug-in java_library)
    #     ;;
    *.sql )
        if grep -q -E "SQLite .* database" <(file -b "${targetHL}"); then
            # skip binary sql databases.
            exit 1
        fi
        lang=sql
        ;;
    *.pch | *.h )
        if grep -q "@interface" <("${targetHL}") &> /dev/null; then
            lang=objc
        else
            lang=h
        fi
        ;;
    * )
        lang=${targetHL##*.}
        ;;
esac

if [[ ${syntaxHL} != "" ]]; then
    # Use the request file type.
    lang=${syntaxHL}
fi

debug "Target to colorize: ${targetHL}"
debug "Resolved to language: $lang"

if [[ ${preprocessorHL} != "" ]]; then
    reader=${preprocessorHL}
fi

debug "Reader: ${reader}"
debug "Highlight: $cmd"

go4it () {
    # Split extraFlagsHL to an array of arguments using '•' as separator.
    #
    # Do not use zsh {= expansion because it split the string on all space ignoring quotes and causing error.
    cmdExtra=("${(@s/•/)extraFlagsHL}")
    
    export cmdOptsHL=(${plugin} --syntax=${lang} --quiet --include-style --encoding=${textEncoding} ${cmdExtra} --validate-input)
    
    if [ "x${useLSP}" != "x" ]; then
        # LSP require full path.
        cmdOptsHL+=(-i "${targetHL}")
    fi
    
    # debug "Environments:"
    # env=`set`
    # debug "\n$env"
    
    if [ -n "${maxFileSizeHL}" ]; then
        # create a temporary file
        tmpfile=$(mktemp -t colorize)
        debug "Save reader output to a temporary file: $tmpfile"
        debug "\$ ${reader} > \"$tmpfile\""
        
        # apply preprocessor
        (eval ${reader}) > "$tmpfile" 2>> ${err_device}
        result=$?
        if [ $result != 0 ]; then
            debug "Error $result!"
            exit $result
        fi
        
        # get file size
        bytes=$((`cat "$tmpfile" | wc -c` + 0))
        debug "Output take $bytes bytes."
        
        # Convert to number.
        bytes=$((bytes + 0))
        maxFileSizeHL=$((maxFileSizeHL + 0))
        
        if [ $bytes -gt $maxFileSizeHL ]; then
            debug "Truncate data to ${maxFileSizeHL} bytes."
            
            comment1=""
            comment2=""
            case ${lang} in
                abap4 | abp | abc | express | exp | vimscript | vim | vimrc )
                    comment1="\""
                    ;;
                abnf | ascend | a4c | delphi | pas | dpr | ebnf | ebnf2 | innosetup | iss | lotos | mod2 | mod | def | mod3 | m3 | i3 | oberon | ooc | ocaml | ml | mli | polygen | grm | tex | sty | cls | znn )
                    comment1="(* "
                    comment2=" *)"
                    ;;
                actionscript | as | ballerina | bal | bcpl | biferno | bfr | bison | y | bnf | c | c++ | cpp | cxx | cc | h | hh | hxx | hpp | cu | ceylon | chpl | clean | icl | clipper | coldfusion | cfc | cfm | csharp | cs | d | dart | dylan | fame | frink | fsharp | fs | fsx | fx | go | graphviz | dot | haxe | hx | hugo | hug | idl | interlis | ili | java | groovy | grv | jenkinsfile | gradle | js | json | kotlin | kt | less | lindenscript | lsl | luban | lbn | maple | mpl | maya | mel | modelica | mo | nbc | nemerle | n | nxc | objc | m | os | php | php3 | php4 | php5 | php6 | pike | pmod | pov | pure | qml | rpg | rs | sas | scad | scilab | sci | sce | scss | small | sma | solidity | sol | squirrel | nut | styl | swift | ts | ttcn3 | vala | verilog | v | whiley | yang)
                    comment1="//"
                    ;;
                ada | adb | ads | a | gnad | agda | alan | i | applescript | eiffel | e | se | euphoria | ex | exw | wxu | ew | eu | haskell | hs | lua | ms | mssql | netrexx | nrx | oorexx | pl1 | ff | fp | pp | rpp | sf | sp | spb | spp | sps | wp | wf | wpp | wps | wpb | bdy | spe | rexx | rex | the | rx | snmp | mib | smisql | sybase | tsql | vhd )
                    comment1="--"
                    ;;
                algol | alg | ampl | dat | run | amtrix | s4 | s4t | s4h | hnd | t4 | awk | bms | boo | cmake | conf | anacrontab | crk | crystal | cr | cs_block_regex | docker | dockerfile | dts | dtsi | elixir | exs | fish | fstab | gdb | gdscript | gd | hcl | httpd | icon | icn | informix | 4gl | julia | jl | ldif | limbo | b | make | mak | mk | makefile | meson | n3 | ttl | nt | nasal | nas | nginx | nim | octave | perl | pl | cgi | pm | plx | plex | po | ps1 | psl | pyrex | pyx | python | py | q | qmake | pro | qu | r | rnc | ruby | rb | rjs | gemfile | rakefile | s | sh | bash | zsh | ebuild | eclass | spec | tcl | wish | itcl | tcsh | terraform | toml | yaml | yml | csh | ksh )
                    comment1="#"
                    ;;
                arc | aspect | was | wud | assembler | asm | a51 | 29k | 68s | 68x | x86 | autohotkey | ahk | autoit | au3 | blitzbasic | bb | clojure | clj | clp | edn | exapunks | exa | fasm | inc | felix | flx | idlang | ini | doxyfile | desktop | kdev3 | jasmin | j | lisp | cl | clisp | el | lsp | sbcl | scom | fas | scm | msl | nbs | nsis | nsi | nsh | paradox | sc | purebasic | pb | pbi | pbf | rebol )
                    comment1=";"
                    ;;
                arm | bat | cmd | vb | bas | basic | bi | vbs )
                    comment1="rem"
                    ;;
                asciidoc )
                    comment1="////"
                    comment2="////"
                    ;;
                asp | aspx | ashx | ascx | html | xhtml | twig | jinja | mxml | slim | svg | xml | sgm | sgml | nrm | ent | hdr | hub | dtd | glade | wml | vxml | tld | csproj | xsl | ecf | jnlp | xsd | resx | xib | storyboard )
                    comment1='<!--'
                    comment2='-->'
                    ;;
                avenue | clearbasic | cb | gambas | class | lotus | ls )
                    comment1="'"
                    ;;
                bibtex | bib | erlang | hrl | erl | inc_luatex | logtalk | lgt | matlab | mercury | oz | ps | )
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

            debug "Generating the preview…"
            
            debug "\$ head -c ${maxFileSizeHL} \"$tmpfile\" | \"${cmd}\" -T \"${targetHL}\" ${cmdOptsHL}"
            
            {head -c ${maxFileSizeHL} "$tmpfile"  2>> ${err_device} ; printf "\n\n${comment1} Output truncated: the file ($bytes bytes) exceed the $maxFileSizeHL bytes limit. ${comment2}\n\n" } | "${cmd}" -T "${targetHL}" ${cmdOptsHL} 2>> ${err_device}
            result=$?
        else
            debug "No need to truncate the data."
            debug "Generating the preview…"
            debug "\$ cat \"$tmpfile\" | \"${cmd}\" -T \"${targetHL}\" ${cmdOptsHL}"
            cat "$tmpfile" | "${cmd}" -T "${targetHL}" ${cmdOptsHL} 2>> ${err_device}
            result=$?
        fi
        
        if [ $result = 0 ]; then
            debug "Success."
        else
            debug "Error $result!"
        fi
        
        debug "Deleting the temporary file."
        # delete the temporary file.
        rm "$tmpfile"
        if [ $result = 0 ]; then
            exit 0
        else
            return result
        fi
    else
        debug "Generating the preview…"
        if [ "x${useLSP}" != "x" ]; then
            debug "\$ \"${cmd}\" -T \"${targetHL}\" ${cmdOptsHL}"
            "${cmd}" -T "${targetHL}" ${cmdOptsHL} 2>> ${err_device}
        else
            debug "\$ ${reader} | \"${cmd}\" -T \"${targetHL}\" ${cmdOptsHL}"
            (eval ${reader}) 2>> ${err_device} | "${cmd}" -T "${targetHL}" ${cmdOptsHL} 2>> ${err_device}
        fi
        
        result=$?
        if [ $result = 0 ]; then
            debug "Success."
            exit 0
        else
            debug "Error $result!"
            return result
        fi
    fi
}

setopt no_err_exit

go4it

# Uh-oh, it didn't work.  Fall back to rendering the file as plain
debug "-------------------------------------------------"
debug "First try failed, second try with txt language…"

lang=txt
export syntaxHL=txt
go4it

debug "-------------------------------------------------"
debug "Reached the end of the file. That should not happen."

exit 101
