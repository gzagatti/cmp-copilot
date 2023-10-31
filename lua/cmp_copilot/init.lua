local source = {}

source.new = function()
  return setmetatable({
    timer = vim.loop.new_timer()
  }, { __index = source })
end

source.get_keyword_pattern = function()
  return '.'
end

source.is_available = function()
  return vim.g.loaded_copilot == 1 and vim.b.copi_enabled ~= false
end

source.deindent = function(_, text)
  local indent = string.match(text, '^%s*')
  if not indent then
    return text
  end
  return string.gsub(string.gsub(text, '^' .. indent, ''), '\n' .. indent, '\n')
end

source.label = function(_, text)
  local shorten = function (str)
    local short_prefix = string.sub(str, 0, 20)
    local short_suffix = string.sub(str, string.len(str)-15, string.len(str))
    local delimiter = " ... "
    return short_prefix .. delimiter .. short_suffix
  end
  text = source:deindent(text)
  text = text:gsub("^%s*", "")
  return string.len(text) > 40 and shorten(text) or text
end

source.complete = function(self, params, callback)
  vim.fn['copilot#Complete'](function(result)
    callback({
      isIncomplete = true,
      items = vim.tbl_map(function(item)
        return {
          label = source:label(item.text),
          cmp = {
            kind_hl_group = "CmpItemKindCopilot",
            kind_text = "Copilot",
          },
          textEdit = {
            range = item.range,
            newText = item.text,
          },
          documentation = {
            kind = 'markdown',
            value = table.concat({
              '```' .. vim.api.nvim_buf_get_option(0, 'filetype'),
              self:deindent(item.text),
              '```'
            }, '\n'),
          }
        }
      end, (result or {}).completions or {})
    })
  end, function()
    callback({
      isIncomplete = true,
      items = {},
    })
  end)
end


return source

