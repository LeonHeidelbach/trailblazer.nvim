local api = vim.api
local tr = require('trailblazer.trails')

describe("Trails.actions.new_trail_mark:", function()
  it("Register a new trail mark with no active buffer. Throws 'invalid_pos_for_buf_lines error'.",
    function()
      assert.has_error(tr.actions.new_trail_mark)
      assert.are.same(true, #tr.stacks.current_trail_mark_stack == 0)
    end)
end)

describe("Trails.actions.new_trail_mark:", function()
  it("Register a new trail mark with specific window, buffer and position.", function()
    local buf = vim.api.nvim_create_buf(true, false)
    local win = vim.api.nvim_open_win(buf, true, {
      relative = "editor",
      width = 1,
      height = 1,
      row = 1,
      col = 1
    })
    local mark = tr.actions.new_trail_mark(win, buf, { 1, 0 })
    if not mark then error("No trail mark was created.") end
    assert.are.same(true, mark ~= nil)
    assert.are.same({ win = win, buf = buf, pos = { 1, 0 }, mark_id = 1 },
      { win = mark.win, buf = mark.buf, pos = mark.pos, mark_id = mark.mark_id })
  end)
end)

describe("Trails.actions.new_trail_mark:", function()
  it("Register a new trail mark with active buffer but no parameteres at cursor position.",
    function()
      local buf = vim.api.nvim_create_buf(true, false)
      vim.api.nvim_set_current_buf(buf)
      local mark = tr.actions.new_trail_mark()
      if not mark then error("No trail mark was created.") end
      assert.are.same(true, mark ~= nil)
      assert.are.same(mark, tr.stacks.current_trail_mark_stack[tr.stacks.trail_mark_cursor])
    end)
end)

describe("Trails.actions.track_back:", function()
  it("Track back to the last trail mark.", function()
    local buf = vim.api.nvim_create_buf(true, false)
    local mark = tr.actions.new_trail_mark(nil, buf, nil)
    if not mark then error("No trail mark was created.") end
    assert.are.same(true, mark ~= nil)
    assert.are.same(mark, tr.stacks.current_trail_mark_stack[tr.stacks.trail_mark_cursor])
    tr.common.reregister_trail_marks()
    assert.are.same(true, tr.actions.track_back())
    assert.are.same(api.nvim_win_get_cursor(0), mark.pos)
  end)
end)

describe("Trails.motions.peek_move_next_down:", function()
  it("Peek move backward to the previous trail mark.", function()
    local buf = vim.api.nvim_create_buf(true, false)
    local mark = tr.actions.new_trail_mark(nil, buf, nil)
    if not mark then error("No trail mark was created.") end
    assert.are.same(true, mark ~= nil)
    assert.are.same(mark, tr.stacks.current_trail_mark_stack[tr.stacks.trail_mark_cursor])
    tr.common.reregister_trail_marks()
    assert.are.same(true, tr.motions.peek_move_next_down())
    tr.common.reregister_trail_marks()
    assert.are.same(true, tr.motions.peek_move_next_down())
    assert.are.same(api.nvim_win_get_cursor(0),
      tr.stacks.current_trail_mark_stack[#tr.stacks.current_trail_mark_stack - 2].pos)
  end)
end)

describe("Trails.motions.peek_move_previous_up:", function()
  it("Peek move forward to the next trail mark.", function()
    local buf = vim.api.nvim_create_buf(true, false)
    local mark = tr.actions.new_trail_mark(nil, buf, nil)
    if not mark then error("No trail mark was created.") end
    assert.are.same(mark ~= nil, true)
    assert.are.same(mark, tr.stacks.current_trail_mark_stack[tr.stacks.trail_mark_cursor])
    tr.common.reregister_trail_marks()
    assert.are.same(true, tr.motions.peek_move_previous_up())
    assert.are.same(api.nvim_win_get_cursor(0),
      tr.stacks.current_trail_mark_stack[#tr.stacks.current_trail_mark_stack - 2].pos)
  end)
end)
