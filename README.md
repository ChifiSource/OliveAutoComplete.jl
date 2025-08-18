<div align="center">
<img src="https://github.com/ChifiSource/image_dump/raw/main/olive/0.1/extensions/oliveautocomplete.png" width="250"></img>
</div>

`OliveAutoComplete` provides `Olive` with fully-featured *autocomplete* functionality. This includes automatic indentation and code-suggestion autofill. Add the package within your `olive` environment or the environment you run `Olive` from:
```julia
using Pkg

Pkg.add("OliveAutoComplete")

# unstable; latest, sometimes broken, changes
Pkg.add("OliveAutoComplete", rev = "Unstable")
```

`OliveAutoComplete` is loaded like any other `Olive` extension, by loading the `Module` in your `olive.jl` file or **before** starting `Olive`.
```julia
using OliveAutoComplete; using Olive; Olive.start()
```
For more information on installing, check out [installing extensions](https://chifidocs.com/olive/Olive/installing-extensions).
