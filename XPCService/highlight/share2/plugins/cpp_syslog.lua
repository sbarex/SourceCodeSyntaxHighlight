--[[

Sample plugin file for highlight 3.1

Adds additional keywords to C++ syntax description and corresponding
formatting in colour theme

USAGE: highlight -I main.cpp --plug-in=plugin.lua
]]

Description="Add syslog and kernel log levels to C and C++ keywords"

Categories = {"c++", "syslog" }

-- function to update language definition with syslog levels
-- optional parameter: syntax description
function syntaxUpdate(desc)
  if desc=="C and C++" then
    -- insert syslog level for C and C++
    table.insert( Keywords,
                  { Id=5, List={"LOG_EMERG", "LOG_CRIT", "LOG_ALERT",
                    "LOG_ERR", "LOG_WARNING","LOG_NOTICE","LOG_INFO",
                    "LOG_DEBUG",
                    "KERN_ERR", "KERN_INFO", "KERN_EMERG", "KERN_ALERT",
                    "KERN_CRIT",  "KERN_WARNING",  "KERN_NOTICE",
                    "KERN_DEBUG", "KERN_DEFAULT",  "KERN_CONT" }
                  } )
  end
end

-- function to update theme definition
-- optional parameter: theme description
function themeUpdate(desc)
  --add 5th keyword style for syslog levels defined in  syntaxUpdate()
  if #Keywords==4 then
    table.insert(Keywords, {Colour= "#ff0000", Bold=true})
  end
end


--The Plugins array assigns code chunks to themes or language definitions.
--The chunks are interpreted after the theme or lang file were parsed,
--so you can refer to elements of these files

Plugins={

  { Type="theme", Chunk=themeUpdate },
  { Type="lang", Chunk=syntaxUpdate },

}
