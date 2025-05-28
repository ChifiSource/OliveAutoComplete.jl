module OliveAutoComplete
import Olive: on_code_build, Cell, ComponentModifier, OliveExtension, Project
using Olive.Components
using Olive.Toolips
using Olive.Toolips.Components
using Olive.ToolipsSession

indent_after = ("begin", "function", "struct")

# TODO This will be part of `Olive` auto-complete instead.
function on_code_build(c::Connection, cm::ComponentModifier, oe::OliveExtension{:indent}, 
    cell::Cell{:code}, proj::Project{<:Any}, component::Component{:div}, km::ToolipsSession.KeyMap)
    ToolipsSession.bind(c, cm, component, "Enter", on = :up) do cm::ComponentModifier
        callback_comp::Component = cm["cell$(cell.id)"]
        
        curr::String = callback_comp["text"]
        last_n::Int64 = parse(Int64, callback_comp["caret"])
        n::Int64 = length(curr)
        previous_line_i = findprev("\n", curr, last_n)
        if isnothing(previous_line_i)
            @warn "no previous"
            previous_line_i = 1
        else
            previous_line_i = minimum(previous_line_i) + 1
        end
        @warn "previous line: \n" * replace(curr[begin:previous_line_i], "\n" => "|||")

        line_slice = curr[previous_line_i:last_n]
        contains_indent::Bool = ~isnothing(findfirst(x -> contains(line_slice, x), indent_after))
        contains_end = ~(isnothing(findfirst("end", line_slice)))
        indentation_level = findlast(c -> c == ' ', line_slice)
        @warn "current line: \n" * replace(line_slice, " " => "-")
        @info indentation_level
        indent_level = ~(isnothing(indentation_level)) && indentation_level[end] > 3
        if contains_end && contains_indent
            return
        end
        if contains_end && indent_level
            indentation_level -= 4
        end
        # TODO get last line, check for indent key-words, pre-indentation, and `end`.
        #<br> is replaced, so `\n` is shorter by 2. Plus, JS index starts at 0
        if contains_indent
            cell.source = curr[1:last_n] * "\n&nbsp;&nbsp;&nbsp;&nbsp;" * join("&nbsp;" for x in indentation_level) * curr[last_n + 1:length(curr)]
            set_text!(cm, "cell$(cell.id)", cell.source)
            @info "caret: " string(last_n) " len: " length(curr)
            cm["cell$(cell.id)"] = "caret" => string(last_n + 5)
            focus!(cm, "cell$(cell.id)")
            Components.set_textdiv_cursor!(cm, "cell$(cell.id)", last_n + 5)
        elseif contains_end && indent_level
            
        elseif contains_end

        elseif indent_level
            @info "INDENTED"
            cell.source = curr[1:last_n] * "\n" * join("&nbsp;" for x in indentation_level) * curr[last_n + 1:end]
            set_text!(cm, "cell$(cell.id)", cell.source)
            cm["cell$(cell.id)"] = "caret" => string(last_n + indentation_level)
            focus!(cm, "cell$(cell.id)")
            Components.set_textdiv_cursor!(cm, "cell$(cell.id)", last_n + indentation_level - 1)
        end
    end
end


end # module OliveAutoComplete
