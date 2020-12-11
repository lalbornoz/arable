#!/bin/sh
#

source_dir() {
	local _dname="${1}" _script_fname="";
	set +o noglob; for _script_fname in "${_dname}"/*.subr; do
		. "${_script_fname}" || exit "${?}";
	done; set -o noglob;
};

arable() {
	local	_cflag="${1}" _domain="${2}" _hname="${3}" _funs="${4}" _lfilter="${5}"		\
		_llimit="${6}" _log_fname="${7}" _nflag="${8}" _tasks="${9}" _uname="${10}"	\
		_hosts_line="" _fun="" _log_fname_abs="" _rc=0 _script_fname="";

	for _script_fname in $(set +o noglob; echo domains/${_domain}/tasks/*.sh); do
		. "${_script_fname}"; _fun="${_script_fname##*/}"; _fun="${_fun#*.}";
		_funs="${_funs:+${_funs} }process_${_fun%%.sh}";
	done
	[ -z "${_log_fname}" ]	&& { _log_fname_abs="${_domain}.log"; msgf_log_fname "${_log_fname_abs}"; }\
				|| { _log_fname_abs="${_log_fname}"; msgf_log_fname "${_log_fname_abs}"; };
	for _fun in ${_funs}; do
		if [ -z "${_tasks}" ] || lsearch "${_tasks}" "${_fun#process_}"; then
			msgf -- "96;4" "--- %s ---\n" "$(eval printf \""%s"\" \""\${${_fun}_legend}"\")";
			while read _hosts_line; do
				trap "exit 0" HUP INT TERM USR1 USR2;
				if [ -n "${_hosts_line}" ]					\
				&& [ "${_hosts_line#\#}" = "${_hosts_line}" ]; then
					_uname="${_hosts_line%%@*}"; _hname="${_hosts_line##*@}";
					if [ -n "${_uname}" ] && [ -n "${_hname}" ]\
					&& ! filter "${_hname}" "${_uname}" "${_lfilter}" "${_llimit}"; then
						if [ -n "${_log_fname_abs}" ]; then
							("${_fun}" "${_nflag}" "${_domain}" "${_hname}" "${_uname}" 2>&1 | tee -a "${_log_fname_abs}"); _rc="${?}";
						else
							("${_fun}" "${_nflag}" "${_domain}" "${_hname}" "${_uname}" 2>&1); _rc="${?}";
						fi;
						case "${_cflag}${_rc}" in
						[01]0)	;;
						0*)	exit "${_rc}"; ;;
						1*)	msgf -- "31" "(ignoring soft failure due to -c)\n"; ;;
						esac;
					fi;
				fi;
			done < "domains/${_domain}/hosts";
		fi;
	done;
};

list_all() {
	local _domain="" _hname="" _hosts_line="" _rc=0 _script_fname="" _task="" _uname="";

	if [ "${#}" -eq 0 ]; then
		set -- $(cd domains && find -maxdepth 1 -mindepth 1 -type d -printf '%P\n');
	fi;
	for _domain in "${@}"; do
			msgf -- "36" "Host: ";
			msgf "" "%s@" "${_uname}"; msgf "4;1" "%s\n" "${_hname}";
		if ! [ -e "domains/${_domain}" ]; then
			msgf -- "31" "Warning: ignoring non-existing domain \`%s'\n" "${_domain}"; _rc=1;
		else
			msgf -- "96" "Hosts of domain: "; msgf "1" "%s\n" "${_domain}";
			msgf -- "35" "Tasks of domain: "; msgf "1" "%s\n" "${_domain}"; msgf -- "35" "";
			for _script_fname in $(set +o noglob; echo "domains/${_domain}/tasks"/*.sh); do
				_task="${_script_fname##*/}"; _task="${_task#*.}";
				msgf "4" "%s" "${_task%%.sh}"; msgf "" " ";
			done; msgf "" "\n\n";
		fi;
	done; return "${_rc}";
};

ex_load_hosts() {
	local	_hosts_fname="${1}" _groups="" _hname="" _line=""	\
		_nline=0 _schedule="" _section="" _uname=""		\
		_vname="" _vval="";

	while read _line; do : $((_nline+=1));
		case "${_line}" in
		\[*\])
			_section="${_line#[\[]}"; _section="${_section%[]]}";
			;;
		*=*)
			_vname="${_line%%=*}"; _vval="${_line##*=}";
			;;
		[_0-9a-zA-Z]*)
			set -- ${_line}; _hname="${1#*@}"; _uname="${1%@*}"; shift;
			;;
		[[:space:]]*\#*)
			;;
		)	
			;;
		*)
			msgf -- "91" "Error: invalid line #%d (%s)" "${_nline}" "${_line}";
			;;
		esac;
	done <"${_hosts_fname}";
};

usage() {
{	printf "usage: ${0} [-h] [-c] [-F [user@]host[,..]] [-H [user@]host[,..]]\n";
	printf "       [-l] [-L [fname]] [-n] [-t task[,..]] [-x] domain [domain..]\n";
	printf "\n";
	printf "       -h..........: show this screen\n";
	printf "       -c..........: continue on soft failure\n";
	printf "       -F host.....: filter by hostname and/or username@hostname (processed after -H)\n";
	printf "       -H host.....: limit by hostname and/or username@hostname\n";
	printf "       -l..........: list domains, hosts & tasks and exit\n";
	printf "       -L [fname]..: additionally log to fname (defaults to: <domain>.log)\n";
	printf "       -n..........: perform dry run\n";
	printf "       -t task.....: limit by task\n";
	printf "       -x..........: enable xtrace debugging\n"
} >&2; };

main() {
	local	_cflag=0 _domain="" _lfilter="" _lflag=0 _llimit="" _log_fname=""	\
		_nflag="" _tasks="" _xflag=0 _funs="" _hname="" _opt="" _rc=0		\
		_uname="" OPTARG="";
	source ./rtl.subr || exit 1; while getopts chF:H:lLnt:x _opt; do
	case "${_opt}" in
	c)	_cflag=1; ;;
	F)	_lfilter="$(echo "${OPTARG}" | sed 's/,/ /g')"; ;;
	h)	usage; exit 0; ;;
	H)	_llimit="$(echo "${OPTARG}" | sed 's/,/ /g')"; ;;
	l)	_lflag=1; ;;
	L)	set +o nounset; [ \( "${#}" -ge 2 \) -a \( "${2#-}" = "${2}" \) ] && { _log_fname="${2}"; shift; } || _log_fname=""; set -o nounset; ;;
	n)	_nflag="1"; ;;
	t)	_tasks="$(echo "${OPTARG}" | sed 's/,/ /g')"; ;;
	x)	_xflag=1; set -o xtrace; ;;
	*)	usage; exit 2; ;;
	esac; shift $((${OPTIND}-1)); OPTIND=1; done;
	if [ "${_lflag}" -eq 1 ]; then
		list_all "${@}";
	elif [ "${#}" -eq 0 ]; then
		msgf -- "91" "Error: missing domain(s)\n"; usage; _rc=2;
	else
		for _domain in "${@}"; do
			if ! [ -e "domains/${_domain}" ]; then
				case "${_cflag}" in
				0)	msgf -- "91" "Error: non-existing domain \`%s'\n" "${_domain}"; usage; _rc=3; break; ;;
				1)	msgf -- "90" "Warning: ignoring non-existing domain \`%s'\n" "${_domain}"; ;;
				esac;
			else
				arable	\
					"${_cflag}" "${_domain}" "${_hname}" "${_funs}"  "${_lfilter}"	\
					"${_llimit}" "${_log_fname}" "${_nflag}" "${_tasks}" "${_uname}";
				[ "${?}" -ne 0 ] && _rc=4;
			fi;
		done;
	fi; return "${_rc}";
};

set +o errexit -o noglob -o nounset; main "${@}";

# vim:foldmethod=marker sw=8 ts=8 tw=120
