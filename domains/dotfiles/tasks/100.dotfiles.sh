#!/bin/sh
#



process_dotfiles_legend="SHARED AND {HOST,USER}-LOCAL DOTFILES";
process_dotfiles_exclude="
	***/__pycache__/
	***/*.sw[op]
	***/.*.sw[op]
	***/.directory_mode
	***/.directory_optional
	***/.shared_directory
	.*_optional/
	.git/
	.gitignore
	.gitmodules
	.irssi/
	.ssh/known_hosts
	.ssh/private/
";

process_dotfiles_() {
	local	_nflag="${1}" _dst="${2}" _domain="${3}" _hname="${4}" _private_dname="${5}"	\
		_shared_dname="${6}" _uname="${7}" _include_fname="";

	if _include_fname="$(mktemp -t "${0##*/}.XXXXXX")"; then
		trap "rm -f \"${_include_fname}\" 2>/dev/null" EXIT HUP INT TERM USR1 USR2;
		build_excludes ${process_dotfiles_exclude} >>"${_include_fname}";
		build_includes "${_shared_dname}" >>"${_include_fname}";
		if [ -e "${_private_dname}" ]; then
			build_includes "${_private_dname}" "" 1 >>"${_include_fname}";
			build_finish >>"${_include_fname}";
			rsync_push "${_nflag}" "${_uname}" "${_hname}" "${_dst}"		\
				"${_include_fname}" ""						\
				"${_shared_dname}/" "${_private_dname}/";
		else
			build_finish >>"${_include_fname}";
			rsync_push "${_nflag}" "${_uname}" "${_hname}" "${_dst}"		\
				"${_include_fname}" ""						\
				"${_shared_dname}/";
		fi;
		mode_push "${_nflag}" "${_uname}" "${_hname}";
		rm -f "${_include_fname}" 2>/dev/null;
		trap - EXIT HUP INT TERM USR1 USR2;
	fi;
};

process_dotfiles() {
	local	_nflag="${1}" _domain="${2}" _hname="${3}" _uname="${4}"		\
		_private_dname="domains/${2}/private/${4}@${3%.}" _shared_dname="domains/${2}/shared";

	if [ "${_hname}" = "$(hostname -f | sed -ne '/^[^\.]\+$/s/$/.local/')" ]\
	&& [ "${_uname}" = "$(id -nu)" ]; then
		msgf -- "36" "(ignoring attempted transfer from local to local host)\n";
		return 0;
	elif [ -e "${_shared_dname}" ]\
	||   [ -e "${_private_dname}" ]; then
		case "${_uname}" in
		[rR][oO][oO][tT])
			msgf -- "36" "Transfer shared dotfiles into /etc/skel/: "
			msgf "1" "%s@%s\n" "${_uname}" "${_hname}";
			process_dotfiles_						\
				"${_nflag}" "/etc/skel" "${_domain}" "${_hname}"	\
				"${_private_dname}" "${_shared_dname}" "${_uname}"; ;;
		esac;
		msgf -- "36" "Transfer shared and {user,host}-local dotfiles: ";
		msgf "1" "%s@%s\n" "${_uname}" "${_hname}";
		process_dotfiles_							\
			"${_nflag}" "" "${_domain}" "${_hname}"				\
			"${_private_dname}" "${_shared_dname}" "${_uname}";
	fi;
};

# vim:foldmethod=marker sw=8 ts=8 tw=120
