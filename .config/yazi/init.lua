require("starship"):setup()
require("session"):setup({ sync_yanked = true })

-- show links in status bar
function Status:name()
    local h = cx.active.current.hovered
    return h and ui.Span(" " .. h.name .. (h.link_to and " -> " .. tostring(h.link_to) or "")) or ui.Span("")
end

-- show user/group in status bar
function Status:owner()
  local h = cx.active.current.hovered
  return h and ya.target_family() == "unix" and ui.Line {
    ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
    ui.Span(":"),
    ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
    ui.Span(" "),
  } or ui.Line {}
end
function Status:render(area)
  self.area = area
  local left = ui.Line { self:mode(), self:size(), self:name() }
  local right = ui.Line { self:owner(), self:permissions(), self:percentage(), self:position() }
  return {
    ui.Paragraph(area, { left }),
    ui.Paragraph(area, { right }):align(ui.Paragraph.RIGHT),
    table.unpack(Progress:render(area, right:width())),
  }
end
