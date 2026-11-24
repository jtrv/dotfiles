require("mime-ext"):setup()
-- without file(1) fallback, files with no extension or an unknown one lose their MIME type
require("mime-ext.local"):setup({ fallback_file1 = true })
require("fuse-archive"):setup({ smart_enter = true })
require("dust-size"):setup()
require("git"):setup()
require("relative-motions"):setup({ show_numbers="relative_absolute", show_motion = true, enter_mode ="cache_or_first" })
require("session"):setup({ sync_yanked = true })
require("starship"):setup()

-- show links in status bar
function Status:name()
    local h = cx.active.current.hovered
    return h and ui.Span(" " .. h.name .. (h.link_to and " -> " .. tostring(h.link_to) or "")) or ui.Span("")
end

-- show user/group in status bar
Status:children_add(function()
  local h = cx.active.current.hovered
  if not h or ya.target_family() ~= "unix" then
    return ""
  end
  return ui.Line {
    ui.Span(ya.user_name(h.cha.uid) or tostring(h.cha.uid)):fg("magenta"),
    ui.Span(":"),
    ui.Span(ya.group_name(h.cha.gid) or tostring(h.cha.gid)):fg("magenta"),
    ui.Span(" "),
  }
end, 500, Status.RIGHT)
