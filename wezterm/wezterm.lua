-- https://wezfurlong.org/wezterm/config/files.html
local wezterm = require 'wezterm'
local act = wezterm.action
local scrollHeight = 4

return {
    color_scheme = 'Catppuccin Mocha',

    font = wezterm.font 'Cascadia Code',
    font_size = 11,

    hide_tab_bar_if_only_one_tab = true,
    scrollback_lines = 10000,
    window_close_confirmation = 'NeverPrompt',

    window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    },
    window_background_opacity = .8,

    -- https://github.com/wez/wezterm/discussions/4947#discussioncomment-8777872
    mouse_bindings = {
        {
            event = { Down = { streak = 1, button = { WheelUp = 1 } } },
            mods = 'NONE',
            action = act.ScrollByLine(-scrollHeight),
        },
        {
            event = { Down = { streak = 1, button = { WheelDown = 1 } } },
            mods = 'NONE',
            action = act.ScrollByLine(scrollHeight),
        },
    }
}
