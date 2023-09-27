# Installation script for highlight.
# See INSTALL for details.

# Installation directories:

# Destination directory for installation (intended for packagers)
DESTDIR =

# Root directory for final installation
PREFIX = /usr

# Data file directory
data_dir = ${PREFIX}/share/

# Location of the highlight data files:
hl_data_dir = ${data_dir}highlight/

# Location of the highlight binary:
bin_dir = ${PREFIX}/bin/

# Location of the highlight library:
lib_dir = ${PREFIX}/lib/

# Location of the highlight man pages:
man_dir = ${data_dir}man/

# Documentation directory
doc_dir = ${data_dir}doc/

# Location of the highlight documentation:
hl_doc_dir = ${doc_dir}highlight/

# Location of the highlight extras:
examples_dir = ${hl_doc_dir}extras/

# Location of system-wide config files:
ifeq (${PREFIX},/usr)
	conf_dir = /etc/
else
	conf_dir = ${PREFIX}/etc/
endif

# Location of the highlight config files:
hl_conf_dir = ${conf_dir}highlight/

# Location of bash completions:
bash_comp_dir = ${data_dir}bash-completion/completions/

# Location of fish completions:
fish_comp_dir = ${data_dir}fish/vendor_completions.d/

# Location of zsh completions:
zsh_comp_dir = ${data_dir}zsh/site-functions/

# Location of additional gui files
desktop_apps = ${data_dir}applications/
desktop_icons = ${data_dir}icons/hicolor/256x256/apps/

# Commands:
GZIP=gzip -9f
INSTALL_DATA=install -m644
INSTALL_PROGRAM=install -m755
MKDIR=mkdir -p -m 755
RMDIR=rm -r -f

all cli:
	${MAKE} -C ./src -f ./makefile2.makefile HL_DATA_DIR=${hl_data_dir} HL_CONFIG_DIR=${hl_conf_dir}

lib lib-static:
	${MAKE} -C ./src -f ./makefile2.makefile HL_DATA_DIR=${hl_data_dir} HL_CONFIG_DIR=${hl_conf_dir} lib-static

lib-shared:
	${MAKE} -C ./src -f ./makefile2.makefile HL_DATA_DIR=${hl_data_dir} HL_CONFIG_DIR=${hl_conf_dir} PIC=1 lib-shared

gui:
	${MAKE} -C ./src -f ./makefile2.makefile HL_DATA_DIR=\"${hl_data_dir}\" HL_CONFIG_DIR=\"${hl_conf_dir}\" HL_DOC_DIR=\"${hl_doc_dir}\" gui-qt
	@echo
	@echo "You need to run 'make install' AND 'make install-gui' now!"

install:
	@echo "This script will install highlight in the following directories:"
	@echo "Data directory:             ${DESTDIR}${hl_data_dir}"
	@echo "Documentation directory:    ${DESTDIR}${hl_doc_dir}"
	@echo "Plugin directory:           ${DESTDIR}${hl_data_dir}plugins/"
	@echo "Examples directory:         ${DESTDIR}${examples_dir}"
	@echo "Manual directory:           ${DESTDIR}${man_dir}"
	@echo "Binary directory:           ${DESTDIR}${bin_dir}"
	@echo "Configuration directory:    ${DESTDIR}${hl_conf_dir}"
	@echo "Bash completions directory: ${DESTDIR}${bash_comp_dir}"
	@echo "Fish completions directory: ${DESTDIR}${fish_comp_dir}"
	@echo "Zsh completions directory:  ${DESTDIR}${zsh_comp_dir}"
	@echo

	${MKDIR} ${DESTDIR}${hl_doc_dir}
	${MKDIR} ${DESTDIR}${hl_conf_dir}
	${MKDIR} ${DESTDIR}${examples_dir} \
		${DESTDIR}${examples_dir}swig \
		${DESTDIR}${examples_dir}tcl \
		${DESTDIR}${examples_dir}pandoc \
		${DESTDIR}${examples_dir}json \
		${DESTDIR}${examples_dir}pywal \
		${DESTDIR}${examples_dir}langDefs-resources \
		${DESTDIR}${examples_dir}themes-resources \
		${DESTDIR}${examples_dir}themes-resources/base16 \
		${DESTDIR}${examples_dir}themes-resources/css-themes

	${MKDIR} ${DESTDIR}${hl_data_dir} \
		${DESTDIR}${hl_data_dir}themes \
		${DESTDIR}${hl_data_dir}themes/base16 \
		${DESTDIR}${hl_data_dir}langDefs \
		${DESTDIR}${hl_data_dir}plugins
	${MKDIR} ${DESTDIR}${man_dir}man1/
	${MKDIR} ${DESTDIR}${man_dir}man5/
	${MKDIR} ${DESTDIR}${bash_comp_dir}
	${MKDIR} ${DESTDIR}${fish_comp_dir}
	${MKDIR} ${DESTDIR}${zsh_comp_dir}
	${MKDIR} ${DESTDIR}${bin_dir}

	${INSTALL_DATA} ./langDefs/*.lang ${DESTDIR}${hl_data_dir}langDefs/
	${INSTALL_DATA} ./*.conf ${DESTDIR}${hl_conf_dir}
	${INSTALL_DATA} ./themes/*.theme ${DESTDIR}${hl_data_dir}themes/
	${INSTALL_DATA} ./themes/base16/*.theme ${DESTDIR}${hl_data_dir}themes/base16/
	${INSTALL_DATA} ./plugins/*.lua ${DESTDIR}${hl_data_dir}plugins/
	${INSTALL_DATA} ./man/highlight.1 ${DESTDIR}${man_dir}man1/
	${GZIP} ${DESTDIR}${man_dir}man1/highlight.1
	${INSTALL_DATA} ./man/filetypes.conf.5 ${DESTDIR}${man_dir}man5/
	${GZIP} ${DESTDIR}${man_dir}man5/filetypes.conf.5

	${INSTALL_DATA} ./sh-completion/highlight.bash ${DESTDIR}${bash_comp_dir}highlight
	${INSTALL_DATA} ./sh-completion/highlight.fish ${DESTDIR}${fish_comp_dir}
	${INSTALL_DATA} ./sh-completion/highlight.zsh ${DESTDIR}${zsh_comp_dir}_highlight

	${INSTALL_DATA} ./AUTHORS ${DESTDIR}${hl_doc_dir}
	${INSTALL_DATA} ./README* ${DESTDIR}${hl_doc_dir}
	${INSTALL_DATA} ./ChangeLog.adoc ${DESTDIR}${hl_doc_dir}
	${INSTALL_DATA} ./COPYING ${DESTDIR}${hl_doc_dir}
	${INSTALL_DATA} ./INSTALL ${DESTDIR}${hl_doc_dir}
	${INSTALL_DATA} ./extras/swig/* ${DESTDIR}${examples_dir}swig
	${INSTALL_DATA} ./extras/tcl/* ${DESTDIR}${examples_dir}tcl
	${INSTALL_DATA} ./extras/pandoc/* ${DESTDIR}${examples_dir}pandoc
	${INSTALL_DATA} ./extras/pywal/* ${DESTDIR}${examples_dir}pywal
	${INSTALL_DATA} ./extras/json/* ${DESTDIR}${examples_dir}json
	${INSTALL_DATA} ./extras/langDefs-resources/* ${DESTDIR}${examples_dir}langDefs-resources
	${INSTALL_DATA} ./extras/themes-resources/base16/* ${DESTDIR}${examples_dir}themes-resources/base16
	${INSTALL_DATA} ./extras/themes-resources/css-themes/* ${DESTDIR}${examples_dir}themes-resources/css-themes
	${INSTALL_DATA} ./extras/highlight_pipe.* ${DESTDIR}${examples_dir}
	${INSTALL_DATA} ./extras/*.py ${DESTDIR}${examples_dir}
	${INSTALL_PROGRAM} ./src/${BUILD_DIR}/highlight ${DESTDIR}${bin_dir}

	@echo
	@echo "Done."
	@echo "Type highlight --help or man highlight for instructions."
	@echo "Take a look at ${DESTDIR}${examples_dir} for scripts, SWIG and TCL bindings."
	@echo "Execute 'make install-gui' to install the highlight GUI ('make gui')."
	@echo "Do not hesitate to report problems. Unknown bugs are hard to fix."

install-gui:
	@echo "Installing files for the GUI..."
	${MKDIR} ${DESTDIR}${hl_data_dir} \
		${DESTDIR}${hl_data_dir}gui_files \
		${DESTDIR}${hl_data_dir}gui_files/ext \
		${DESTDIR}${hl_data_dir}gui_files/l10n \
		${DESTDIR}${desktop_apps} \
		${DESTDIR}${desktop_icons}

	${INSTALL_DATA} ./gui_files/l10n/* ${DESTDIR}${hl_data_dir}gui_files/l10n/
	${INSTALL_DATA} ./gui_files/ext/* ${DESTDIR}${hl_data_dir}gui_files/ext/
	${INSTALL_DATA} ./highlight.desktop ${DESTDIR}${desktop_apps}
	${INSTALL_DATA} ./src/gui-qt/highlight.png ${DESTDIR}${desktop_icons}
	${INSTALL_PROGRAM} ./src/highlight-gui ${DESTDIR}${bin_dir}

install-lib-shared:
	${INSTALL_DATA} ./src/libhighlight.so.4.0 ${DESTDIR}${lib_dir}

uninstall:
	@echo "Removing highlight files from system..."
	${RMDIR} ${DESTDIR}${hl_data_dir}
	${RMDIR} ${DESTDIR}${hl_doc_dir}
	${RMDIR} ${DESTDIR}${hl_conf_dir}
	${RMDIR} ${DESTDIR}${examples_dir}
	rm -rf ${DESTDIR}${man_dir}man1/highlight.1.gz
	rm -rf ${DESTDIR}${man_dir}man5/filetypes.conf.5.gz
	rm -rf ${DESTDIR}${bash_comp_dir}highlight
	rm -rf ${DESTDIR}${fish_comp_dir}highlight.fish
	rm -rf ${DESTDIR}${zsh_comp_dir}_highlight
	rm -rf ${DESTDIR}${bin_dir}highlight
	rm -rf ${DESTDIR}${bin_dir}highlight-gui
	rm -rf ${DESTDIR}${desktop_apps}highlight.desktop
	rm -rf ${DESTDIR}${desktop_icons}highlight.png
	@echo "Done."

clean cleanall:
	$(MAKE) -C ./src -f ./makefile2.makefile clean

clean-obj:
	$(MAKE) -C ./src -f ./makefile2.makefile clean-obj

completions:
	sh-completion/gen-completions bash >sh-completion/highlight.bash
	sh-completion/gen-completions fish >sh-completion/highlight.fish
	sh-completion/gen-completions zsh >sh-completion/highlight.zsh

help:
	@echo "This makefile offers the following options:"
	@echo
	@echo "(all)            Compile the command line interface."
	@echo "lib-static       Compile only the static library."
	@echo "lib-shared       Compile only the shared library."
	@echo "gui              Compile the Qt (5.x) GUI."
	@echo "install          Copy all data files to ${hl_data_dir}."
	@echo "install-gui      Copy GUI data files to ${hl_data_dir}."
	@echo "clean            Remove object files and binaries."
	@echo "completions      Generate shell completion scripts."
	@echo "uninstall        Remove highlight files from system."
	@echo
	@echo "See src/makefile for compilation and linking options."

# Target needed for redhat 9.0 rpmbuild
install-strip:

.PHONY: clean all install help uninstall install-strip clean-obj
