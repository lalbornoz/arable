#!/bin/sh
#



process_backup_bint_legend="BACKUP TCL BINT";

process_backup_bint() {
	local	_nflag="${1}" _domain="${2}" _hname="${3}" _uname="${4}"	\
		_private_dname="domains/${2}/private/${4}@${3%.}" _shared_dname="domains/${2}/shared";
};

# vim:foldmethod=marker sw=8 ts=8 tw=120
