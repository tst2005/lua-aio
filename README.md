# Lua All In One

Embeding lot of lua modules/files into only one lua file.

Note: it's an Beta version.

# Why using this util ?

I initialy create this util for 2 projects :
 * for Alephone Game
  because the Lua Script support only support ONE Lua file to load.
  Having one big file is too ugly for me, I prefere split all part to lua modules and generate the big one at the end.
 * In fakelove
 A implementation of LÖVE in pur lua (without graphical stuff) usefull for server side code game.

# More usefull than expected

Now I use it for :
 * [hate](https://github.com/tst2005/hate/tree/allinone) : a clone of love2d but with LuaJIT
 * [lunajson](https://github.com/tst2005/lunajson) : a json module
 * [makefly](https://github.com/tst2005/makefly) : a command line utility to make html static page
 * my [mom.lua](https://github.com/tst2005/mom) project


# How it run

## Command line support

Note: this way become obsolete?

You should the `aio-cli` and use command line options.
Sample of self made aio-cli all-in-one :
```
./aio-cli \
--shebang aio-cli \
--rawmod "aio" aio.lua \
--code aio-cli \
> aio-cli.tmp
```

Note: I move to lua use, more than shell use.

## In lua

This util catch each module files and push their contents inside the preload table.
By this way we can use `require("aio")` like any other lua module.

```
local aio = require "aio"
aio.shebang("aio-cli")
aio.rawmod("aio", "aio.lua")
aio.code("aio-cli")
```

# hybrid mode

Call the lua interpretor in shell and evaluate a big option :
```
lua -l aio -e '
local aio = require "aio"
aio.shebang("aio-cli")
aio.rawmod("aio", "aio.lua")
aio.code("aio-cli")
' > aio-cli.tmp
```


# Documentation

Note: this doc is a little obsolete ...

```
$ ./pack-them-all.lua <arguments...>
```

```
Options and arguments :
  --shebang               <path/to/file.lua>
  --code                  <path/to/file.lua>
  --codehead <n>          <path/to/file.lua>
  --mod      <modulename> <path/to/modulefile.lua>
  --rawmod   <modulename> <path/to/modulefile.lua>
  --luamod   <modulename> <path/to/modulefile.lua>
  ---mode    'lua'|'raw'
  --autoaliases
  --icheckinit
  --icheck
  --require  <modulename>
  --file <path/to/file>
  -- [<file1> [<file2> [...]]]
```

# Sample of use

See files inside the sample directory

# Special feature

## autoaliases feature

In usual case a module named `abc` defined in an `abc/init.lua` file should be called with an `abc` name : `require("abc")`
because the usual loader use package.path to search `?.lua` or `?/init.lua`.

The preload system does not use path.

The --autoaliases make aliases for all registred modules named with the `.init` suffix to be called without the suffix.
Must be used at the end (when module will be already registred in preload table).

## Integrity Check

This feature was introduce for my-self to be able to control how many module have been packed and how many we get at runtime.

# TODO

 * improve the shebang detection : raise a warning if the shebang seems not a shebang but a simple shell comment.
   See: http://www.lua.org/source/5.2/lauxlib.c.html#skipBOM http://www.lua.org/source/5.2/lauxlib.c.html#skipcomment
 * add the line number info in the first comment (usefull for debug?)
 * create the sample directory :D
 * implement the .sh version like the new .lua one (or drop the .sh version)
 * document the --autoaliases behavior
 * (?) allow to use --autoaliases anywhere (the code will be added at the end)
```
do ..... function(...)-- <pack something.init> 9233 --
```
 * (?) use and embed a getopt or argparse or cliargs module to manage --options

