--[[
Sample plugin file for highlight 3.9
]]

Description="Add perldoc.perl.org reference links to HTML, LaTeX, RTF and ODT output of Perl code"

Categories = {"perl", "html", "rtf", "latex", "odt" }

-- optional parameter: syntax description
function syntaxUpdate(desc)

  if desc~="Perl" then
    return
  end

  function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
      return set
  end

  function_items = Set {"chomp", "chop", "chr", "crypt", "hex", "index", "lc",
    "lcfirst", "length", "oct", "ord", "pack", "qq", "reverse", "rindex", "sprintf",
    "substr", "tr", "uc", "ucfirst,",  "pos", "quotemeta", "split", "study",
    "qr", "abs", "atan2", "cos", "exp", "hex", "int", "log", "oct", "rand", "sin",
    "sqrt", "srand", "each", "keys", "pop", "push", "shift", "splice", "unshift",
    "values", "grep", "join", "map", "qw", "reverse", "sort", "unpack", "delete",
    "each", "exists", "keys", "values", "binmode", "close", "closedir", "dbmclose",
    "dbmopen", "die", "eof", "fileno", "flock", "format", "getc", "print", "printf",
    "read", "readdir", "rewinddir", "say", "seek", "seekdir", "select", "syscall",
    "sysread", "sysseek", "syswrite", "tell", "telldir", "truncate", "warn",
    "write", "pack", "read", "syscall", "sysread", "syswrite", "unpack", "vec",
    "chdir", "chmod", "chown", "chroot", "fcntl", "glob", "ioctl", "link", "lstat",
    "mkdir", "open", "opendir", "readlink", "rename", "rmdir", "stat", "symlink",
    "sysopen", "umask", "unlink", "utime", "caller", "continue", "die", "do",
    "dump", "eval", "exit", "goto", "last", "next", "redo", "return", "sub",
    "wantarray", "continue",  "caller", "import", "local", "my", "our",
    "package", "state", "use", "defined", "dump", "eval", "formline", "local", "my",
    "our", "reset", "scalar", "state", "undef", "wantarray", "alarm", "exec",
    "fork", "getpgrp", "getppid", "getpriority", "kill", "pipe", "qx", "setpgrp",
    "setpriority", "sleep", "system", "times", "wait", "waitpid", "do", "import",
    "no", "package", "require", "use", "bless", "dbmclose", "dbmopen", "package",
    "ref", "tie", "tied", "untie", "use", "accept", "bind", "connect",
    "getpeername", "getsockname", "getsockopt", "listen", "recv", "send",
    "setsockopt", "shutdown", "socket", "socketpair", "msgctl", "msgget", "msgrcv",
    "msgsnd", "semctl", "semget", "semop", "shmctl", "shmget", "shmread",
    "shmwrite", "endgrent", "endhostent", "endnetent", "endpwent", "getgrent",
    "getgrgid", "getgrnam", "getlogin", "getpwent", "getpwnam", "getpwuid",
    "setgrent", "setpwent", "endprotoent", "endservent", "gethostbyaddr",
    "gethostbyname", "gethostent", "getnetbyaddr", "getnetbyname", "getnetent",
    "getprotobyname", "getprotobynumber", "getprotoent", "getservbyname",
    "getservbyport", "getservent", "sethostent", "setnetent", "setprotoent",
    "setservent", "gmtime", "localtime", "time", "times", "abs", "bless", "chomp",
    "chr", "continue", "exists", "formline", "glob", "import", "lc", "lcfirst",
    "lock", "map", "my", "no", "our", "prototype", "qr", "qw", "qx", "readline",
    "readpipe", "ref", "sub*", "sysopen", "tie", "tied", "uc", "ucfirst", "untie",
    "use", "binmode", "chmod", "chown", "chroot", "crypt", "dbmclose", "dbmopen",
    "dump", "endgrent", "endhostent", "endnetent", "endprotoent", "endpwent",
    "endservent", "exec", "fcntl", "flock", "fork", "getgrent", "getgrgid",
    "gethostbyname", "gethostent", "getlogin", "getnetbyaddr", "getnetbyname",
    "getnetent", "getppid", "getpgrp", "getpriority", "getprotobynumber",
    "getprotoent", "getpwent", "getpwnam", "getpwuid", "getservbyport",
    "getservent", "getsockopt", "glob", "ioctl", "kill", "link", "lstat", "msgctl",
    "msgget", "msgrcv", "msgsnd", "open", "pipe", "readlink", "rename", "select",
    "semctl", "semget", "semop", "setgrent", "sethostent", "setnetent", "setpgrp",
    "setpriority", "setprotoent", "setpwent", "setservent", "setsockopt", "shmctl",
    "shmget", "shmread", "shmwrite", "socket", "socketpair", "stat", "symlink",
    "syscall", "sysopen", "system", "times", "truncate", "umask", "unlink", "utime",
    "wait", "waitpid" }

  function getURL(token)
    url='http://perldoc.perl.org/functions/'..string.lower(token).. '.html'

    if (HL_OUTPUT== HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
      return '<a class="hl" target="new" href="' .. url .. '">'.. token .. '</a>'
    elseif (HL_OUTPUT == HL_FORMAT_LATEX) then
      return '\\href{'..url..'}{'..token..'}'
    elseif (HL_OUTPUT == HL_FORMAT_RTF) then
      return '{{\\field{\\*\\fldinst HYPERLINK "'..url..'" }{\\fldrslt\\ul\\ulc0 '..token..'}}}'
    elseif (HL_OUTPUT == HL_FORMAT_ODT) then
      return '<text:a xlink:type="simple" xlink:href="'..url..'">'..token..'</text:a>'
    end
  end


  function Decorate(token, state)

    if  (state ~= HL_STANDARD and state ~= HL_KEYWORD) then
      return
    end

    if function_items[token] then
      return getURL(token)
    end

  end
end

function themeUpdate(desc)
  if (HL_OUTPUT == HL_FORMAT_HTML or HL_OUTPUT == HL_FORMAT_XHTML) then
    Injections[#Injections+1]="a.hl, a.hl:visited {color:inherit;font-weight:inherit;}"
  elseif (HL_OUTPUT==HL_FORMAT_LATEX) then
    Injections[#Injections+1]="\\usepackage[colorlinks=false, pdfborderstyle={/S/U/W 1}]{hyperref}"
  end
end
--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files

Plugins={

  { Type="lang", Chunk=syntaxUpdate },
  { Type="theme", Chunk=themeUpdate },

}
