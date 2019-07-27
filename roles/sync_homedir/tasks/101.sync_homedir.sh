#!/bin/sh

rc() {
	local _choice="" _log_fname="${1}" _cmd="${2}"; shift 2;
	printf "Run command: %s %s? (y|N) " "${_cmd}" "${*}";
	read _choice;
	case "${_choice}" in
	[yY])	set +o errexit;
		if [ -n "${_log_fname}" ]; then
			"${_cmd}" "${@}" 2>&1 | tee -a "${_log_fname}";
		else
			"${_cmd}" "${@}";
		fi;
		set -o errexit; ;;
	*)	return 0; ;;
	esac;
};

usage() {
	local _rc="${1}" _msg="${2:-}";
	if [ -n "${_msg}" ]; then
		printf "%s\n" "${_msg}" >&2;
	fi;
	echo "usage: ${0##*/} [-d dest] [-h] [-L] [-n] [--] target[..]" >&2;
	exit "${_rc}";
};

main() {
	local _dst="" _log_fname="" _Lflag=0 _nflag=0 _opt="" _rc=0 _rsync_args_extra="" _target="";
	while getopts d:hLn _opt; do
	case "${_opt}" in
	d)	_dst="${OPTARG}"; ;;
	L)	_Lflag=1; ;;
	n)	_nflag=1; _rsync_args_extra="-n"; ;;
	*)	usage 1; ;;
	esac; done; shift $((${OPTIND}-1));
	if [ "${#}" -eq 0 ]; then
		usage 1 "missing target";
	else
		while [ "${#}" -gt 0 ]; do
			_target="${1}"; shift
			case "${_target}" in
			abbad)			_dst="${_dst:-/cygdrive/h/}"; ;;
			lucio-home-backup00)	_dst="${_dst:-/cygdrive/g/}"; ;;
			lucio-thinkpad)		_dst="${_dst:-lucio-thinkpad.}:"; ;;
			*) 		echo "error: unknown target \`${_target}'" >&2;
					continue; _rc=1; ;;
			esac;
			if [ "${_Lflag}" -eq 0 ]; then
				_log_fname="rsync_${_target}-${USER}@$(hostname -f)-$(date +%d%m%Y-%H%M%S).log";
				printf "" > "${_log_fname}";
			fi;
			case "${_target}" in
			lucio-home-backup00)
				rc "${_log_fname}" rsync								\
					-aiPv --delete									\
					${_rsync_args_extra}								\
						--exclude="/\$RECYCLE.BIN"						\
						--exclude="/Movies and TV shows - KaraGarga archive"			\
						--exclude="/System Volume Information"					\
						. "${_dst}"; ;;
			*)
				rc "${_log_fname}" rsync								\
					-aiPv --delete									\
					${_rsync_args_extra}								\
						"Documents - Backups"							\
						"Documents - Photographies and pictures"				\
						"Documents - Repositories"						\
						"Documents - Zoo of documents"						\
						TODO									\
						"${_dst}"; ;;
			esac;
		done;
		exit "${_rc}";
	fi;
};

set -o errexit -o noglob -o nounset; main "${@}";
