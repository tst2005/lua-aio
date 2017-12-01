# My bundle format

## How to get bundle info without loading it ?

For a module `foo` I provide a module `foo.__bundle`.

## meta module format

A lua table with mandatory fields:
* `_BUNDLE`: (boolean value) `true`
* `_BUNDLE_FORMAT`: (string) currently only `v0.1.0.alpha1` is available
* `_BUNDLEFOR`: (string) the name of the embedded module

### meta module format sample

The `*.__bundle` format:
```lua
return {
	_BUNDLE=true,
	_BUNDLE_FORMAT="v0.1.0.alpha1",
	_BUNDLEFOR="foo"
}
```

## How to check if a module is a bundle

```lua
local function is_a_bundle(name)
	local ok, res = pcall(require, name..".__bundle")
	return (ok and res._BUNDLE == true)
end

print( is_a_bundle("foo") )
```


## selfcheck

```lua
local function selfcheck(name, bundle_version)
	if not bundle_version then bundle_version="v0.1.0.alpha1" end

	local ok, res = pcall(require, name..".__bundle")
	return (ok and res._BUNDLE == true and res._BUNDLE_FORMAT==bundle_version and res._BUNDLEFOR==name)
end
assert(selfcheck("foo", "v0.1.0.alpha1"))
```
