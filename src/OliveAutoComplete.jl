module OliveAutoComplete
import Olive: on_code_build, Cell, ComponentModifier, OliveExtension, Project
using Olive.Components
using Olive.Toolips
using Olive.Toolips.Components
using Olive.ToolipsSession

indent_after = ("begin", "function", "struct", "for", "if", "else", "elseif", "do", "macro")

# TODO This will be part of `Olive` auto-complete instead.
function on_code_build(c::Connection, cm::ComponentModifier, oe::OliveExtension{:indent}, 
    cell::Cell{:code}, proj::Project{<:Any}, component::Component{:div}, km::ToolipsSession.KeyMap)
    ToolipsSession.bind(c, cm, component, "Enter", on = :up) do cm::ComponentModifier
        callback_comp::Component = cm["cell$(cell.id)"]
        
        curr::String = callback_comp["text"]
        if curr[end] == '\n'
            if curr == "\n"
                return
            end
            curr = curr[1:end - 1]
        end
        last_n::Int64 = parse(Int64, callback_comp["caret"])
        n::Int64 = length(curr)
        if last_n < n 
            length(findall("\n", curr))
            last_n += length(findall("\n", curr))
        end
        @info "(debug messages)"
        if last_n <= n
            @warn replace(curr[1:last_n], " " => "-", "\n" => "|||") * "|CURSOR|" * replace(curr[last_n + 1:end], " " => "-", "\n" => "|||")

        else
            @warn "last_n > n :o"
            throw("last_n: $(last_n), `n`: $n")
        end
        previous_line_i = findprev("\n", curr, last_n)
        if isnothing(previous_line_i)
            @warn "no previous line"
            previous_line_i = 1
        else
            previous_line_i = minimum(previous_line_i)
        end
        @warn "previous line: \n" * replace(curr[begin:previous_line_i], "\n" => "|||")

        line_slice = curr[previous_line_i:last_n]
        contains_indent::Bool = ~isnothing(findfirst(x -> contains(line_slice, x), indent_after))
        contains_end = ~(isnothing(findfirst("end", line_slice)))
        indentation_level = findlast(c -> c == ' ', line_slice)
        if ~(isnothing(indentation_level))
            indentation_level = minimum(indentation_level) - 1
        end
        level_check = findfirst(c -> c != ' ', replace(line_slice, "\n" => ""))
        if isnothing(level_check)
            level_check = length(line_slice)
        else
            level_check = maximum(level_check)
        end
        @warn "current line: \n" * replace(line_slice, " " => "-")
        @info indentation_level
        indent_level = ~(isnothing(indentation_level)) && indentation_level > 3 && indentation_level <= level_check
        @info "continue indent?: " * string(indent_level)
        if ~(indent_level)
            msg = ""
            if isnothing(indentation_level)
                msg = "no indentation level $indentation_level $level_check"
            elseif ~(indentation_level[end] > 3)
                msg = "indentation level not > 3 $indentation_level"
            else
                msg = "failed level check: " * string(indentation_level) * " | " * string(level_check)
            end
            @warn "reason for no continued indent: " * msg
        end
        if contains_end && contains_indent
            return
        end
        if contains_end && indent_level
            indentation_level -= 4
        end
        # TODO get last line, check for indent key-words, pre-indentation, and `end`.
        #<br> is replaced, so `\n` is shorter by 2. Plus, JS index starts at 0
        if contains_indent
            addin = ""
            position = last_n + 4
            if indent_level
                addin = join("&nbsp;" for x in 1:indentation_level)
                position += indentation_level
            end
            res = curr[1:last_n] * "\n    " * addin * curr[last_n + 1:length(curr)]
            cell.source = res
            set_text!(cm, "cell$(cell.id)", replace(cell.source, " " => "&nbsp;"))
            @info "caret: " string(last_n) " len: " length(curr)
            @info string(last_n + 5 + indentation_level)
            cm["cell$(cell.id)"] = "caret" => position + 1
            focus!(cm, "cell$(cell.id)")
            @info "set cursor pos to $position"
            Components.set_textdiv_cursor!(cm, "cell$(cell.id)", position)
        elseif contains_end && indent_level
            indentation_level -= 4
            offset = 0
            if indentation_level > 3
                cell.source = curr[1:last_n] * join("&nbsp;" for x in 1:indentation_level) * curr[last_n + 1:length(curr)]
                offset = 5
            else
                cell.source = curr
            end
            set_text!(cm, "cell$(cell.id)", cell.source)
        elseif contains_end

        elseif indent_level
            @info "INDENTED"
            @info replace(join(" " for x in 1:indentation_level), " " => "-")
            res = curr[1:last_n] * "\n" * join(" " for x in 1:indentation_level) * curr[last_n + 1:end]
            cell.source = res
            @info replace(cell.source, " " => "&nbsp;")
            set_text!(cm, "cell$(cell.id)", replace(cell.source, " " => "&nbsp;"))
            cm["cell$(cell.id)"] = "caret" => string(last_n + indentation_level)
            focus!(cm, "cell$(cell.id)")
            Components.set_textdiv_cursor!(cm, "cell$(cell.id)", last_n + indentation_level - 1)
        end
    end
end


end # module OliveAutoComplete
