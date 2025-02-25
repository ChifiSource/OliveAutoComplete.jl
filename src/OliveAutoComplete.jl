module OliveAutoComplete
import Olive: on_code_build

# TODO This will be part of `Olive` auto-complete instead.
function on_code_build(c::Connection, cm::ComponentModifier, oe::OliveExtension{:indent}, 
    cell::Cell{:code}, proj::Project{<:Any}, component::Component{:div}, km::ToolipsSession.KeyMap)
    ToolipsSession.bind(c, cm, component, "Enter", on = :up) do cm::ComponentModifier
        callback_comp::Component = cm["cell$(cell.id)"]
        curr::String = callback_comp["text"]
        last_n::Int64 = parse(Int64, callback_comp["caret"])
        n::Int64 = length(curr)
        previous_line_i = findprev("\n", curr, last_n)
        @info previous_line_i
        if isnothing(previous_line_i)
            @info curr
            @warn last_n
            previous_line_i = 1
        else
            previous_line_i = minimum(previous_line_i) + 1
        end
        line_slice = curr[previous_line_i:last_n]
        contains_indent::Bool = ~isnothing(findfirst(x -> contains(line_slice, x), indent_after))
        # TODO get last line, check for indent key-words, pre-indentation, and `end`.
        #<br> is replaced, so `\n` is shorter by 2. Plus, JS index starts at 0
        if contains_indent
            cell.source = curr[1:last_n] * "\n&nbsp;&nbsp;&nbsp;&nbsp;" * curr[last_n + 1:length(curr)]
            set_text!(cm, "cell$(cell.id)", cell.source)
            focus!(cm, "cell$(cell.id)")
            Components.set_textdiv_cursor!(cm, "cell$(cell.id)", last_n + 4)
        end
    end
end


end # module OliveAutoComplete
