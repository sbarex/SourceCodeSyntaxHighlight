function dump(o)
    if type(o) == 'table' then
       local s = '{ \n'
       for k,v in pairs(o) do
          if type(k) ~= 'number' then k = '"'..k..'"' end
          s = s .. '['..k..'] = ' .. dump(v) .. ','
       end
       return s .. '} \n '
    else
       return tostring(o)
    end
end

function print_table(node)
    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. string.rep('\t',depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. string.rep('\t',depth-1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)
    output_str = table.concat(output)

    print(output_str)
end

function dbg_state(state)
    if state == 0 then
        return 'STANDARD'
    elseif state == 1 then
        return 'STRING'
    elseif state == 2 then
        return 'NUMBER'
    elseif state == 3 then
        return 'SL_COMMENT'
    elseif state == 4 then
        return 'ML_COMMENT'
    elseif state == 5 then
        return 'ESC_CHAR'
    elseif state == 6 then
        return 'DIRECTIVE'
    elseif state == 7 then
        return 'DIRECTIVE_STRING'
    elseif state == 8 then
        return 'LINENUMBER'
    elseif state == 9 then
        return 'SYMBOL'
    elseif state == 10 then
        return 'STRING_INTERPOLATION'
    elseif state == 11 then
        return 'KEYWORD'
    elseif state == 12 then
        return 'STRING_END'
    elseif state == 13 then
        return 'NUMBER_END'
    elseif state == 14 then
        return 'SL_COMMENT_END'
    elseif state == 15 then
        return 'ML_COMMENT_END'
    elseif state == 16 then
        return 'ESC_CHAR_END'
    elseif state == 17 then
        return 'DIRECTIVE_END'
    elseif state == 18 then
        return 'SYMBOL_END'
    elseif state == 19 then
        return 'STRING_INTERPOLATION_END'
    elseif state == 20 then
        return 'KEYWORD_END'
    elseif state == 21 then
        return 'IDENTIFIER_BEGIN'
    elseif state == 22 then
        return 'IDENTIFIER_END'
    elseif state == 23 then
        return 'EMBEDDED_CODE_BEGIN'
    elseif state == 24 then
        return 'EMBEDDED_CODE_END'
    else
        return state
    end
end
