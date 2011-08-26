-- Generic XML writer for lunamark

local gsub = string.gsub
local util = require("lunamark.util")

local Xml = {}

Xml.options = { containers = false }

Xml.firstline = true
Xml.formats = {}

Xml.linebreak = "<linebreak />"

Xml.sep = { interblock = {compact = "\n", default = "\n\n", minimal = ""},
             container = { compact = "\n", default = "\n", minimal = ""}
          }

Xml.space = " "

Xml.interblocksep = Xml.sep.interblock.default

Xml.containersep = Xml.sep.container.default

local escaped = {
   ["<" ] = "&lt;",
   [">" ] = "&gt;",
   ["&" ] = "&amp;",
   ["\"" ] = "&quot;",
   ["'" ] = "&#39;"
}

function Xml.string(s)
  return s:gsub(".",escaped)
end

function Xml.start_document()
  Xml.firstline = true
  return ""
end

function Xml.stop_document()
  return ""
end

function Xml.plain(s)
  return s
end

local meta = {}
meta.__index =
  function(_, key)
    io.stderr:write(string.format("WARNING: Undefined writer function '%s'\n",key))
    return (function(...) return table.concat(arg," ") end)
  end
setmetatable(Xml, meta)

return Xml
