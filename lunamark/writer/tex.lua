-- (c) 2009-2011 John MacFarlane. Released under MIT license.
-- See the file LICENSE in the source for details.

--- Generic TeX writer for lunamark.
-- Extends [lunamark.writer.generic].

local M = {}

local util = require("lunamark.util")
local generic = require("lunamark.writer.generic")
local entities = require("lunamark.entities")
local md5 = require("md5")
local format = string.format

--- Returns a new TeX writer.
-- For a list of fields, see [lunamark.writer.generic]. `options` is a table
-- that must contain the following fields:
--
-- `cacheDir`
-- :   The directory in which temporary files are stored.
--
-- and that may contain the following fields:
--
-- `hybrid`
-- :   Prevents the escaping of special TeX characters. This makes it possible
--     to intersperse the Markdown markup with TeX code.
--
-- `verbatim`
-- :   Code blocks will not be surrounded by \markdownCodeBlockBegin and
--     \markdownCodeBlockEnd and have the special TeX characters escaped in
--     their contents. Instead, their contents will be stored in a temporary
--     file inside `cachedir`. The pathname of this file will be passed to the
--     \markdownInputVerbatim macro.
function M.new(options)
  local options = options or {}
  local TeX = generic.new(options)

  TeX.interblocksep = "\n\n"  -- insensitive to layout

  TeX.containersep = "\n"

  TeX.linebreak = "\\\\"

  TeX.ellipsis = "\\markdownEllipsis "

  TeX.escaped = {
     ["{"] = "\\{",
     ["}"] = "\\}",
     ["$"] = "\\$",
     ["%"] = "\\%",
     ["&"] = "\\&",
     ["_"] = "\\_",
     ["#"] = "\\#",
     ["^"] = "\\^{}",
     ["\\"] = "\\char92{}",
     ["~"] = "\\char126{}",
     ["|"] = "\\char124{}",
     ["["] = "{[}", -- to avoid interpretation as optional argument
     ["]"] = "{]}",
   }
  
  local escape = util.escaper(TeX.escaped)
  if options.hybrid then
    TeX.string = function(s) return s end
  else
    TeX.string = escape
  end

  function TeX.paragraph(s)
    return s
  end

  function TeX.code(s)
    return {"\\markdownCodeSpan{",escape(s),"}"}
  end

  function TeX.link(lab,src,tit)
    return {"\\markdownLink{",TeX.string(lab[1]),"}",
                          "{",TeX.string(src),"}",
                          "{",TeX.string(tit),"}"}
  end

  function TeX.image(lab,src,tit)
    return {"\\markdownImage{",TeX.string(lab[1]),"}",
                           "{",TeX.string(src),"}",
                           "{",TeX.string(tit),"}"}
  end

  local function ulitem(s)
    return {"\\markdownUlItem ",s}
  end

  function TeX.bulletlist(items,tight)
    local buffer = {}
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = ulitem(item)
    end
    local contents = util.intersperse(buffer,"\n")
    if tight then
      return {"\\markdownUlBeginTight\n",contents,"\n\\markdownUlEndTight "}
    else
      return {"\\markdownUlBegin\n",contents,"\n\\markdownUlEnd "}
    end
  end

  local function olitem(s,num)
    if num ~= nil then
      return {"\\markdownOlItemWithNumber{",num,"} ",s}
    else
      return {"\\markdownOlItem ",s}
    end
  end

  function TeX.orderedlist(items,tight,startnum)
    local buffer = {}
    local num = startnum
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = olitem(item,num)
      if num ~= nil then
        num = num + 1
      end
    end
    local contents = util.intersperse(buffer,"\n")
    if tight then
      return {"\\markdownOlBeginTight\n",contents,"\n\\markdownOlEndTight "}
    else
      return {"\\markdownOlBegin\n",contents,"\n\\markdownOlEnd "}
    end
  end

  local function dlitem(term,defs)
      return {"\\markdownDlItem{",term,"}\n",defs}
  end

  function TeX.definitionlist(items,tight)
    local buffer = {}
    for _,item in ipairs(items) do
      buffer[#buffer + 1] = dlitem(item.term,
        util.intersperse(item.definitions, TeX.interblocksep))
    end
    local contents = util.intersperse(buffer, TeX.containersep)
    if tight then
      return {"\\markdownDlBeginTight\n",contents,"\n\\markdownDlEndTight "}
    else
      return {"\\markdownDlBegin\n",contents,"\n\\markdownDlEnd "}
    end
  end

  function TeX.emphasis(s)
    return {"\\markdownEmphasis{",s,"}"}
  end

  function TeX.strong(s)
    return {"\\markdownStrongEmphasis{",s,"}"}
  end

  function TeX.blockquote(s)
    return {"\\markdownBlockQuoteBegin\n",s,"\n\\markdownBlockQuoteEnd "}
  end

  local function pathname(file)
    if #options.cacheDir == 0 then
      return file
    else
      return options.cacheDir .. "/" .. file
    end
  end

  function TeX.verbatim(s)
    if options.verbatim then
      local name = pathname(md5.sumhexa(s) .. ".verbatim")
      local file = io.open(name, "r")
      if file == nil then -- If no cache entry exists, then create a new one.
        -- TODO: Cache autocleaning.
        local file = assert(io.open(name, "w"))
        assert(file:write(s))
        assert(file:close())
      end
      return {"\\markdownInputVerbatim{",name,"}"}
    else
      return {"\\markdownCodeBlockBegin\n",escape(s),"\\markdownCodeBlockEnd "}
    end
  end

  function TeX.header(s,level)
    local cmd
    if level == 1 then
      cmd = "\\markdownHeaderOne"
    elseif level == 2 then
      cmd = "\\markdownHeaderTwo"
    elseif level == 3 then
      cmd = "\\markdownHeaderThree"
    elseif level == 4 then
      cmd = "\\markdownHeaderFour"
    elseif level == 5 then
      cmd = "\\markdownHeaderFive"
    elseif level == 6 then
      cmd = "\\markdownHeaderSix"
    else
      cmd = ""
    end
    return {cmd,"{",s,"}"}
  end

  TeX.hrule = "\\markdownHorizontalRule "

  function TeX.note(contents)
    return {"\\markdownFootnote{",contents,"}"}
  end

  return TeX
end

return M
