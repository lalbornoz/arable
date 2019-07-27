#!/bin/sh

main() {
	local _subdir="";
	find . -maxdepth 1 -mindepth 1 -type d |\
	while read _subdir; do
		cd "${_subdir}";
		./.RSYNC_COMMAND.SH -y;
		cd "${OLDPWD}";
	done;
};

set -o errexit -o noglob -o nounset; main "${@}";
