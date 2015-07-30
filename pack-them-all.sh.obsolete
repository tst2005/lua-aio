#!/bin/sh

# ----------------------------------------------------------------------------
#	-- Dragoon Framework - A Framework for Lua/LOVE --
#	-- Copyright (c) 2014-2015 TsT worldmaster.fr <tst2005@gmail.com> --
# ----------------------------------------------------------------------------

# $0 --mod <modname1 pathtofile1> --mod <modname2> <pathtofile2> -- <file> [files...]

# TODO: support -h|--help and help/usage text

pack_module_begin() {
cat<<EOD
do -- package block
	local package = require("package")
EOD
}

pack_module_end() {
cat<<EOD
end -- package block

-- main --
EOD
}

pack_module() {
	local modname="$1" ; shift
	local modpath="$1" ; shift
#	pack_module_begin
cat<<EOD
	do -- <pack $modname> --
		local _tmp_
		do -- protect package
			local package -- refuse to catch package upvalue

			function _tmp_(...)
EOD
cat -- "$modpath"
cat<<EOD
			end -- function _tmp_
		end
		package.preload["${modname}"] = _tmp_
	end -- </pack $modname> --
EOD
#	pack_module_end
}

min_pack_module_begin() { echo 'do local package=require"package"'; }
min_pack_module_end() { echo 'end'; }
min_pack_module() { echo 'do local _tmp_;do local package; function _tmp_(...)';cat -- "$2";echo 'end;end;package.preload["'"$1"'"]=_tmp_;end'; }


MODULE_BEGIN=0

while [ $# -gt 0 ]; do
	case "$1" in
		--code)
			if [ $MODULE_BEGIN -eq 1 ]; then
				min_pack_module_end
				MODULE_BEGIN=0
			fi
			shift ; cat -- "$1" ; shift ; continue
		;;
		--mod)
			if [ $MODULE_BEGIN -eq 0 ]; then
				min_pack_module_begin
				MODULE_BEGIN=1
			fi
			shift; min_pack_module "$1" "$2" ; shift; shift ; continue
		;;
		--) shift ; break ;;
		*) echo >&2 "error $1" ; exit 1
	esac
	shift
done

if [ $MODULE_BEGIN -eq 1 ]; then
	min_pack_module_end
	MODULE_BEGIN=0
fi

if [ $# -ge 1 ]; then
	cat -- "$@"
fi

