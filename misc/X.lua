do local loadstring=loadstring;(function(name, rawcode)require"package".preload[name]=function(...)return assert(loadstring(rawcode))(...)end;end)("f1", ([[
-- <pack f1> --
return {\[=\[
F1 \[ \]
F1 \\] \\[
F1 \\[ \\]
F1 \ \\ \\\
\]=\]}
]]):gsub('\\([%]%[])','%1'))end
