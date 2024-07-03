local M = {}
M.levenshtein_distance = function()
  local s1 = table.concat(vim.api.nvim_buf_get_lines(M.cur.btest, 0, -1, false), "\n")
  local s2 = table.concat(vim.api.nvim_buf_get_lines(M.cur.btype, 0, -1, false), "\n")

  local len1 = #s1
  local len2 = #s2
  local words = 0
  for _ in string.gmatch(s1, "%S+") do
    words = words + 1
  end

  local matrix = {}
  for i = 0, len1 do
    matrix[i] = { [0] = i }
  end
  for j = 1, len2 do
    matrix[0][j] = j
  end
  for i = 1, len1 do
    for j = 1, len2 do
      local cost = s1:sub(i, i) == s2:sub(j, j) and 0 or 1
      matrix[i][j] = math.min(
        matrix[i - 1][j] + 1,       -- deletion
        matrix[i][j - 1] + 1,       -- insertion
        matrix[i - 1][j - 1] + cost -- substitution
      )
    end
  end
  return len1, matrix[len1][len2], words
end
M.hello = function()
  print("hello")
end
M.insertEnter = function()
  M.st = vim.loop.hrtime()
end
M.insertLeave = function()
  vim.api.nvim_win_close(M.cur.wtype, true)
  vim.api.nvim_win_close(M.cur.wtest, true)

  vim.api.nvim_clear_autocmds({ group = "tt_group" })

  M.et = vim.loop.hrtime()
  local ms_elapsed = (M.et - M.st) / 1e6
  local len, err, words = M:levenshtein_distance()
  local acc = (len - err) * 100 / len
  local wpm = (words * acc / 100) * 1000 * 60 / ms_elapsed
  local success
  if acc >= 70 then
    success = "success"
  else
    success = "failed"
  end
  local info = string.format("%s accuracy: %.2f%% speed: %.2f wpm", success, acc, wpm)
  print(info)
end
M.createWindows = function()
  M.cur = {}
  -- create buffers
  M.cur.btest = vim.api.nvim_create_buf(false, true)
  M.cur.btype = vim.api.nvim_create_buf(false, true)

  local cols = vim.api.nvim_get_option("columns")
  local lines = vim.api.nvim_get_option("lines")

  local w = math.floor(cols * 0.7)
  local h = math.floor(lines * 0.35)
  local c_off = math.floor((cols - w) / 2)
  local r_off = math.floor((lines - h * 2) / 2)

  M.cur.wtest = vim.api.nvim_open_win(M.cur.btest, 0, {
    relative = "editor",
    width = w,
    height = h,
    col = c_off,
    row = r_off,
    style = "minimal",
    border = "single",
    title = " test ",
    focusable = false,
  })
  M.cur.wtype = vim.api.nvim_open_win(M.cur.btype, 0, {
    relative = "editor",
    width = w,
    height = h,
    col = c_off,
    row = r_off + h + 2,
    style = "minimal",
    border = "single",
    title = " type ... ",
    focusable = true,
  })
  -- set windows options
  vim.api.nvim_win_set_option(M.cur.wtest, "number", true)
  vim.api.nvim_win_set_option(M.cur.wtype, "number", true)
  -- set test buffer
  vim.api.nvim_buf_set_lines(M.cur.btest, 0, -1, true, { "hello sir", "second line" })
  -- set autocmd group
  local tt_group = vim.api.nvim_create_augroup("tt_group", { clear = true })
  vim.api.nvim_create_autocmd("InsertEnter", {
    group = tt_group,
    callback = M.insertEnter,
  })
  vim.api.nvim_create_autocmd("InsertLeave", {
    group = tt_group,
    callback = M.insertLeave,
  })
end

M.start = function()
  M.createWindows()
  for k, v in pairs(M.cur) do
    print(k, v)
  end
end

M.setup = function()
  vim.cmd("command! Typetest lua require('typetest').start()")
end

return M
