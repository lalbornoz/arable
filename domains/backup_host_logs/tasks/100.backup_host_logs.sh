#!/bin/sh
#



process_backup_host_logs_legend="BACKUP HOST LOGS";

process_backup_host_logs() {
	local	_nflag="${1}" _domain="${2}" _hname="${3}" _uname="${4}"	\
		_private_dname="domains/${2}/private/${4}@${3%.}" _shared_dname="domains/${2}/shared";
};

# vim:foldmethod=marker sw=8 ts=8 tw=120
