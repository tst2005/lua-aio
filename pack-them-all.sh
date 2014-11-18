#!/bin/sh

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


MODULE_BEGIN=0

while true; do
	case "$1" in
		--code)
			if [ $MODULE_BEGIN -eq 1 ]; then
				pack_module_end
				MODULE_BEGIN=0
			fi
			shift ; cat -- "$1" ; shift ; continue
		;;
		--mod)
			if [ $MODULE_BEGIN -eq 0 ]; then
				pack_module_begin
				MODULE_BEGIN=1
			fi
			shift; pack_module "$1" "$2" ; shift; shift ; continue
		;;
		--) shift ; break ;;
		*) echo "error $1" ; exit 1
	esac
	shift
done

if [ $MODULE_BEGIN -eq 1 ]; then
	pack_module_end
	MODULE_BEGIN=0
fi

if [ $# -ge 1 ]; then
	cat -- "$@"
fi

