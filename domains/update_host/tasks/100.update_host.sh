#!/bin/sh
#



process_update_hosts_legend="HOST PACKAGE UPDATES";
# {{{ Remote script variable
REMOTE_SCRIPT='
	fini() { local _log_fname="${1}"; echo "${rc_last:-0} fini"; cat "${_log_fname}"; rm -f "${_log_fname}"; };
	init() { dpkg_new_fnames=""; pkgs=""; pkgs_rdepends=""; pkgs_rdepends_services=""; rc=""; rc_last=""; log_fname="$(mktemp)" || exit 1; };
	status() { local _rc="${1}"; echo "${*}"; rc_last="${_rc}"; if [ "${_rc}" -ne 0 ]; then exit "${_rc}"; fi; };
	init; trap "fini \"${log_fname}\"" EXIT HUP INT QUIT TERM USR1 USR2;

	# apt-get -y update
	apt-get -y update >>"${log_fname}" 2>&1;
	status "${?}" update;

	# apt-get -y dist-upgrade
	pkgs="$(apt-get -y -o Dpkg::Options::="--force-confold" dist-upgrade 2>&1)"; rc="${?}";
	printf "%s\n" "${pkgs}" >>"${log_fname}";
	pkgs="$(printf "%s\n" "${pkgs}"									|
		awk '\''
			$0 == "The following packages will be upgraded:" {m=1; next}
			m {if ($0 !~ /^  /) {m=0} else {print}}'\'')";
	pkgs="$(printf "%s\n" "${pkgs}"									|
		sed -ne "s/  */\n/gp" | sed -ne "/^ *$/d" -e "p" | paste -sd " ")";
	status "${rc}" dist-upgrade "${pkgs}";

	# apt-get -y autoremove --purge
	apt-get -y autoremove --purge >>"${log_fname}" 2>&1;
	status "${?}" autoremove;

	# rm -f /var/cache/apt/archives/*.deb
	rm -f /var/cache/apt/archives/*.deb >>"${log_fname}" 2>&1;
	status "${?}" clean;

	if [ -n "${pkgs}" ]; then
		# apt-cache rdepends --installed
		pkgs_rdepends="$(apt-cache rdepends --installed ${pkgs} 2>&1)"; rc="${?}";
		printf "%s\n" "${pkgs_rdepends}" >>"${log_fname}";
		pkgs_rdepends="$(printf "%s\n" "${pkgs_rdepends}"					|
			sed -n -e "s/^\s\+|\?//" -e "/^Reverse Depends:\$/d" -e "/^lib/d" -e "p"	|
			sort | uniq | paste -sd " ")";
		status "${rc}" rdepends "${pkgs_rdepends}";

		# dpkg -l [ ... ] | grep -Eq "^(/etc/init.d|/lib/systemd/system)/"
		for pkg in ${pkgs_rdepends}; do
			if dpkg -L "${pkg}" 2>>"${log_fname}"						|
			   grep -Eq "^(/etc/init.d|/lib/systemd/system)/"; then
				pkgs_rdepends_services="${pkgs_rdepends_services:+${pkgs_rdepends_services} }${pkg}";
			fi;
		done;
		if [ -n "${pkgs_rdepends_services}" ]; then
			status 0 services "${pkgs_rdepends_services}";
		fi;

		# find /etc -name *.dpkg-new
		dpkg_new_fnames="$(find /etc -name *.dpkg-new 2>/dev/null | paste -d " " -s)";
		if [ -n "${dpkg_new_fnames}" ]; then
			status "${?}" dpkg-new "${dpkg_new_fnames}";
		fi;
	fi';
# }}}

printf_rc() {
	local _colour="${1:-${DEFAULT_COLOUR_SUCCESS}}" _rc="${2}" _fmt="${3}"; shift 3;
	if [ "${_rc}" -eq 0 ]; then
		printf "[${_colour}m${_fmt}[0m" "${@}";
	else
		printf "[${DEFAULT_COLOUR_FAILURE}m${_fmt}[0m" "${@}";
	fi;
};

process_update_hosts() {
	local	_nflag="${1}" _domain="${2}" _hname="${3}" _uname="${4}"				\
		_failf=0 _log_data="" _msg="" _rc=0 _rc_fifo_fname="update_hosts.${_hname%%.}.fifo"	\
		_rc_fifo_fl=0 _rc_fifo_rc=0 _type="";

	msgf -- "36" "Updating host: "; msgf "1" "%s@%s\n" "${_uname}" "${_hname}";
	if [ -z "${_nflag}" ]; then
	if ! rm -f "${_rc_fifo_fname}"\
	|| ! mkfifo "${_rc_fifo_fname}"; then
		return 1;
	else
		trap "rm -f \"${_rc_fifo_fname}\" >/dev/null 2>&1" EXIT HUP INT TERM USR1 USR2;
		{ sleep 1; set +o errexit; exec 3>"${_rc_fifo_fname}";		\
		  ssh -l"${_uname}" -T "${_hname}" "${REMOTE_SCRIPT}" 2>/dev/null; echo "${?}" >&3; } | {
		exec 3<>"${_rc_fifo_fname}";
		while true; do
			if [ "${_rc_fifo_fl:-0}" -eq 0 ]; then
				_msg=""; read -r _msg <&3;
				if [ -n "${_msg}" ]; then
					_rc_fifo_fl=1; _rc_fifo_rc="${_msg}";
				fi;
			fi;
			if ! read -r _rc _type _msg; then
				break;
			else
				if [ "${_rc:-0}" -ne 0 ]; then
					_failfl=1;
				fi;
				case "${_type}" in
				autoremove)
						printf_rc "" "${_rc}" " %s" "${_type}"; ;;
				clean)
						printf_rc "" "${_rc}" " %s" "${_type}"; ;;
				dist-upgrade)
						printf_rc "${DEFAULT_COLOUR_DIST_UPGRADE}" "${_rc}" " %s(%s)" "${_type}" "${_msg}"; ;;
				dpkg-new)
						printf_rc "" "${_rc}" " %s(%s)" "${_type}" "${_msg}"; ;;
				rdepends)
						printf_rc "${DEFAULT_COLOUR_RDEPENDS}" "${_rc}" " %s(%s)" "${_type}" "${_msg}"; ;;
				services)
						printf_rc "${DEFAULT_COLOUR_SERVICES}" "${_rc}" " %s(%s)" "${_type}" "${_msg}"; ;;
				update)
						printf_rc "" "${_rc}" " %s" "${_type}"; ;;
				fini)		printf_rc "" "${_rc}" " %s" "[fetching log]";
						if [ "${_failfl:-0}" -eq 0 ]\
						&& [ "${_lflag:-0}" -eq 0 ]; then
							_log_fname="/dev/null";
						else
							touch "${_log_fname}";
						fi;
						while IFS= read -r _log_data; do
							printf "%s\n" "${_log_data}" >>"${_log_fname}";
						done; break; ;;
				*)		printf " [${DEFAULT_COLOUR_FAILURE}m?(rc=%s,type=%s,msg=%s)[0m" "${_rc}" "${_type}" "${_msg}"; break; ;;
				esac;
			fi;
		done;
		if [ "${_rc_fifo_rc}" -ne 0 ]; then
			printf " [${DEFAULT_COLOUR_FAILURE}m[ssh(1) exited w/ exit status %s.][0m\n" "${_rc_fifo_rc}";
		else
			printf ".\n";
		fi;};
		rm -f "${_rc_fifo_fname}"; trap - EXIT HUP INT TERM USR1 USR2;
	fi;
};

# vim:foldmethod=marker sw=8 ts=8 tw=120
