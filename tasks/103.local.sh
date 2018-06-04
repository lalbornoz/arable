#!/bin/sh
#

process_local_legend="[35;4m--- LOCAL DOTFILES               ---[0m";

process_local() {
	local _uname="${1}" _hname="${2}" _tags="${3}" _src="";
	if [ -e "../dotfiles_private/${_uname}@${_hname}" ]; then
		printf "[1mTransfer user- and host-local dotfiles[0m: [4m${_uname}@${_hname}[0m\n";
		_src="$(find "../dotfiles_private/${_uname}@${_hname}"	\
			-maxdepth 1 -mindepth 1				\
			-name '.*' -not -name '.*.sw[op]'		\
			-printf '%p ')"
		rsync_push "${_uname}" "${_hname}" "${_src}";
	fi;
};

# vim:foldmethod=marker sw=8 ts=8 tw=120