#!/bin/sh
#



process_backup_hosts_legend="HOST BACKUPS";

process_backup_hosts() {
	local	_nflag="${1}" _domain="${2}" _hname="${3}" _uname="${4}"	\
		_private_dname="domains/${2}/private/${3%.}";

	msgf -- "36" "Pulling host backup: "; msgf "1" "%s@%s\n" "${_uname}" "${_hname}";
	if ! [ -e "${_private_dname}" ]; then
		if [ -z "${_nflag}" ]; then
			mkdir -p "${_private_dname}";
		fi;
	fi;
	rsync_pull "${_nflag}" "${_uname}" "${_hname}"				\
		"${_private_dname}" "${_private_dname}/.RSYNC_INCLUDE_FROM"	\
		"--numeric-ids" "/";
	if [ -z "${_nflag}" ]; then
		msgf -- "36" "Producing compressed host backup tarball: "; msgf "1" "%s@%s\n" "${_uname}" "${_hname}";
		(cd "${_private_dname}/.." && tar -cpf - "${3%.}" | bzip2 -c -9 - > "${3%.}.tbz2");
	fi;

};

# vim:foldmethod=marker sw=8 ts=8 tw=120
