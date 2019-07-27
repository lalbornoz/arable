#!/bin/sh

pop_IFS() { IFS="${_IFS}"; unset _IFS; };
push_IFS() { _IFS="${IFS}"; IFS="${1}"; };

rc() {
	local _nflag="${1}" _cmd="${2}"; shift 2;
	printf "%s %s\n" "${_cmd}" "${*}";
	case "${_nflag}" in
	1)	printf "Run the above command? (y|N) "; read _choice;
		case "${_choice}" in
		[yY])	return 0;;
		*)	return 1; ;;
		esac; ;;
	*)	;;
	esac;
};

backup_apps() {
	local _nflag="${1}" _hname="${2}" _uname="${3}" _fname_dst="apps.ab";
	if rc "${_nflag}" ssh -l"${_uname}" -T "${_hname}" '
		bu backup -all -apk -keyvalue -noshared -obb -system
		' \> "${_fname_dst}";
	then
		ssh -l"${_uname}" -T "${_hname}" '
			bu backup -all -apk -keyvalue -noshared -obb -system
			' > "${_fname_dst}"; 
	fi;
};

ls_media() {
	local _nflag="${1}" _hname="${2}" _uname="${3}"			\
		_fname_dst="media.lst" _path_src="/data/media/0";
	if rc "${_nflag}" ssh -l"${_uname}" -T "${_hname}" '
		ls -alR '\'''"${_path_src}"''\''
		' \> "${_fname_dst}";
	then
		ssh -l"${_uname}" -T "${_hname}" '
			ls -alR '\'''"${_path_src}"''\''
			' > "${_fname_dst}"; 
	fi;
};

rsync_media() {
	local _nflag="${1}" _hname="${2}" _uname="${3}"			\
		_path_dst="media" _path_src="/data/media/0";
	if rc "${_nflag}" rsync -aiPv --delete				\
		"${_uname}@${_hname}:${_path_src}/" "${_path_dst}/";
	then
		rsync -aiPv --delete					\
			"${_uname}@${_hname}:${_path_src}/" "${_path_dst}/";
	fi;
};

usage() {
	local _rc="${1:-1}";
	printf "usage: %s [-n] [-s]\n" "${0##*/}" >&2;
	exit "${_rc}";
};

main() {
	local _nflag=0 _sflag=0 _device="" _opt="";
	while getopts hns _opt; do
	case "${_opt}" in
	h)	usage 0; ;;
	n)	_nflag=1; ;;
	s)	_sflag=1; ;;
	*)	usage 1; ;;
	esac; done;
	shift $((${OPTIND}-1));
	push_IFS "
";	for _device in $(find . -maxdepth 1 -mindepth 1 -type d); do
		pop_IFS;
		_device="${_device#./}";
		(cd "${_device}"; . ./.backup.rc;
		 if [ "${_sflag}" -eq 0 ]; then
		 	backup_apps "${_nflag}" "${SSH_HOST_NAME}" "${SSH_USER_NAME}";
		 fi;
		 rsync_media "${_nflag}" "${SSH_HOST_NAME}" "${SSH_USER_NAME}";
		 ls_media "${_nflag}" "${SSH_HOST_NAME}" "${SSH_USER_NAME}";
		);
		push_IFS "
";	done;
};

set -o errexit -o noglob -o nounset; main "${@}";
