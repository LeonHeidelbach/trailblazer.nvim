local api = vim.api
local tr = require('trailblazer.trails')

describe("Trails.new_trail_mark:", function()
  it("Register a new trail mark with no active buffer. Throws 'invalid_pos_for_buf_lines error'.",
    function() assert.has_error(tr.new_trail_mark) end)
end)

describe("Trails.new_trail_mark:", function()
  it("Register a new trail mark with specific window, buffer and position.", function()
    local buf = vim.api.nvim_create_buf(false, true)
    local win = vim.api.nvim_open_win(buf, true, { relative = "editor", width = 1, height = 1,
      row = 1, col = 1 })
    local mark = tr.new_trail_mark(win, buf, { 1, 0 })
    assert.are.same(mark ~= nil, true)
    assert.are.same(mark, { win = win, buf = buf, pos = { 1, 0 }, mark_id = 1 })
  end)
end)

describe("Trails.new_trail_mark:", function()
  it("Register a new trail mark with active buffer but no parameteres at cursor position.",
    function()
      local buf = vim.api.nvim_create_buf(false, true)
      vim.api.nvim_set_current_buf(buf)
      local mark = tr.new_trail_mark()
      assert.are.same(mark ~= nil, true)
      assert.are.same(mark, tr.trail_mark_stack[tr.trail_mark_cursor])
    end)
end)

describe("Trails.track_back:", function()
  it("Track back to the last trail mark.", function()
    local mark = tr.new_trail_mark()
    if not mark then error("No trail mark was created.") end
    assert.are.same(mark ~= nil, true)
    assert.are.same(mark, tr.trail_mark_stack[tr.trail_mark_cursor])
    assert.are.same(tr.track_back(), true)
    assert.are.same(api.nvim_win_get_cursor(0), mark.pos)
  end)
end)

describe("Trails.peek_move_backward:", function()
  it("Peek move backward to the previous trail mark.", function()
    local mark = tr.new_trail_mark()
    if not mark then error("No trail mark was created.") end
    assert.are.same(mark ~= nil, true)
    assert.are.same(mark, tr.trail_mark_stack[tr.trail_mark_cursor])
    assert.are.same(tr.peek_move_backward(), true)
    assert.are.same(tr.peek_move_backward(), true)
    assert.are.same(api.nvim_win_get_cursor(0), tr.trail_mark_stack[#tr.trail_mark_stack - 2].pos)
  end)
end)

describe("Trails.peek_move_forward:", function()
  it("Peek move forward to the next trail mark.", function()
    local mark = tr.new_trail_mark()
    if not mark then error("No trail mark was created.") end
    assert.are.same(mark ~= nil, true)
    assert.are.same(mark, tr.trail_mark_stack[tr.trail_mark_cursor])
    assert.are.same(tr.peek_move_forward(), true)
    assert.are.same(api.nvim_win_get_cursor(0), tr.trail_mark_stack[#tr.trail_mark_stack - 2].pos)
  end)
end)
