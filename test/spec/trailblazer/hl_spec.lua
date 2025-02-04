local hl = require('trailblazer.highlights')

-- Using indicies is necessary to keep the items ordered for testing.
-- [1] = TrailBlazerTrailMark
-- [2] = TrailBlazerTrailMark2
local hl_groups = {
  [1] = {
    [1] = "Black",
    [2] = "Red",
    [3] = "bold",
  },
  [2] = {
    link = 'TrailBlazerTrailMark',
  },
}

describe("Highlights.register:", function()
  it("Register highlight groups and return a list of registered group names.", function()
    assert.combinators.match(
      { "TrailBlazerTrailMark2" },
      hl.register({ TrailBlazerTrailMark2 = hl_groups[2] }))
  end)
end)

describe("Highlights.register_hl_groups:", function()
  it("Register a list of highlight groups.", function()
    assert.has_no.errors(function()
      hl.register_hl_groups({
        "hi TrailBlazerTrailMark guifg=Black guibg=Red gui=bold",
        "hi default link TrailBlazerTrailMark2 TrailBlazerTrailMark",
      })
    end)
  end)
end)

describe("Highlights.generate_group_strings:", function()
  it("Generate table of highlight strings.", function()
    assert.combinators.match({
      "hi default link 2 TrailBlazerTrailMark",
      "hi default 1 1=Black 2=Red 3=bold",
    }, hl.generate_group_strings(hl_groups))
  end)
end)

describe("Highlights.def_to_string:", function()
  it("Generate string from highlight definition.", function()
    assert.combinators.match("TrailBlazerTrailMark 1=Black 2=Red 3=bold",
      hl.def_to_string("TrailBlazerTrailMark", hl_groups[1]))
    assert.combinators.match("link TrailBlazerTrailMark2 TrailBlazerTrailMark",
      hl.def_to_string("TrailBlazerTrailMark2", hl_groups[2]))
  end)
end)
