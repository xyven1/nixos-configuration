-- Remove all trailing whitespace on save
local trim = vim.api.nvim_create_augroup('TrimWhiteSpace', { clear = true })
vim.api.nvim_create_autocmd("BufWritePre", {
  group = trim,
  command = [[:%s/\s\+$//e]]
})

-- Auto format on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*.go",
  callback = function() vim.lsp.buf.format { async = false } end,
})
