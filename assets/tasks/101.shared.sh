#!/bin/sh
#

process_shared_legend="SHARED DOTFILES";

process_shared() {
	local _uname="${1}" _hname="${2}" _tags="${3}" _nflag="${4}";
	msgf "[1mTransfer shared dotfiles[0m: [4m%s@%s[0m" "${_uname}" "${_hname}";
	rsync_push "${_nflag}" "${_uname}" "${_hname}"			\
		"assets/dotfiles_shared/" ""				\
		--include-from=assets/dotfiles_shared/.RSYNC_INCLUDE_FROM;
};

# vim:foldmethod=marker sw=8 ts=8 tw=120