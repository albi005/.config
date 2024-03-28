-- https://wezfurlong.org/wezterm/config/files.html
local wezterm = require'wezterm'

return {
    color_scheme = 'Catppuccin Mocha',

    font = wezterm.font 'Cascadia Code',
    font_size = 11,

    hide_tab_bar_if_only_one_tab = true,

    window_padding = {
        left = 0,
        right = 0,
        top = 0,
        bottom = 0,
    },

    window_background_opacity = .8,
}
