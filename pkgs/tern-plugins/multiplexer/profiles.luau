--!strict

local PLUGIN = "plugin.multiplexer."
local PREFIX = "ctrl+b>"

local herdr = {
  [PREFIX .. "h"] = "focus_pane:left",
  [PREFIX .. "j"] = "focus_pane:down",
  [PREFIX .. "k"] = "focus_pane:up",
  [PREFIX .. "l"] = "focus_pane:right",
  [PREFIX .. "p"] = "previous_tab",
  [PREFIX .. "n"] = "next_tab",
  [PREFIX .. "c"] = "new_tab",
  [PREFIX .. "shift+n"] = "plugin.spaces.new_space",
  [PREFIX .. "v"] = "split_right",
  [PREFIX .. "minus"] = "split_down",
  [PREFIX .. "z"] = "zoom",
  [PREFIX .. "x"] = "close_tab",
  [PREFIX .. "ctrl+x"] = "close_tab",
  [PREFIX .. "b"] = "toggle_sidebar",
  [PREFIX .. "."] = PLUGIN .. "next_agent",
  [PREFIX .. ","] = PLUGIN .. "previous_agent",
  [PREFIX .. "shift+r"] = PLUGIN .. "label_agent",
  [PREFIX .. "ctrl+b"] = PLUGIN .. "send_prefix",
}

local tmux = {
  [PREFIX .. "%"] = "split_right",
  [PREFIX .. '"'] = "split_down",
  [PREFIX .. "left"] = "focus_pane:left",
  [PREFIX .. "down"] = "focus_pane:down",
  [PREFIX .. "up"] = "focus_pane:up",
  [PREFIX .. "right"] = "focus_pane:right",
  [PREFIX .. "o"] = "next_pane",
  [PREFIX .. ";"] = PLUGIN .. "last_pane",
  [PREFIX .. "c"] = "new_tab",
  [PREFIX .. "p"] = "previous_tab",
  [PREFIX .. "n"] = "next_tab",
  [PREFIX .. "z"] = "zoom",
  [PREFIX .. "x"] = "close_pane",
  [PREFIX .. "&"] = "close_tab",
  [PREFIX .. ","] = "rename_tab",
  [PREFIX .. "["] = "open_scrollback",
  [PREFIX .. "space"] = "equalize",
  [PREFIX .. "ctrl+b"] = PLUGIN .. "send_prefix",
}

-- Zellij's mode prefixes are one-shot sequences here, leaving normal typing to the pane.
local zellij = {
  ["ctrl+p>h"] = "focus_pane:left",
  ["ctrl+p>j"] = "focus_pane:down",
  ["ctrl+p>k"] = "focus_pane:up",
  ["ctrl+p>l"] = "focus_pane:right",
  ["ctrl+p>r"] = "split_right",
  ["ctrl+p>d"] = "split_down",
  ["ctrl+p>n"] = "split_right",
  ["ctrl+p>x"] = "close_pane",
  ["ctrl+p>f"] = "zoom",
  ["ctrl+p>w"] = "equalize",
  ["ctrl+t>n"] = "new_tab",
  ["ctrl+t>h"] = "previous_tab",
  ["ctrl+t>l"] = "next_tab",
  ["ctrl+t>x"] = "close_tab",
  ["ctrl+t>r"] = "rename_tab",
  ["ctrl+n>h"] = "resize_split:left",
  ["ctrl+n>j"] = "resize_split:down",
  ["ctrl+n>k"] = "resize_split:up",
  ["ctrl+n>l"] = "resize_split:right",
  ["alt+h"] = "focus_pane:left",
  ["alt+j"] = "focus_pane:down",
  ["alt+k"] = "focus_pane:up",
  ["alt+l"] = "focus_pane:right",
}

for index = 1, 9 do
  herdr[PREFIX .. index] = "goto_tab:" .. index
  herdr[PREFIX .. "w>" .. index] = "plugin.spaces.space_" .. index
  herdr[PREFIX .. "shift+" .. index] = PLUGIN .. "agent_" .. index
  tmux[PREFIX .. index] = "goto_tab:" .. index
  zellij["ctrl+t>" .. index] = "goto_tab:" .. index
end

return {
  default = "herdr",
  styles = { herdr = herdr, tmux = tmux, zellij = zellij },
  -- Personal bindings intentionally replace the selected style's entries.
  personal = {
    ["ctrl+alt+h"] = "focus_pane:left",
    ["ctrl+alt+j"] = "focus_pane:down",
    ["ctrl+alt+k"] = "focus_pane:up",
    ["ctrl+alt+l"] = "focus_pane:right",
    ["ctrl+alt+["] = "previous_tab",
    ["ctrl+alt+]"] = "next_tab",
    ["ctrl+shift+tab"] = "previous_tab",
    ["ctrl+tab"] = "next_tab",
    ["ctrl+alt+c"] = "new_tab",
    ["ctrl+shift+w"] = "close_tab",
    ["ctrl+alt+d"] = "split_right",
    ["ctrl+alt+shift+d"] = "split_down",
    ["ctrl+alt+z"] = "zoom",
    ["ctrl+alt+tab"] = PLUGIN .. "last_pane",
    ["ctrl+alt+b"] = "toggle_sidebar",
  },
}
