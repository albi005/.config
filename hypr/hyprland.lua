local terminal = 'alacritty'
-- local terminal = "wezterm"
local browser = 'zen-beta'
-- local browser = "helium"

hl.env('TERMINAL', terminal)
hl.env('BROWSER', browser)

--make obsidian use wayland
-- https://www.electronjs.org/docs/latest/api/environment-variables#electron_ozone_platform_hint-linux
hl.env('ELECTRON_OZONE_PLATFORM_HINT', 'wayland')

--novideo
hl.env('LIBVA_DRIVER_NAME', 'nvidia')
hl.env('XDG_SESSION_TYPE', 'wayland')
hl.env('GBM_BACKEND', 'nvidia-drm')
hl.env('__GLX_VENDOR_LIBRARY_NAME', 'nvidia')
hl.env('WLR_NO_HARDWARE_CURSORS', '1')

hl.on('hyprland.start', function()
    hl.exec_cmd'ags'
    hl.exec_cmd'albert'
    hl.exec_cmd'hyprpaper'
    hl.exec_cmd'lxqt-policykit-agent'
    hl.exec_cmd'wl-paste --watch cliphist store'
end)

hl.monitor{
    output = 'desc:Samsung Electric Company LS24AG30x H4PW100111',
    mode = 'preferred',
    position = '0x0',
    scale = '1',
}
hl.monitor{
    output = 'desc:Samsung Electric Company LC24RG50 HTHM301681',
    mode = 'preferred',
    position = '0x0',
    scale = '1',
}
hl.monitor{
    output = 'desc:Dell Inc. DELL SE2417HG P9T3N79H048I',
    mode = 'preferred',
    position = '-1920x0',
    scale = '1',
}
hl.monitor{
    output = '',
    mode = 'preferred',
    position = 'auto',
    scale = 'auto',
}

hl.config{
    input = {
        kb_layout = 'us,hu',
        kb_options = 'grp:win_space_toggle',
        kb_variant = '',
        kb_model = '',
        kb_rules = '',
        follow_mouse = 1,
        accel_profile = 'flat',
        touchpad = {
            natural_scroll = true,
        },
        sensitivity = 0, -- -1.0 - 1.0, 0 means no modification.
        repeat_rate = 30,
        repeat_delay = 220,
    },
    cursor = {
        no_hardware_cursors = true,
    },
    general = {
        gaps_in = 0,
        gaps_out = 0,
        border_size = 0,
        col = {
            active_border = { colors = { 'rgba(33ccffee)', 'rgba(00ff99ee)' }, angle = 45 },
            inactive_border = 'rgba(595959aa)',
        },
        layout = 'dwindle',
        -- Please see https://wiki.hyprland.org/Configuring/Tearing/ before you turn this on
        allow_tearing = false,
    },
    decoration = {
        rounding = 8,
        rounding_power = 2,
        blur = {
            enabled = true,
            size = 4,
            passes = 3,
        },
        shadow = {
            range = 40,
            render_power = 3,
            color = 'rgba(00000020)',
            offset = '2 4',
            scale = 1,
        },
    },
    animations = {
        enabled = false,
        -- Some default animations, see https://wiki.hyprland.org/Configuring/Animations/ for more
    },
    dwindle = {
        -- See https://wiki.hyprland.org/Configuring/Dwindle-Layout/ for more
        preserve_split = true, -- you probably want this
    },
    master = {
        -- See https://wiki.hyprland.org/Configuring/Master-Layout/ for more
        --new_is_master = true
    },
    misc = {
        force_default_wallpaper = 0, -- select default wallpaper: 0 -> generic, 2 -> uwu
        splash_font_family = 'Cascadia Code',
        focus_on_activate = true,
        initial_workspace_tracking = 1,
        middle_click_paste = false,
        -- enable_anr_dialog = false # disable app not responding dialog for debugging flutter apps
    },
}

hl.layer_rule{
    name = 'layerrule-1',
    match = {
        namespace = 'waybar',
    },
    blur = true,
}
hl.layer_rule{
    name = 'layerrule-2',
    match = {
        namespace = 'bar-0',
    },
    blur = true,
}
hl.layer_rule{
    name = 'layerrule-3',
    match = {
        namespace = 'bar-1',
    },
    blur = true,
}
hl.layer_rule{
    name = 'layerrule-4',
    match = {
        namespace = 'bar-2',
    },
    blur = true,
}
hl.layer_rule{
    name = 'layerrule-5',
    match = {
        namespace = 'rofi',
    },
    blur = true,
}

-- windowrule = float,kruler
-- windowrule = rounding 0,kruler
hl.window_rule{
    name = 'windowrule-1',
    match = {
        title = '^(Picture-in-Picture)$',
    },
    float = true,
    pin = true,
}
hl.window_rule{
    name = 'windowrule-2',
    match = {
        title = '(GrafikaApp)',
    },
    float = true,
}
hl.window_rule{
    name = "fix-albert",
    match = {
        title = "Albert"
    },
    decorate = false,
    no_blur = true,
}

-- disable padding for workspaces with a single tiled window
hl.workspace_rule{
    workspace = 'w[t1]',
    gaps_in = 0,
    gaps_out = 0,
    -- rounding = 0,
    border_size = 0,
}

-- KDE CONNECT Presentation Mode
-- https://reddit.com/r/hyprland/comments/1d0f2ou/to_the_one_person_using_kde_connect_presentation/
-- windowrule=move 0 0, title:KDE Connect Daemon
hl.window_rule{
    name = 'windowrule-3',
    match = {
        title = 'KDE Connect Daemon',
    },
    opacity = 1,
    no_blur = true,
    border_size = 0,
    no_shadow = true,
    no_anim = true,
    no_focus = true,
    suppress_event = 'fullscreen',
    float = true,
    pin = true,
    min_size = '1920 1080',
}

hl.curve('myBezier', { type = 'bezier', points = { { 0.05, 0.9 }, { 0.1, 1.05 } } })
hl.animation{
    leaf = 'windows',
    enabled = true,
    speed = 2,
    bezier = 'myBezier',
}
hl.animation{
    leaf = 'windowsOut',
    enabled = true,
    speed = 2,
    bezier = 'default',
    style = 'popin 80%',
}
hl.animation{
    leaf = 'border',
    enabled = true,
    speed = 2,
    bezier = 'default',
}
hl.animation{
    leaf = 'borderangle',
    enabled = true,
    speed = 2,
    bezier = 'default',
}
hl.animation{
    leaf = 'fade',
    enabled = true,
    speed = 2,
    bezier = 'default',
}
hl.animation{
    leaf = 'workspaces',
    enabled = true,
    speed = 1,
    bezier = 'default',
}

hl.gesture{
    fingers = 3,
    action = 'workspace',
    direction = 'horizontal',
}

hl.bind('SUPER + Q', hl.dsp.exec_cmd(terminal))
hl.bind('SUPER + C', hl.dsp.window.close())
hl.bind('CTRL + SHIFT + SUPER + I', hl.dsp.exec_cmd'uwsm stop')
hl.bind('SUPER + E', hl.dsp.exec_cmd'nemo')
hl.bind('SUPER + F', hl.dsp.window.float{ action = 'toggle' })
hl.bind('SUPER + R', hl.dsp.exec_cmd"echo -n '[\"toggle\"]' | nc -U ~/.cache/albert/ipc_socket")
hl.bind('SUPER + V',
    hl.dsp.exec_cmd'rofi -modi clipboard:~/.config/hypr/cliphist-rofi-img.sh -show clipboard -show-icons')
hl.bind('SUPER + W', hl.dsp.exec_cmd(browser))
hl.bind('SUPER + PERIOD', hl.dsp.exec_cmd'wofi-emoji')
hl.bind('SUPER + A', hl.dsp.exec_cmd'pkill ags; ags')
hl.bind('SUPER + S', hl.dsp.exec_cmd'jetbrains-toolbox')
hl.bind('SUPER + SHIFT + C', hl.dsp.exec_cmd'hyprpicker -a')

hl.bind('SUPER + T', hl.dsp.focus{ workspace = 'name:T' })
hl.workspace_rule{
    workspace = 'name:T',
    monitor = 'desc:Dell Inc. DELL SE2417HG P9T3N79H048I',
    on_created_empty = browser .. ' --new-window tidal.com',
}

hl.bind('SUPER + M', hl.dsp.focus{ workspace = 'name:M' })
hl.workspace_rule{
    workspace = 'name:M',
    on_created_empty = 'thunderbird',
}

hl.bind('SUPER + O', hl.dsp.focus{ workspace = 'name:O' })
hl.workspace_rule{
    workspace = 'name:O',
    on_created_empty = 'obsidian',
}

hl.bind('SUPER + B', hl.dsp.focus{ workspace = 'name:B' })
hl.workspace_rule{
    workspace = 'name:B',
    on_created_empty = 'beeper',
}

hl.bind('SUPER + H', hl.dsp.focus{ direction = 'left' })
hl.bind('SUPER + L', hl.dsp.focus{ direction = 'right' })
hl.bind('SUPER + K', hl.dsp.focus{ direction = 'up' })
hl.bind('SUPER + J', hl.dsp.focus{ direction = 'down' })

-- switch between vertical/horizontal split for windows
hl.bind('SUPER + U', hl.dsp.layout'togglesplit')

-- Switch workspaces with mainMod + [0-9]
hl.bind('SUPER + 1', hl.dsp.focus{ workspace = 1 })
hl.bind('SUPER + 2', hl.dsp.focus{ workspace = 2 })
hl.bind('SUPER + 3', hl.dsp.focus{ workspace = 3 })
hl.bind('SUPER + 4', hl.dsp.focus{ workspace = 4 })
hl.bind('SUPER + 5', hl.dsp.focus{ workspace = 5 })
hl.bind('SUPER + 6', hl.dsp.focus{ workspace = 6 })
hl.bind('SUPER + 7', hl.dsp.focus{ workspace = 7 })
hl.bind('SUPER + 8', hl.dsp.focus{ workspace = 8 })
hl.bind('SUPER + 9', hl.dsp.focus{ workspace = 9 })
hl.bind('SUPER + 0', hl.dsp.focus{ workspace = 10 })

-- Move active window to a workspace with mainMod + SHIFT + [0-9]
hl.bind('SUPER + SHIFT + 1', hl.dsp.window.move{ workspace = 1 })
hl.bind('SUPER + SHIFT + 2', hl.dsp.window.move{ workspace = 2 })
hl.bind('SUPER + SHIFT + 3', hl.dsp.window.move{ workspace = 3 })
hl.bind('SUPER + SHIFT + 4', hl.dsp.window.move{ workspace = 4 })
hl.bind('SUPER + SHIFT + 5', hl.dsp.window.move{ workspace = 5 })
hl.bind('SUPER + SHIFT + 6', hl.dsp.window.move{ workspace = 6 })
hl.bind('SUPER + SHIFT + 7', hl.dsp.window.move{ workspace = 7 })
hl.bind('SUPER + SHIFT + 8', hl.dsp.window.move{ workspace = 8 })
hl.bind('SUPER + SHIFT + 9', hl.dsp.window.move{ workspace = 9 })
hl.bind('SUPER + SHIFT + 0', hl.dsp.window.move{ workspace = 10 })
hl.bind('SUPER + SHIFT + T', hl.dsp.window.move{ workspace = 'name:T' })
hl.bind('SUPER + SHIFT + O', hl.dsp.window.move{ workspace = 'name:O' })

-- Scroll through existing workspaces with mainMod + scroll
hl.bind('SUPER + mouse_down', hl.dsp.focus{ workspace = 'e+1' })
hl.bind('SUPER + mouse_up', hl.dsp.focus{ workspace = 'e-1' })

-- Move/resize windows with mainMod + LMB/RMB and dragging
hl.bind('SUPER + mouse:272', hl.dsp.window.drag())
hl.bind('SUPER + mouse:273', hl.dsp.window.resize())

-- Set up media keys
-- https://www.reddit.com/r/hyprland/comments/1707yb8/comment/k3j8jgn
-- l -> do stuff even when locked
-- e -> repeats when key is held
hl.bind('XF86AudioMute', hl.dsp.exec_cmd'wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle', { locked = true })
hl.bind('XF86AudioPlay', hl.dsp.exec_cmd'playerctl play-pause', { locked = true })
hl.bind('XF86AudioNext', hl.dsp.exec_cmd'playerctl next', { locked = true })
hl.bind('XF86AudioPrev', hl.dsp.exec_cmd'playerctl previous', { locked = true })

-- compatibility
hl.bind('SUPER+CTRL+ALT+SHIFT + L', hl.dsp.exec_cmd'xdg-open https://linkedin.com')

-- Screenshots
-- PrtScn: everything
-- Shift + PrtScn: select area or window
hl.env('XDG_SCREENSHOTS_DIR', os.getenv'HOME' .. '/Pictures/Screenshots')
hl.bind('Print', hl.dsp.exec_cmd'mkdir -p $XDG_SCREENSHOTS_DIR && grimblast copysave')
hl.bind('SHIFT + Print', hl.dsp.exec_cmd'mkdir -p $XDG_SCREENSHOTS_DIR && grimblast copysave area')
hl.bind('SUPER + SHIFT + S', hl.dsp.exec_cmd'mkdir -p $XDG_SCREENSHOTS_DIR && grimblast copysave area')
hl.bind('SUPER + CTRL + SHIFT + S', hl.dsp.exec_cmd'mkdir -p $XDG_SCREENSHOTS_DIR && grimblast copysave')

-- to switch between windows in a floating workspace
hl.bind('SUPER + Tab', hl.dsp.window.cycle_next{ next = true }, { repeating = true })
hl.bind('SUPER + Tab', hl.dsp.window.bring_to_top(), { repeating = true })

-- toggle fullscreen
hl.bind('SUPER + F11', hl.dsp.window.fullscreen{ mode = 'fullscreen', action = 'toggle' })
hl.bind('SUPER + XF86AudioLowerVolume', hl.dsp.window.fullscreen{ mode = 'fullscreen', action = 'toggle' })

-- host-specific configuration managed using Nix
require'host'
