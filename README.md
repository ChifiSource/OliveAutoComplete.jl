<div align="center">
<img src="https://github.com/ChifiSource/image_dump/raw/main/olive/0.1/extensions/oliveautocomplete.png" width="250"></img>
</div>

- **note**: this first iteration of `OliveAutoComplete` is most likely *not* unicode-safe.
- [documentation](https://chifidocs.com/olive/OliveAutoComplete)
- [olive](https://github.com/ChifiSource/Olive.jl)

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
### using autocomplete
Once autocomplete is loaded, each `:code` cell should have a box at the bottom. As you type, the box fills with suggestions from your loaded packages and `OliveBase`. Use `shift` + `ArrowRight` & `shift` + `ArrowLeft` to navigate these suggestions, and use `shift` + `Space` to fill with the currently selected suggestion.
##### future editions
Future editions will include fixes for bugs with the current functionality, as well as
- type-specific suggest (after `::`)
- `Olive` class usage for all components (`0.3` +)
- Indentation after `elseif`, `else`, `catch`
- Keybindings moved to keybind settings
- autocomplete settings, with the ability to turn each autocomplete functionality off or on.
