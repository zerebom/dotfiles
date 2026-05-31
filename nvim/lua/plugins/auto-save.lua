return {
  "okuuva/auto-save.nvim",
  version = "*",
  event = { "InsertLeave", "TextChanged" },
  opts = {
    debounce_delay = 1000,
    condition = function(buf)
      if vim.bo[buf].buftype ~= "" then
        return false
      end
      if not vim.bo[buf].modifiable or vim.bo[buf].readonly then
        return false
      end
      if vim.api.nvim_buf_get_name(buf) == "" then
        return false
      end
      return true
    end,
  },
}
