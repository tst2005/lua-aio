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

Now I use it to :
 * test on big projet like : hate with the hate-allinone.lua result.
 * bundle third party module like : lunajson, ...
 * bundle [featured.lua](https://github.com/tst2005/mom/blob/master/featured.lua) of the [mom project](https://github.com/tst2005/mom)

# How it run

## Command line support

This util catch each module files and push their contents inside the preload table.
By this way we can use `require("modulename")` like usual. 

# Documentation

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


## v-next
 * recode the whole .lua to be a lua module
 * (?) use and embed a getopt or argparse module to manage --options

