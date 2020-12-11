#!/bin/sh
#

process_irssi_legend="Irssi directories";

process_irssi() {
	local _nflag="${1}" _domain="${2}" _hname="${3}" _uname="${4}"		\
		_private_dname="domains/${2}/private/${4}@${3%.}/.irssi";

	if [ -e "${_private_dname}" ]; then
		msgf -- "36" "Pull user- and host-local irssi dotdir: ";
		msgf "1" "%s@%s\n" "${_uname}" "${_hname}";
		rsync_pull "${_nflag}" "${_uname}" "${_hname}"			\
			".irssi/"						\
			"${_private_dname}"					\
			"--exclude=away.log --exclude=logs";
		if [ -z "${_nflag}" ]; then
			msgf -- "36" "Commit to Git repository: ";
			msgf "1" "%s@%s\n" "${_uname}" "${_hname}";
			(cd "${_private_dname}"					\
			 && git add .irssi					\
			 && [ $(git status --porcelain .irssi | wc -l) -gt 0 ]	\
			 && git commit						\
				-m "Automatic irssi dotdir pull from ${_uname}@${_hname} to ${USER}@$(hostname -f)." .irssi || exit 0);
		fi;
	fi;
};

# vim:foldmethod=marker sw=8 ts=8 tw=120
