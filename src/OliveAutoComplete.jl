module OliveAutoComplete
import Olive: on_code_build, Cell, ComponentModifier, OliveExtension, Project
using Olive.Components
using Olive.Toolips
using Olive.Toolips.Components
using Olive.ToolipsSession

indent_after = ("begin", "function", "struct", "for", "if", "else", "elseif", "do", "macro")

function on_code_build(c::Connection, cm::ComponentModifier, oe::OliveExtension{:indent}, 
    cell::Cell{:code}, proj::Project{<:Any}, component::Component{:div}, km::ToolipsSession.KeyMap)
    suggest_box = div("autobox")
    style!(component[:children][1], "margin" => 0px, "padding" => 0percent)
    style!(suggest_box, "background-color" => "white", "border" => "2px solid #3D3D3D", 
        "border-radius" => 3px, "margin-left" => 28pt, "width" => 85percent, "border-top" => 0px, "border-top-left-radius" => 0px, "border-top-right-radius" => 0px, 
        "min-height" => 16pt)
    insert!(component[:children], 2, suggest_box)
    ToolipsSession.bind(km, " ", :shift, prevent_default = true) do cm::ComponentModifier
        alert!(cm, "will fill currently selected complete")
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
        if n == 0
            return
        elseif n < 2
            return
        end
        # safety
        if last_n > n + 1
            last_n -= 1
            if last_n > n + 1
                @warn "caret beyond length"
            end
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
        current_line_has_end = occursin(r"\bend\b", current_line)

        new_indent::Int64 = indent_spaces
        if contains_indent && ~(current_line_has_end)
            new_indent += 4
        end
        # rule 2: if current line contains "end" and is at same indent as prev
        newpos = nothing
        if occursin(r"\bend\b", current_line)      
            prev_indent_spaces = length(match(r"^ *", prev_line).match)
            if cur_indent_spaces == indent_spaces && cur_indent_spaces > 3
                @warn current_line
                @warn prev_line
                # Dedent "end" by stripping up to 4 spaces
                stripped_line = replace(current_line, r"^ {0,4}" => "")
                lines[current_line_idx] = stripped_line
                new_indent -= 4
            end
        end
        newline_indent = "<br>" * " "^new_indent
        res = before * newline_indent * after
        res_safe = replace(res, " " => "&nbsp;", "\n" => "<br>")
        newpos = last_n + 1 + new_indent
        # update component
        @info res_safe
        set_text!(cm, "cell$(cell.id)", res_safe)
        cm["cell$(cell.id)"] = "caret" => string(newpos)
        Components.set_textdiv_cursor!(cm, "cell$(cell.id)", newpos + 1)
    end
end

    

end # module OliveAutoComplete
