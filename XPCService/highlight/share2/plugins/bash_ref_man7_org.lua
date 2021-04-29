
Description="Add man7.org reference links to HTML, LaTeX, RTF and ODT output of Bash scripts"

Categories = {"bash", "html", "rtf", "latex", "odt", "hyperlinks" }

function syntaxUpdate(desc)

  if desc~="Bash" then
    return
  end

  function Set (list)
    local set = {}
    for _, l in ipairs(list) do set[l] = true end
      return set
  end

  man1_items = Set {
    "abicompat", "abidiff", "abidw", "abilint", "abipkgdiff", "ac", "addftinfo",
    "addr2line", "afmtodit", "apropos", "ar", "aria_chk", "aria_dump_log",
    "aria_ftdump", "aria_pack", "aria_read_log", "AS", "as", "attr", "audit2allow",
    "audit2why", "autofsd-probe", "autopoint", "b2sum", "babeltrace-log",
    "babeltrace", "base32", "base64", "basename", "bash", "blkparse",
    "blkrawverify", "bno_plot", "bootctl", "btt", "busctl", "cal",
    "callgrind_annotate", "callgrind_control", "cancel", "capsh", "cat", "certtool",
    "cg_annotate", "cgcc", "cg_diff", "cg_merge", "chacl", "chage", "chattr",
    "chcon", "chem", "chfn", "chgrp", "chkhelp", "chmod", "chown", "chroot", "chrt",
    "chsh", "chvt", "cifsiostat", "cksum", "CLEAR", "clear", "cmp", "col", "colcrt",
    "collectl2pcp", "colrm", "column", "comm", "comp_err", "coredumpctl", "cp",
    "cpp", "cronnext", "crontab", "csplit", "cups-config", "cups", "cupstestdsc",
    "cupstestppd", "cut", "danetool", "dash", "date", "dbpmda", "dbprobe", "dd",
    "deallocvt", "debuginfo-install", "df", "diff", "diff3", "dir", "dircolors",
    "dirname", "dlltool", "dmesg", "dnsdomainname", "domainname",
    "dpkg-architecture", "dpkg-buildflags", "dpkg-buildpackage",
    "dpkg-checkbuilddeps", "dpkg-deb", "dpkg-distaddfile", "dpkg-divert",
    "dpkg-genbuildinfo", "dpkg-genchanges", "dpkg-gencontrol", "dpkg-gensymbols",
    "dpkg-maintscript-helper", "dpkg-mergechangelogs", "dpkg-name",
    "dpkg-parsechangelog", "dpkg-query", "dpkg-scanpackages", "dpkg-scansources",
    "dpkg-shlibdeps", "dpkg-source", "dpkg-split", "dpkg-statoverride",
    "dpkg-trigger", "dpkg-vendor", "dpkg", "dselect", "dtrace", "du", "dumpkeys",
    "echo", "egrep", "eject", "elfedit", "env", "envsubst", "eqn", "eqn2graph",
    "expand", "expect", "expiry", "expr", "factor", "fallocate", "false",
    "fedabipkgdiff", "fgconsole", "fgrep", "file", "fincore",
    "find-repos-of-install", "find", "flock", "fmt", "fold", "free", "fuse2fs",
    "fuser", "fusermount3", "g++", "galera_new_cluster", "galera_recovery",
    "ganglia2pcp", "gawk", "gcc", "gcore", "gcov-dump", "gcov-tool", "gcov", "gdb",
    "gdbserver", "gdiffmk", "genpmda", "getent", "getfacl", "getfattr", "getopt",
    "gettext", "gettextize", "gfortran", "git-add", "git-am", "git-annotate",
    "git-apply", "git-archimport", "git-archive", "git-bisect", "git-blame",
    "git-branch", "git-bundle", "git-cat-file", "git-check-attr",
    "git-check-ignore", "git-check-mailmap", "git-check-ref-format",
    "git-checkout-index", "git-checkout", "git-cherry-pick", "git-cherry",
    "git-citool", "git-clean", "git-clone", "git-column", "git-commit-tree",
    "git-commit", "git-config", "git-count-objects", "git-credential-cache--daemon",
    "git-credential-cache", "git-credential-store", "git-credential",
    "git-cvsexportcommit", "git-cvsimport", "git-cvsserver", "git-daemon",
    "git-describe", "git-diff-files", "git-diff-index", "git-diff-tree", "git-diff",
    "git-difftool", "git-fast-export", "git-fast-import", "git-fetch-pack",
    "git-fetch", "git-filter-branch", "git-fmt-merge-msg", "git-for-each-ref",
    "git-format-patch", "git-fsck-objects", "git-fsck", "git-gc",
    "git-get-tar-commit-id", "git-grep", "git-gui", "git-hash-object", "git-help",
    "git-http-backend", "git-http-fetch", "git-http-push", "git-imap-send",
    "git-index-pack", "git-init-db", "git-init", "git-instaweb",
    "git-interpret-trailers", "git-log", "git-ls-files", "git-ls-remote",
    "git-ls-tree", "git-mailinfo", "git-mailsplit", "git-merge-base",
    "git-merge-file", "git-merge-index", "git-merge-one-file", "git-merge-tree",
    "git-merge", "git-mergetool--lib", "git-mergetool", "git-mktag", "git-mktree",
    "git-mv", "git-name-rev", "git-notes", "git-p4", "git-pack-objects",
    "git-pack-redundant", "git-pack-refs", "git-parse-remote", "git-patch-id",
    "git-prune-packed", "git-prune", "git-pull", "git-push", "git-quiltimport",
    "git-read-tree", "git-rebase", "git-receive-pack", "git-reflog", "git-relink",
    "git-remote-ext", "git-remote-fd", "git-remote-testgit", "git-remote",
    "git-repack", "git-replace", "git-request-pull", "git-rerere", "git-reset",
    "git-rev-list", "git-rev-parse", "git-revert", "git-rm", "git-send-email",
    "git-send-pack", "git-series", "git-sh-i18n--envsubst", "git-sh-i18n",
    "git-sh-setup", "git-shell", "git-shortlog", "git-show-branch",
    "git-show-index", "git-show-ref", "git-show", "git-stage", "git-stash",
    "git-status", "git-stripspace", "git-submodule", "git-svn", "git-symbolic-ref",
    "git-tag", "git-unpack-file", "git-unpack-objects", "git-update-index",
    "git-update-ref", "git-update-server-info", "git-upload-archive",
    "git-upload-pack", "git-var", "git-verify-commit", "git-verify-pack",
    "git-verify-tag", "git-web--browse", "git-whatchanged", "git-worktree",
    "git-write-tree", "git", "gitk", "gitremote-helpers", "gitweb", "glilypond",
    "gnutls-cli-debug", "gnutls-cli", "gnutls-serv", "gpasswd", "gperl", "gpinyin",
    "gprof", "grap2graph", "grep", "grn", "grodvi", "groff", "groffer", "grog",
    "grohtml", "grolbp", "grolj4", "gropdf", "grops", "grotty", "groups", "guards",
    "head", "hexdump", "hg", "hostid", "hostname", "hostnamectl", "hpftodit",
    "htop", "iconv", "id", "indent", "indxbib", "init", "innochecksum",
    "inotifywait", "inotifywatch", "install", "intro", "ionice", "iostat",
    "iostat2pcp", "iowatcher", "ipcmk", "ipcrm", "ipcs", "ippfind", "ipptool",
    "join", "journalctl", "kbd_mode", "kernelshark", "keyctl", "kill", "killall",
    "last", "lastb", "lastcomm", "ld", "ldapadd", "ldapcompare", "ldapdelete",
    "ldapexop", "ldapmodify", "ldapmodrdn", "ldappasswd", "ldapsearch", "ldapurl",
    "ldapwhoami", "ldd", "less", "lessecho", "lesskey", "lexgrog", "line", "link",
    "lkbib", "ln", "loadkeys", "locale", "localectl", "localedef", "locate",
    "logger", "login", "loginctl", "logname", "look", "lookbib", "lp", "lpoptions",
    "lpq", "lpr", "lprm", "lpstat", "ls", "lsattr", "lscpu", "lsinitrd", "lsipc",
    "lslogins", "lsmem", "ltrace", "lttng-add-context", "lttng-calibrate",
    "lttng-crash", "lttng-create", "lttng-destroy", "lttng-disable-channel",
    "lttng-disable-event", "lttng-enable-channel", "lttng-enable-event",
    "lttng-gen-tp", "lttng-help", "lttng-list", "lttng-load", "lttng-metadata",
    "lttng-regenerate", "lttng-save", "lttng-set-session", "lttng-snapshot",
    "lttng-start", "lttng-status", "lttng-stop", "lttng-track", "lttng-untrack",
    "lttng-version", "lttng-view", "lttng", "lttngtop", "lttngtoptrace",
    "lxc-attach", "lxc-autostart", "lxc-cgroup", "lxc-checkconfig",
    "lxc-checkpoint", "lxc-config", "lxc-console", "lxc-copy", "lxc-create",
    "lxc-destroy", "lxc-device", "lxc-execute", "lxc-freeze", "lxc-info", "lxc-ls",
    "lxc-monitor", "lxc-snapshot", "lxc-start", "lxc-stop", "lxc-top",
    "lxc-unfreeze", "lxc-unshare", "lxc-user-nic", "lxc-usernsexec", "lxc-wait",
    "machinectl", "make", "make_win_bin_dist", "man", "manconv", "manpath",
    "mariadb-service-convert", "mcookie", "md5sum", "memusage", "memusagestat",
    "mesg", "mkaf", "mkdir", "mkfifo", "mknod", "mktemp", "mmroff", "more",
    "mountpoint", "mpstat", "mrtg2pcp", "msgattrib", "msgcat", "msgcmp", "msgcomm",
    "msgconv", "msgen", "msgexec", "msgfilter", "msgfmt", "msggrep", "msginit",
    "msgmerge", "msgunfmt", "msguniq", "ms_print", "msql2mysql", "mtrace", "mv",
    "myisamchk", "myisam_ftdump", "myisamlog", "myisampack", "my_print_defaults",
    "my_safe_process", "mysql-stress-test.pl", "mysql-test-run.pl", "mysql",
    "mysql.server", "mysqlaccess", "mysqladmin", "mysqlbinlog", "mysqlbug",
    "mysqlcheck", "mysql_client_test", "mysql_client_test_embedded", "mysql_config",
    "mysql_convert_table_format", "mysqld_multi", "mysqld_safe",
    "mysqld_safe_helper", "mysqldump", "mysqldumpslow", "mysql_find_rows",
    "mysql_fix_extensions", "mysqlhotcopy", "mysqlimport", "mysql_install_db",
    "mysql_plugin", "mysql_secure_installation", "mysql_setpermission", "mysqlshow",
    "mysqlslap", "mysqltest", "mysqltest_embedded", "mysql_tzinfo_to_sql",
    "mysql_upgrade", "mysql_waitpid", "mysql_zap", "namei", "ncat",
    "ncurses5-config", "ncurses6-config", "ndiff", "needs-restarting", "neqn",
    "networkctl", "newgidmap", "newgrp", "newhelp", "newrole", "newuidmap",
    "nfs4_editfacl", "nfs4_getfacl", "nfs4_setfacl", "nfsiostat-sysstat",
    "ngettext", "nice", "nisdomainname", "nl", "nlmconv", "nm", "nmap-update",
    "nmap", "nodename", "nohup", "nping", "nproc", "nroff", "nsenter", "numfmt",
    "objcopy", "objdump", "ocount", "ocsptool", "od", "op-check-perfevents",
    "opannotate", "oparchive", "opcontrol", "openvt", "operf", "opgprof", "ophelp",
    "opimport", "opreport", "oprofile", "oprof_start", "p11tool", "package-cleanup",
    "passwd", "paste", "patch", "pathchk", "pcap-config", "pcp-atop", "pcp-atopsar",
    "pcp-collectl", "pcp-dmcache", "pcp-free", "pcp-iostat", "pcp-ipcs",
    "pcp-lvmcache", "pcp-mpstat", "pcp-numastat", "pcp-pidstat", "pcp-python",
    "pcp-shping", "pcp-summary", "pcp-tapestat", "pcp-uptime", "pcp-verify",
    "pcp-vmstat", "pcp", "pcp2graphite", "pcp2influxdb", "PCPIntro", "pcpintro",
    "pcre-config", "pcregrep", "pcretest", "pdfmom", "pdfroff", "peekfd",
    "perf-annotate", "perf-archive", "perf-bench", "perf-buildid-cache",
    "perf-buildid-list", "perf-c2c", "perf-config", "perf-data", "perf-diff",
    "perf-evlist", "perf-ftrace", "perf-help", "perf-inject", "perf-kallsyms",
    "perf-kmem", "perf-kvm", "perf-list", "perf-lock", "perf-mem", "perf-probe",
    "perf-record", "perf-report", "perf-sched", "perf-script-perl",
    "perf-script-python", "perf-script", "perf-stat", "perf-test", "perf-timechart",
    "perf-top", "perf-trace", "perf", "perfalloc", "perror", "pfbtops", "pg",
    "pgrep", "pic", "pic2graph", "pidof", "pidstat", "pinky", "pkill", "pldd",
    "pmafm", "pmap", "pmatop", "pmcd", "pmcd_wait", "pmchart", "pmclient",
    "pmclient_fg", "pmcollectl", "pmconfig", "pmconfirm", "pmcpp", "pmdaactivemq",
    "pmdaaix", "pmdaapache", "pmdabash", "pmdabind2", "pmdabonding", "pmdacifs",
    "pmdacisco", "pmdadarwin", "pmdadbping", "pmdadm", "pmdadocker", "pmdads389",
    "pmdads389log", "pmdaelasticsearch", "pmdafreebsd", "pmdagfs2", "pmdagluster",
    "pmdagpfs", "pmdaib", "pmdajbd2", "pmdajson", "pmdakernel", "pmdakvm",
    "pmdalibvirt", "pmdalinux", "pmdalio", "pmdalmsensors", "pmdalogger",
    "pmdalustre", "pmdalustrecomm", "pmdamailq", "pmdamemcache", "pmdamic",
    "pmdammv", "pmdamounts", "pmdamysql", "pmdanetbsd", "pmdanetfilter",
    "pmdanfsclient", "pmdanginx", "pmdanutcracker", "pmdanvidia", "pmdaoracle",
    "pmdapapi", "pmdaperfevent", "pmdapipe", "pmdapostfix", "pmdapostgresql",
    "pmdaproc", "pmdaredis", "pmdaroomtemp", "pmdaroot", "pmdarpm", "pmdarsyslog",
    "pmdasample", "pmdasendmail", "pmdashping", "pmdasimple", "pmdaslurm",
    "pmdasolaris", "pmdasummary", "pmdasystemd", "pmdate", "pmdatrace",
    "pmdatrivial", "pmdatxmon", "pmdaunbound", "pmdaweblog", "pmdawindows",
    "pmdaxfs", "pmdazimbra", "pmdazswap", "pmdbg", "pmdiff", "pmdumplog",
    "pmdumptext", "pmerr", "pmevent", "pmfind", "pmgenmap", "pmgetopt",
    "pmhostname", "pmie", "pmie2col", "pmie_check", "pmieconf", "pmie_daily",
    "pmiestatus", "pminfo", "pmiostat", "pmlc", "pmlock", "pmlogcheck", "pmlogconf",
    "pmlogextract", "pmlogger", "pmlogger_check", "pmlogger_daily",
    "pmlogger_merge", "pmloglabel", "pmlogmv", "pmlogreduce", "pmlogrewrite",
    "pmlogsummary", "pmmessage", "pmmgr", "pmnewlog", "pmnsadd", "pmnscomp",
    "pmnsdel", "pmnsmerge", "pmpause", "pmpost", "pmprobe", "pmproxy", "pmpython",
    "pmquery", "pmrep", "pmsignal", "pmsleep", "pmsnap", "pmsocks", "pmstat",
    "pmstore", "pmtime", "pmtrace", "pmval", "pmview", "pmwebd", "ppdc", "ppdhtml",
    "ppdi", "ppdmerge", "ppdpo", "pr", "preconv", "printenv", "printf", "prlimit",
    "prtstat", "ps", "psfaddtable", "psfgettable", "psfstriptable", "psfxtable",
    "psktool", "pslog", "pstree", "ptx", "pv", "pwd", "pwdx", "quilt", "quota",
    "quotasync", "ranlib", "readelf", "readlink", "realpath", "recode-sr-latin",
    "refer", "rename", "renice", "replace", "repo-graph", "repo-rss", "repoclosure",
    "repodiff", "repomanage", "repoquery", "reposync", "repotrack", "RESET",
    "reset", "resolveip", "resolve_stack_dump", "rev", "rm", "rmdir", "roff2dvi",
    "roff2html", "roff2pdf", "roff2ps", "roff2text", "roff2x", "rsync", "runcon",
    "runuser", "sadf", "sar", "sar2pcp", "scmp_sys_resolver", "scp", "screen",
    "script", "scriptreplay", "sdiff", "secon", "sed", "seq", "setfacl", "setfattr",
    "setleds", "setmetamode", "setpriv", "setsid", "setterm", "sftp", "sg",
    "sha1sum", "sha224sum", "sha256sum", "sha384sum", "sha512sum", "sheet2pcp",
    "show-changed-rco", "show-installed", "showkey", "shred", "shuf", "size",
    "skill", "slabtop", "sleep", "snice", "soelim", "sort", "sparse", "split",
    "sprof", "srptool", "ssh-add", "ssh-agent", "ssh-keygen", "ssh-keyscan", "ssh",
    "SSHFS", "sshfs", "stap-merge", "stap-prep", "stap-report", "stap", "stapref",
    "stapvirt", "stat", "stdbuf", "stg-branch", "stg-clean", "stg-clone",
    "stg-commit", "stg-delete", "stg-diff", "stg-edit", "stg-export", "stg-files",
    "stg-float", "stg-fold", "stg-goto", "stg-hide", "stg-id", "stg-import",
    "stg-init", "stg-log", "stg-mail", "stg-new", "stg-next", "stg-patches",
    "stg-pick", "stg-pop", "stg-prev", "stg-publish", "stg-pull", "stg-push",
    "stg-rebase", "stg-redo", "stg-refresh", "stg-rename", "stg-repair",
    "stg-reset", "stg-series", "stg-show", "stg-sink", "stg-squash", "stg-sync",
    "stg-top", "stg-uncommit", "stg-undo", "stg-unhide", "stg", "strace", "strings",
    "strip", "stty", "su", "sum", "sync", "systemctl", "systemd-analyze",
    "systemd-ask-password", "systemd-bootchart", "systemd-cat", "systemd-cgls",
    "systemd-cgtop", "systemd-delta", "systemd-detect-virt", "systemd-escape",
    "systemd-firstboot", "systemd-firstboot.service", "systemd-inhibit",
    "systemd-machine-id-setup", "systemd-mount", "systemd-notify", "systemd-nspawn",
    "systemd-path", "systemd-resolve", "systemd-run", "systemd-socket-activate",
    "systemd-tty-ask-password-agent", "systemd-umount", "systemd", "systemkey-tool",
    "TABS", "tabs", "tac", "tail", "tapestat", "tar", "taskset", "tbl", "tcpdump",
    "tee", "telnet-probe", "test", "tfmtodit", "time", "timedatectl", "timeout",
    "tload", "tmux", "tokuftdump", "tokuft_logdump", "tokuft_logprint", "top",
    "touch", "tpmtool", "TPUT", "tput", "tr", "trace-cmd-check-events",
    "trace-cmd-extract", "trace-cmd-hist", "trace-cmd-list", "trace-cmd-listen",
    "trace-cmd-mem", "trace-cmd-options", "trace-cmd-profile", "trace-cmd-record",
    "trace-cmd-report", "trace-cmd-reset", "trace-cmd-restore", "trace-cmd-show",
    "trace-cmd-snapshot", "trace-cmd-split", "trace-cmd-stack", "trace-cmd-start",
    "trace-cmd-stat", "trace-cmd-stop", "trace-cmd-stream", "trace-cmd", "troff",
    "true", "truncate", "TSET", "tset", "tsort", "tty", "ul", "uname", "unexpand",
    "unicode_start", "unicode_stop", "uniq", "unlink", "unshare",
    "update-alternatives", "updatedb", "uptime", "usb-devices", "users", "utmpdump",
    "uuidgen", "valgrind-listener", "valgrind", "vdir", "verify_blkparse",
    "verifytree", "vgdb", "vlock", "w", "wall", "watch", "wc", "Wget", "wget",
    "whatis", "whereis", "who", "whoami", "windmc", "windres", "write",
    "wsrep_sst_common", "wsrep_sst_mysqldump", "wsrep_sst_rsync",
    "wsrep_sst_xtrabackup-v2", "wsrep_sst_xtrabackup", "xargs", "xgettext", "yes",
    "ypdomainname", "yum-aliases", "yum-builddep", "yum-changelog",
    "yum-config-manager", "yum-debug-dump", "yum-debug-restore", "yum-filter-data",
    "yum-fs-snapshot", "yum-groups-manager", "yum-list-data", "yum-ovl",
    "yum-utils", "yum-verify", "yum-versionlock", "yumdownloader", "zenmap",
    "zsoelim"
}

man1p_items = Set {
    "admin", "alias", "ar", "asa", "at", "awk", "basename", "batch", "bc",
    "bg", "break", "c99", "cal", "cat", "cd", "cflow", "chgrp", "chmod",
    "chown", "cksum", "cmp", "colon", "comm", "command", "compress",
    "continue", "cp", "crontab", "csplit", "ctags", "cut", "cxref", "date",
    "dd", "delta", "df", "diff", "dirname", "dot", "du", "echo", "ed",
    "env", "eval", "ex", "exec", "exit", "expand", "export", "expr",
    "false", "fc", "fg", "file", "find", "fold", "fort77", "fuser",
    "gencat", "get", "getconf", "getopts", "grep", "hash", "head", "iconv",
    "id", "ipcrm", "ipcs", "jobs", "join", "kill", "lex", "link", "ln",
    "locale", "localedef", "logger", "logname", "lp", "ls", "m4", "mailx",
    "make", "man", "mesg", "mkdir", "mkfifo", "more", "mv", "newgrp",
    "nice", "nl", "nm", "nohup", "od", "paste", "patch", "pathchk", "pax",
    "pr", "printf", "prs", "ps", "pwd", "qalter", "qdel", "qhold", "qmove",
    "qmsg", "qrerun", "qrls", "qselect", "qsig", "qstat", "qsub", "read",
    "readonly", "renice", "return", "rm", "rmdel", "rmdir", "sact", "sccs",
    "sed", "set", "sh", "shift", "sleep", "sort", "split", "strings",
    "strip", "stty", "tabs", "tail", "talk", "tee", "test", "time",
    "times", "touch", "tput", "tr", "trap", "true", "tsort", "tty", "type",
    "ulimit", "umask", "unalias", "uname", "uncompress", "unexpand", "unget",
    "uniq", "unlink", "unset", "uucp", "uudecode", "uuencode", "uustat",
    "uux", "val", "vi", "wait", "wc", "what", "who", "write", "xargs",
    "yacc", "zcat"
}
man2_items = Set {

    "accept","access","acct","adjtimex","afs_syscall","alarm","alloc_hugepages",
    "arch_prctl","bdflush","bind","break","brk","cacheflush","capget","capset",
    "chdir","chmod","chown","chroot","clone","close","connect","creat",
    "create_module","DC_CTX_new","DC_PLUG_new","DC_PLUG_read","DC_SERVER_new",
    "delete_module","dup2","dup","epoll_create","epoll_ctl","epoll_wait","execve",
    "_exit","fchdir","fchmod","fchown","fcntl","fdatasync","fgetxattr","flistxattr",
    "flock","fork","free_hugepages","fremovexattr","fsetxattr","fstat","fstatfs",
    "fstatvfs","fsync","ftruncate","futex","getcontext","getdents","getdomainname",
    "getdtablesize","getegid","geteuid","getgid","getgroups","gethostid",
    "gethostname","getitimer","get_kernel_syms","getpagesize","getpeername",
    "getpgid","getpgrp","getpid","getpmsg","getppid","getpriority","getresgid",
    "getresuid","getrlimit","getrusage","getsid","getsockname","getsockopt",
    "get_thread_area","gettid","gettimeofday","getuid","getxattr","gtty","idle",
    "inb","inb_p","init_module","inl","inl_p","insb","insl","insw","intro","inw",
    "inw_p","io_cancel","ioctl","ioctl_list","io_destroy","io_getevents","ioperm",
    "iopl","io_setup","io_submit","ipc","kill","killpg","lchown","lgetxattr","link",
    "listen","listxattr","llistxattr","_llseek","llseek","lock","lookup_dcookie",
    "lremovexattr","lseek","lsetxattr","lstat","madvise","mbind","mincore","mkdir",
    "mknod","mlock.2","mlock","mlockall.2","mlockall","mmap2","mmap","modify_ldt",
    "mount","mprotect","mpx","mremap","msgctl","msgget","msgop","msgrcv","msgsnd",
    "msync","munlock","munlockall","munmap","NAL_ADDRESS_new","NAL_BUFFER_new",
    "NAL_CONNECTION_new","NAL_decode_uint32","NAL_LISTENER_new","NAL_SELECTOR_new",
    "nanosleep","_newselect","nfsservctl","nice","obsolete","oldfstat","oldlstat",
    "oldolduname","oldstat","olduname","open","outb","outb_p","outl","outl_p",
    "outsb","outsl","outsw","outw","outw_p","pause","pciconfig_iobase",
    "pciconfig_read","pciconfig_write","personality","pipe","pivot_root","poll",
    "posix_fadvise","prctl","pread","prof","pselect","ptrace","putpmsg","pwrite",
    "query_module","quotactl","read","readahead","readdir","readlink","readv",
    "reboot","recv","recvfrom","recvmsg","remap_file_pages","removexattr","rename",
    "rmdir","sbrk","sched_getaffinity","sched_getparam","sched_get_priority_max",
    "sched_get_priority_min","sched_getscheduler","sched_rr_get_interval",
    "sched_setaffinity","sched_setparam","sched_setscheduler","sched_yield",
    "security","select","select_tut","semctl","semget","semop","semtimedop","send",
    "sendfile","sendmsg","sendto","setcontext","setdomainname","setegid","seteuid",
    "setfsgid","setfsuid","setgid","setgroups","sethostid","sethostname","setitimer"
    ,"set_mempolicy","setpgid","setpgrp","setpriority","setregid","setresgid",
    "setresuid","setreuid","setrlimit","setsid","setsockopt","set_thread_area",
    "settimeofday","setuid","setup","setxattr","sgetmask","shmat","shmctl","shmdt",
    "shmget","shmop","shutdown","sigaction","sigaltstack","sigblock","siggetmask",
    "sigmask","signal","sigpause","sigpending","sigprocmask","sigqueue","sigreturn",
    "sigsetmask","sigsuspend","sigtimedwait","sigvec","sigwaitinfo","socket",
    "socketcall","socketpair","ssetmask","sstk","stat","statfs","statvfs","stime",
    "stty","swapoff","swapon","symlink","sync","syscall","syscalls","_sysctl",
    "sysctl","sysfs","sysinfo","syslog","time","times","tkill","truncate","tux",
    "umask","umount2","umount","uname","undocumented","unimplemented","unlink",
    "uselib","ustat","utime","utimes","vfork","vhangup","vm86","wait","wait3",
    "wait4","waitpid","write","writev"
}


  function getURL(token, manId, pId)
    url='http://man7.org/linux/man-pages/man'..manId .. '/' .. token .. '.'..manId..pId..'.html'

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

    if state~=HL_KEYWORD and state ~=HL_STANDARD then return end

    if man1_items[token] then
      return getURL(token, 1, "")
    elseif man1p_items[token] then
      return getURL(token, 1, "p")
    elseif man2_items[token] then
      return getURL(token, 2, "")
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
