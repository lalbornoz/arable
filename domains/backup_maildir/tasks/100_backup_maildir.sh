#!/bin/sh
#



process_backup_maildir_legend="BACKUP MAILDIR";

process_backup_maildir() {
	local	_nflag="${1}" _domain="${2}" _hname="${3}" _uname="${4}"	\
		_private_dname="domains/${2}/private/${4}@${3%.}" _shared_dname="domains/${2}/shared";
};

# vim:foldmethod=marker sw=8 ts=8 tw=120
