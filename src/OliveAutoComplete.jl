"""
Created in August, 2025 by
[chifi - an open source software dynasty.](https://github.com/orgs/ChifiSource)
- This software is MIT-licensed.
### OliveAutoComplete
`OliveAutoComplete` provides `Olive` with *fully-featured* autocomplete functionality, including automatic indentation 
and suggestion autofill.
##### bindings
```julia
# olive extensions:
on_code_build(c::Connection, cm::ComponentModifier, oe::OliveExtension{:indent}, 
    cell::Cell{:code}, proj::Project{<:Any}, component::Component{:div}, km::ToolipsSession.KeyMap)
on_code_highlight(c::Connection, cm::ComponentModifier, ext::OliveExtension{:autocomplete}, cell::Cell{:code}, proj::Project{<:Any})
on_code_evaluate(c::Connection, cm::ComponentModifier, ext::OliveExtension{:suggestions}, cell::Cell{:code}, proj::Project{<:Any})

# internal:
load_suggestions!(proj::Project{<:Any}, mod::Module = proj[:mod])
```
"""
module OliveAutoComplete
import Olive: on_code_build, Cell, ComponentModifier, OliveExtension, Project, on_code_highlight, olive_notify!, on_code_evaluate, OliveBase
using Olive.Components
using Olive.Toolips
using Olive.Toolips.Components
using Olive.ToolipsSession

indent_after = ("begin", "function", "struct", "for", "if", "else", "elseif", "do", "macro", "quote", "try", "catch")

function on_code_build(c::Connection, cm::ComponentModifier, oe::OliveExtension{:indent}, 
    cell::Cell{:code}, proj::Project{<:Any}, component::Component{:div}, km::ToolipsSession.KeyMap)
    if ~(haskey(proj.data, :autocomp))
        proj.data[:autocomp] = String["function", "end", "begin", "do", "mutable", "struct", "abstract", "quote", "try", "for", "if", "else", "elseif", "macro"]
        proj.data[:autocompT] = String["Int64", "Float64", "String", "AbstractString", "Vector", "Array"]
        proj.data[:lastsrc] = ""
        @async begin
            add_names!(OliveBase, proj)
        end
    end
    suggest_box = div("autobox$(cell.id)", selection = "1")
    style!(component[:children][1], "margin" => 0px, "padding" => 0percent)
    style!(suggest_box, "background-color" => "white", "border" => "2px solid #3D3D3D", 
        "border-radius" => 3px, "margin-left" => 28pt, "width" => 85percent, "border-top" => 0px, "border-top-left-radius" => 0px, "border-top-right-radius" => 0px, 
        "min-height" => 16pt)
    insert!(component[:children], 2, suggest_box)
    ToolipsSession.bind(km, "ArrowLeft", :shift, prevent_default = true) do cm::ComponentModifier
        if ~("$(cell.id)acopt1" in cm)
            return
        end
        selection = parse(Int64, cm[suggest_box]["selection"])
        style!(cm, "$(cell.id)acopt$selection", "background-color" => "#82817f", "border" => "0px solid #ffffff")
        if selection < 2
            selection = 6
        else
            selection -= 1
        end
        if ~("$(cell.id)acopt$selection" in cm)
            selection = length(findall("$(cell.id)acopt", cm.rootc))
        end
        style!(cm, "$(cell.id)acopt$selection", "background-color" => "#2e2a28", "border" => "2px solid #40a35f")
        cm[suggest_box] = "selection" => string(selection)
    end
    ToolipsSession.bind(km, "ArrowRight", :shift, prevent_default = true) do cm::ComponentModifier
        if ~("$(cell.id)acopt1" in cm)
            return
        end
        selection = parse(Int64, cm[suggest_box]["selection"])
        style!(cm, "$(cell.id)acopt$selection", "background-color" => "#82817f", "border" => "0px solid #ffffff")
        if selection == 6
            selection = 1
        else
            selection += 1
        end
        if ~("$(cell.id)acopt$selection" in cm)
            selection = 1
        end
        style!(cm, "$(cell.id)acopt$selection", "background-color" => "#2e2a28", "border" => "2px solid #40a35f")
        cm[suggest_box] = "selection" => string(selection)
    end
    ToolipsSession.bind(km, " ", :shift, prevent_default = true) do cm::ComponentModifier
        selection = cm[suggest_box]["selection"]
        callback_comp::Component = cm["cell$(cell.id)"]
        curr::String = callback_comp["text"]
        last_n::Int = parse(Int, callback_comp["caret"])
        selcompn = "$(cell.id)acopt$selection"
        n = length(curr)
        if  ~(selcompn in cm) || n < 1
            return
        end
        txt = cm[selcompn]["text"]
        # got all data, now we set the new str:
        seps = (',', ' ', ':', ';', '\n', '(', '[')
        lastsep = findprev(c -> c in seps, curr, last_n)
        nextsep = findnext(c -> c in seps, curr, last_n)
        if isnothing(nextsep)
            nextsep = n
        end
        curr = if isnothing(lastsep)
            if last_n == n
                curr = txt
            else
                curr = txt * curr[nextsep:end]
            end
            lastsep = 1
            curr
        elseif last_n == n
            curr[1:lastsep] * txt
        else
            curr[1:lastsep] * txt * curr[nextsep:end]
        end
        if lastsep != 1
            lastsep += 1
        end
        if nextsep != n
            nextsep -= 1
        end
        slicelen = nextsep - lastsep
        newpos = last_n + length(txt) - slicelen
        set_text!(cm, "cell$(cell.id)", replace(curr, " " => "&nbsp;", "\n" => "<br>"))
        cm["cell$(cell.id)"] = "caret" => string(newpos)
        Components.set_textdiv_cursor!(cm, "cell$(cell.id)", newpos + 1)
    end
    if ~(contains(cell.source, "\n") || contains(cell.source, "<br>"))
        interior = component[:children]["cellinterior$(cell.id)"]
        inp = interior[:children]["cellinput$(cell.id)"]
        maincell::Component{:div} = inp[:children]["cell$(cell.id)"]
        maincell[:text] = maincell[:text] * "<br>"
    end
    ToolipsSession.bind(km, "Enter", prevent_default = false) do cm::ComponentModifier
        callback_comp::Component = cm["cell$(cell.id)"]
        curr::String = callback_comp["text"]
        last_n::Int = parse(Int, callback_comp["caret"])
        n::Int = length(curr)
        if n in (0, 2, 1) || last_n < 3
            return
        end
        # safety
        if last_n > n
            return
        end
        before = curr[1:clamp(last_n, 1, n)]
        after  = last_n <= n ? curr[last_n+1:end] : ""
        lines = split(curr, '\n')
        prev_line = isempty(lines) || length(lines) < 2 ? "" : lines[end - 1]
        indent_spaces = length(match(r"^ *", prev_line).match)
        current_line_idx = count(==('\n'), curr[1:clamp(last_n, 1, n)]) + 1
        current_line = lines[current_line_idx]

        contains_indent = any(contains(prev_line, x) for x in indent_after)
        indent_spaces = length(match(r"^ *", prev_line).match)
        cur_indent_spaces = length(match(r"^ *", current_line).match)
        current_line_has_end = begin 
            occursin(r"\bend\b", current_line) || occursin(r"\belseif\b", current_line) || occursin(r"\belse\b", current_line) || occursin(r"\belseif\b", current_line) || occursin(r"\belse\b", current_line) || occursin(r"\bcatch\b", current_line)
        end
        
        new_indent::Int64 = indent_spaces
        if contains_indent && ~(current_line_has_end)
            new_indent += 4
        end
        # rule 2: if current line contains "end" and is at same indent as prev
        newpos = nothing
        if current_line_has_end
            if prev_line == current_line && length(lines) > 3
                prev_line = lines[end - 2]
            end
            prev_indent_spaces = length(match(r"^ *", prev_line).match)
            if cur_indent_spaces == prev_indent_spaces && cur_indent_spaces > 3
                # Dedent "end" by stripping up to 4 spaces
                stripped_line = replace(current_line, r"^ {0,4}" => "")
                lines[current_line_idx] = stripped_line
                curr = replace(join(lines, "<br>"), " " => "&nbsp;")
                set_text!(cm, "cell$(cell.id)", curr)
                newpos = last_n - 4
                cm["cell$(cell.id)"] = "caret" => string(newpos)
                Components.set_textdiv_cursor!(cm, "cell$(cell.id)", newpos + 1)
                return
            end
        end
        newline_indent = "<br>" * " "^new_indent
        res = before * newline_indent * after
        res_safe = replace(res, " " => "&nbsp;", "\n" => "<br>")
        newpos = last_n + 1 + new_indent
        # update component
        set_text!(cm, "cell$(cell.id)", res_safe)
        cm["cell$(cell.id)"] = "caret" => string(newpos)
        Components.set_textdiv_cursor!(cm, "cell$(cell.id)", newpos + 1)
        # for suggest box:
        set_text!(cm, "autobox$(cell.id)", "")
    end
end


function on_code_highlight(c::Connection, cm::ComponentModifier, ext::OliveExtension{:autocomplete}, cell::Cell{:code}, proj::Project{<:Any})
    callback_comp::Component = cm["cell$(cell.id)"]
    curr::String = callback_comp["text"]
    proj.data[:lastsrc]
    last_n::Int = parse(Int, callback_comp["caret"])
    n::Int = length(curr)
    if n < 2
        return
    end
    seps = (',', ' ', ':', ';', '\n', '(', '[')
    lastsep = findprev(c -> c in seps, curr, last_n)
    if lastsep == last_n
        return
    end
    if isnothing(lastsep)
        lastsep = 1
    else
        lastsep = minimum(lastsep)
        lastsep += 1
    end
    curr_str = curr[lastsep:last_n]
    if proj.data[:lastsrc] == curr_str
        return
    end
    proj.data[:lastsrc] = curr_str
    curr_n = length(curr_str)
    autocomp = proj.data[:autocomp]
    autocomp_t = proj.data[:autocompT]
    found_comp = findall(x -> length(x) > curr_n && x[1:curr_n] == curr_str, autocomp)
    found_t = findall(x -> length(x) > curr_n && x[1:curr_n] == curr_str, autocomp_t)
    results = String[]
    if length(found_comp) > 0
        push!(results, [autocomp[e] for e in found_comp] ...)
    end
    if length(found_t) > 0
        push!(results, [autocomp_t[e] for e in found_t] ...)
    end
    n = length(results)
    if n == 0
        set_text!(cm, "autobox$(cell.id)", "")
        return
    end
    max_num = 6
    if n < max_num
        max_num = n
    end
    selected_comp = parse(Int64, cm["autobox$(cell.id)"]["selection"])
    if selected_comp > max_num
        selected_comp = 1
        cm["autobox$(cell.id)"] = "selection" => "1"
    end
    comps = [begin
        comp = a("$(cell.id)acopt$e", text = results[rand(1:n)])
        style!(comp, "color" => "#cdd2d4", "padding" => 5px, "font-size" => 15pt, "border-radius" => 2px)
        if e == selected_comp
            style!(comp, "background-color" => "#2e2a28", "border" => "2px solid #40a35f")
        else
            style!(comp, "background-color" => "#82817f")
        end
        comp::Component{:a}
    end for e in 1:max_num]
    set_children!(cm, "autobox$(cell.id)", comps)
end

function on_code_evaluate(c::Connection, cm::ComponentModifier, ext::OliveExtension{:suggestions}, cell::Cell{:code}, proj::Project{<:Any})
    special_words = ("using", "import")
    src::String = cell.source
    found = findfirst(x -> contains(src, x), special_words)
    if isnothing(found)
        return
    end
    kwpos = findall(special_words[found], src)
    mod = proj[:mod]
    @async begin
        # begin async
    for position in kwpos
        namestart = findnext(" ", src, minimum(position))
        if isnothing(namestart)
            continue
        else
            namestart = minimum(namestart) + 1
        end
        nameend = findnext(" ", src, namestart)
        if isnothing(nameend)
            nameend = length(src)
        else
            nameend = minimum(nameend) - 1
        end
        src = replace(src[namestart:nameend], "\n" => "", " " => "")
        name = Symbol(src)
        if isdefined(mod, name)
            thismod = getfield(mod, name)
            if ~(thismod isa Module)
                continue
            end
            load_suggestions!(proj, thismod)
        end
    end
    end # - async
end

function load_suggestions!(proj::Project{<:Any}, mod::Module = proj[:mod])
    try
    add_names!(mod, proj)
    catch e
        throw(e)
    end
end


function add_names!(mod::Module, proj::Project{<:Any})
    autocomp::Vector{String}, autocomp_t::Vector{String} = (proj[:autocomp], proj[:autocompT])
    for name in names(mod, all = true, imported = true)
        if ~(isdefined(mod, name)) || contains(string(name), "#")
            continue
        end
        T = getfield(mod, name)
        name = string(name)
        if (name in autocomp || name in autocomp_t)
            continue
        end
        if T isa Type
            push!(autocomp_t,  name)
        elseif T isa Module 
            push!(autocomp, name)
        else
            push!(autocomp, name)
        end
    end
end

end # module OliveAutoComplete
