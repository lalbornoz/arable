#!/bin/sh
#

process_appdata_legend="%APPDATA% subdirectories";

process_appdata() {
	local	_nflag="${1}" _domain="${2}" _hname="${3}" _uname="${4}"			\
		_private_dname="domains/${2}/private/${4}_%APPDATA%@${3%.}";

	if [ -e "${_private_dname}" ]; then
		msgf -- "36" "Pull user-local %%APPDATA%% subdirectories: "
		msgf "1" "%s@%s\n" "${_uname}" "${_hname}";
		rsync_pull "${_nflag}" "${_uname}" "${_hname}"				\
			"/cygdrive/c/Users/${_uname}/AppData/Roaming/"			\
			"${_private_dname}/"						\
			"--exclude=.RSYNC_FILES_FROM --include-from=${_private_dname}/.RSYNC_FILES_FROM";
		if [ -z "${_nflag}" ]; then
			msgf -- "36" "Commit to Git repository";
			msgf "1" "%s@%s\n" "${_uname}" "${_hname}";
			(cd "${_private_dname}"						\
			 && git add .							\
			 && [ $(git status --porcelain . | wc -l) -gt 0 ]		\
			 && git commit							\
				-m "Automatic %APPDATA% subdirectory pull from ${_uname}@${_hname} to ${USER}@$(hostname -f)." . || exit 0);
		fi;
	fi;
};

# vim:foldmethod=marker sw=8 ts=8 tw=120
