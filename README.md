# luamodules-all-in-one-file

Embeding all lua modules/files of a project into only one lua file

# Why using this util ?

I only use this util for Alephone Game because the Lua Script support only support ONE Lua file to load.
Having one big file is too ugly for me, I prefere split all part to lua modules and generate the big one at the end.

This util catch each the module file content and push it inside the preload table.
By this way we can use `require("modulename")` like usual. 

# Documentation

```
$ ./pack-them-all.lua <arguments...>
or
$ ./pack-them-all.sh <arguments...>
```

```
arguments :
  --mod <modulename> <path/to/modulefile.lua>
  --code <path/to/code1.lua>
  -- [<file1> [<file2> [...]]]
```

TODO: check if the syntax is still exact...

# Sample of use

See files inside the sample directory

TODO: create the sample directory :D
