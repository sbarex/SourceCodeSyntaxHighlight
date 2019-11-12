//
//  String+ext.swift
//  Syntax Highlight
//
//  Created by Sbarex on 11/11/2019.
//  Copyright © 2019 sbarex. All rights reserved.
//
//
//  This file is part of SourceCodeSyntaxHighlight.
//  SourceCodeSyntaxHighlight is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  SourceCodeSyntaxHighlight is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with SourceCodeSyntaxHighlight. If not, see <http://www.gnu.org/licenses/>.
//
//  Based on glib/gshell.c
//  https://github.com/GNOME/glib/blob/master/glib/gshell.c
//

import Foundation

extension String {
    /*
    func escapeShellArg() -> String {
        return "\'" + self.replacingOccurrences(of: "\'", with: "'\\''") + "\'"
    }
    */
    
    enum TokenizeError: Error {
        case badQuoting(message: String)
    }
    
    private typealias UnquoteResult = (string: String, end: String.Index)
    /**
     * Single quotes preserve the literal string exactly. escape
     * sequences are not allowed; not even \' - if you want a '
     * in the quoted text, you have to do something like 'foo'\''bar'
     *
     * Double quotes allow $ ` " \ and newline to be escaped with backslash.
     * Otherwise double quotes preserve things literally.
     */
    private func unquote_string_inplace() throws -> UnquoteResult {
        let str = self
        var dest = ""
      
        if str.isEmpty {
            return (string: str, end: str.endIndex)
        }
    
        let quote_char = str[str.startIndex]
      
        if !(quote_char == "\"" || quote_char == "\'") {
            throw TokenizeError.badQuoting(message: "Quoted text doesn’t begin with a quotation mark")
            // return (string: self, end: self.endIndex)
        }

        /* Skip the initial quote mark */
        var i = str.index(after: str.startIndex)

        if quote_char == "\"" {
            // Parse double quote token
            while i < str.endIndex {
                var s = str[i]
                
                // g_assert(s > dest); /* loop invariant */
          
                switch s {
                case "\"":
                    /* End of the string, return now */
                    
                    i = str.index(after: i)
                    return (string: dest, end: i)

                case "\\":
                    i = str.index(after: i)
                    s = str[i]
                    /* Possible escaped quote or \ */
                    switch (s) {
                    case "\"", "\\", "`", "$", "\n":
                      dest += String(s);
                      i = str.index(after: i)

                    default:
                        /* not an escaped char */
                        dest += "\\"
                        /* ++s already done. */
                    }

                default:
                    dest += String(s)
                    i = str.index(after: i)
                }

                // g_assert(s > dest); /* loop invariant */
            }
        } else {
            while i < str.endIndex {
                let s = str[i]
                // g_assert(s > dest); /* loop invariant */
              
                if s == "\'" {
                    /* End of the string, return now */
                    i = str.index(after: i)
                    return (string: dest, end: i)
                } else {
                    dest += String(s)
                    i = str.index(after: i)
                }

                // g_assert(s > dest); /* loop invariant */
            }
        }
      
        /* If we reach here this means the close quote was never encountered */

        throw TokenizeError.badQuoting(message: "Unmatched quotation mark in command line or other shell-quoted text")
    }
    
    /**
    * Single quotes preserve the literal string exactly. escape
    * sequences are not allowed; not even \' - if you want a '
    * in the quoted text, you have to do something like 'foo'\''bar'
    *
    * Double quotes allow $ ` " \ and newline to be escaped with backslash.
    * Otherwise double quotes preserve things literally.
    */
    private func unquote_string_inplace() throws -> String {
        let r:UnquoteResult = try self.unquote_string_inplace()
        return r.string
    }
    
    /**
     * Quotes the string for the shell (/bin/sh).
     * If you pass a filename to the shell, for example, you should first quote it
     * with this function.
     * The quoting style used is undefined (single or double quotes may be
     * used).
     *
     * - returns: The quoted string
     */
    func g_shell_quote() -> String {
        let unquoted_string = self
        /* We always use single quotes, because the algorithm is cheesier.
         * We could use double if we felt like it, that might be more
         * human-readable.
         */

        var dest = "'"

        var i = unquoted_string.startIndex
      
        /* could speed this up a lot by appending chunks of text at a
         * time.
         */
        while i < unquoted_string.endIndex {
            let p = unquoted_string[i]
            /* Replace literal ' with a close ', a \', and an open ' */
            if p == "\'" {
                dest += "'\\''"
            } else {
                dest += String(p)
            }
            i = unquoted_string.index(after: i)
        }

        /* close the quote */
        dest += "\'"
      
        return dest
    }
    
    /**
     * Unquotes the string as the shell (/bin/sh) would. Only handles
     * quotes; if a string contains file globs, arithmetic operators,
     * variables, backticks, redirections, or other special-to-the-shell
     * features, the result will be different from the result a real shell
     * would produce (the variables, backticks, etc. will be passed
     * through literally instead of being expanded). This function is
     * guaranteed to succeed if applied to the result of
     * g_shell_quote().
     * The source string need not actually contain quoted or
     * escaped text; g_shell_unquote() simply goes through the string and
     * unquotes/unescapes anything that the shell would. Both single and
     * double quotes are handled, as are escapes including escaped
     * newlines.
     *
     * Shell quoting rules are a bit strange. Single quotes preserve the
     * literal string exactly. escape sequences are not allowed; not even
     * \' - if you want a ' in the quoted text, you have to do something
     * like 'foo'\''bar'.  Double quotes allow $, `, ", \, and newline to
     * be escaped with backslash. Otherwise double quotes preserve things
     * literally.
     *
     * - returns: An unquoted string.
     */
    func g_shell_unquote() throws -> String {
        let quoted_string = self
      
        var i = quoted_string.startIndex
        
        var retval = ""

        /* The loop allows cases such as
         * "foo"blah blah'bar'woo foo"baz"la la la\'\''foo'
         */
        while i < quoted_string.endIndex {
            var start = quoted_string[i]
            /* Append all non-quoted chars, honoring backslash escape */
          
            while i < quoted_string.endIndex && !(start == "\"" || start == "\'") {
                if start == "\\" {
                    /* all characters can get escaped by backslash,
                     * except newline, which is removed if it follows
                     * a backslash outside of quotes
                     */
                    i = quoted_string.index(after: i)
                    start = quoted_string[i]
                    if start != "\n" {
                        retval += String(start)
                    }
                } else {
                    retval += String(start)
                }
                i = quoted_string.index(after: i)
                if i < quoted_string.endIndex {
                    start = quoted_string[i]
                }
            }

            if i < quoted_string.endIndex {
                let substr = String(quoted_string[i ..< quoted_string.endIndex])
                let r: UnquoteResult = try substr.unquote_string_inplace()
                retval += r.string
                i = quoted_string.index(i, offsetBy: substr.distance(from: substr.startIndex, to: r.end))
                if i < quoted_string.endIndex {
                    start = quoted_string[i]
                }
            }
        }

        return retval
    }
    
    /*
     * g_parse_argv() does a semi-arbitrary weird subset of the way
     * the shell parses a command line. We don't do variable expansion,
     * don't understand that operators are tokens, don't do tilde expansion,
     * don't do command substitution, no arithmetic expansion, IFS gets ignored,
     * don't do filename globs, don't remove redirection stuff, etc.
     *
     * READ THE UNIX98 SPEC on "Shell Command Language" before changing
     * the behavior of this code.
     *
     * Steps to parsing the argv string:
     *
     *  - tokenize the string (but since we ignore operators,
     *    our tokenization may diverge from what the shell would do)
     *    note that tokenization ignores the internals of a quoted
     *    word and it always splits on spaces, not on IFS even
     *    if we used IFS. We also ignore "end of input indicator"
     *    (I guess this is control-D?)
     *
     *    Tokenization steps, from UNIX98 with operator stuff removed,
     *    are:
     *
     *    1) "If the current character is backslash, single-quote or
     *        double-quote (\, ' or ") and it is not quoted, it will affect
     *        quoting for subsequent characters up to the end of the quoted
     *        text. The rules for quoting are as described in Quoting
     *        . During token recognition no substitutions will be actually
     *        performed, and the result token will contain exactly the
     *        characters that appear in the input (except for newline
     *        character joining), unmodified, including any embedded or
     *        enclosing quotes or substitution operators, between the quote
     *        mark and the end of the quoted text. The token will not be
     *        delimited by the end of the quoted field."
     *
     *    2) "If the current character is an unquoted newline character,
     *        the current token will be delimited."
     *
     *    3) "If the current character is an unquoted blank character, any
     *        token containing the previous character is delimited and the
     *        current character will be discarded."
     *
     *    4) "If the previous character was part of a word, the current
     *        character will be appended to that word."
     *
     *    5) "If the current character is a "#", it and all subsequent
     *        characters up to, but excluding, the next newline character
     *        will be discarded as a comment. The newline character that
     *        ends the line is not considered part of the comment. The
     *        "#" starts a comment only when it is at the beginning of a
     *        token. Since the search for the end-of-comment does not
     *        consider an escaped newline character specially, a comment
     *        cannot be continued to the next line."
     *
     *    6) "The current character will be used as the start of a new word."
     *
     *
     *  - for each token (word), perform portions of word expansion, namely
     *    field splitting (using default whitespace IFS) and quote
     *    removal.  Field splitting may increase the number of words.
     *    Quote removal does not increase the number of words.
     *
     *   "If the complete expansion appropriate for a word results in an
     *   empty field, that empty field will be deleted from the list of
     *   fields that form the completely expanded command, unless the
     *   original word contained single-quote or double-quote characters."
     *    - UNIX98 spec
     *
     *
     */
    
    func tokenize_command_line() throws -> [String] {
        let command_line = self
        
        var current_quote: Character = "\u{0}"
        var current_token: String = ""
        var retval: [String] = []
        var quoted = false
     
        var i: String.Index = command_line.startIndex
        while i < command_line.endIndex {
            var p = command_line[i]
            if (current_quote == "\\") {
                if p == "\n" {
                    /* we append nothing; backslash-newline become nothing */
                } else {
                    /* we append the backslash and the current char,
                     * to be interpreted later after tokenization
                     */
                    current_token += "\\\(p)"
                }

                current_quote = "\u{0}"
            } else if (current_quote == "#") {
                /* Discard up to and including next newline */
                while i < command_line.endIndex && p != "\n" {
                    i = command_line.index(after: i)
                    p = command_line[i]
                }
                current_quote = "\u{0}"
              
                if p == "\u{0}" || i == command_line.endIndex {
                    break
                }
            } else if current_quote != "\u{0}" {
                if p == current_quote &&
                    /* check that it isn't an escaped double quote */
                    !(current_quote == "\"" && quoted) {
                    /* close the quote */
                    current_quote = "\u{0}"
                }

                /* Everything inside quotes, and the close quote,
                 * gets appended literally.
                 */

                current_token += String(p)
            } else {
                switch p {
                case "\n":
                    retval.insert(current_token, at: 0)
                    current_token = ""
                    
                case " ", "\t":
                    /* If the current token contains the previous char, delimit
                     * the current token. A nonzero length
                     * token should always contain the previous char.
                     */
                    if !current_token.isEmpty {
                        retval.insert(current_token, at: 0)
                        current_token = ""
                    }
                    /* discard all unquoted blanks (don't add them to a token) */
                  

                   /* single/double quotes are appended to the token,
                    * escapes are maybe appended next time through the loop,
                    * comment chars are never appended.
                    */
                  
                case "\'", "\"":
                    current_token += String(p)
                    fallthrough
                case "\\":
                  current_quote = p

                case "#":
                    if p == command_line.first { /* '#' was the first char */
                        current_quote = p
                        break;
                    }
                    switch command_line[command_line.index(before: i)] {
                        case " ", "\n", "\u{0}":
                            current_quote = p
                        default:
                            current_token += String(p)
                    }

                default:
                    /* Combines rules 4) and 6) - if we have a token, append to it,
                     * otherwise create a new token.
                     */
                    
                    current_token += String(p)
                }
            }

            /* We need to count consecutive backslashes mod 2,
             * to detect escaped doublequotes.
             */
            if p != "\\" {
                quoted = false
            } else {
                quoted = !quoted
            }
            i = command_line.index(after: i)
        }

        retval.insert(current_token, at: 0)

        if current_quote != "\u{0}" {
            if current_quote == "\\" {
                throw TokenizeError.badQuoting(message: "Text ended just after a “\\” character. (The text was “\(command_line)”)")
            } else {
                throw TokenizeError.badQuoting(message: "Text ended before matching quote was found for \(current_quote). (The text was “\(command_line)”)")
            }
        }

        if retval.isEmpty {
            // g_set_error_literal (error,
            //                      G_SHELL_ERROR,
            //                      G_SHELL_ERROR_EMPTY_STRING,
            //                      _("Text was empty (or contained only whitespace)"));
            //
            // goto error;
        }
      
        /* we appended backward */
        retval.reverse()

        return retval
    }
    
    /**
     * Parses a command line into an argument vector, in much the same way
     * the shell would, but without many of the expansions the shell would
     * perform (variable expansion, globs, operators, filename expansion,
     * etc. are not supported). The results are defined to be the same as
     * those you would get from a UNIX98 /bin/sh, as long as the input
     * contains none of the unsupported shell expansions. If the input
     * does contain such expansions, they are passed through
     * literally.
     *
     * - returns: Array of parsed arguments
     */
    func shell_parse_argv() throws -> [String] {
        /* Code based on poptParseArgvString() from libpopt */
        
        let tokens = try self.tokenize_command_line()
      
        /* Because we can't have introduced any new blank space into the
         * tokens (we didn't do any new expansions), we don't need to
         * perform field splitting. If we were going to honor IFS or do any
         * expansions, we would have to do field splitting on each word
         * here. Also, if we were going to do any expansion we would need to
         * remove any zero-length words that didn't contain quotes
         * originally; but since there's no expansion we know all words have
         * nonzero length, unless they contain quotes.
         *
         * So, we simply remove quotes, and don't do any field splitting or
         * empty word removal, since we know there was no way to introduce
         * such things.
         */

        var argv: [String] = []
        
        for tmp_list in tokens {
            let t = try tmp_list.g_shell_unquote()
            if t.isEmpty {
                /* Since we already checked that quotes matched up in the
                * tokenizer, this shouldn't be possible to reach I guess.
                */
                throw TokenizeError.badQuoting(message: "Empty token")
            } else {
                argv.append(t)
            }
        }
        
        return argv
    }
}
