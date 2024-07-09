const hyprland = await Service.import("hyprland")
const notifications = await Service.import("notifications")
const mpris = await Service.import("mpris")
const audio = await Service.import("audio")
const battery = await Service.import("battery")
//const systemtray = await Service.import("systemtray")

const date = Variable("", {
    poll: [1000, 'date "+%Y.%m.%d  %R"'],
})

// widgets can be only assigned as a child in one container
// so to make a reuseable widget, make it a function
// then you can simply instantiate one by calling it

function Workspaces(monitor) {
    const activeId = hyprland.active.workspace.bind("name")
    const workspaces = hyprland.bind("workspaces")
        .as(ws => ws
            .filter(w => w.monitorID == monitor)
            .sort((a, b) => a.name.localeCompare(b.name))
            .map(({ name: id }) => Widget.Button({
                on_clicked: () => hyprland.messageAsync(`dispatch workspace ${id}`),
                child: Widget.Label(`${id}`),
                class_name: activeId.as(i => `${i === id ? "focused" : ""}`),
            })))

    return Widget.Box({
        class_name: "workspaces",
        children: workspaces,
    })
}

function Clock() {
    return Widget.Label({
        class_name: "clock",
        label: date.bind(),
    })
}


// we don't need dunst or any other notification daemon
// because the Notifications module is a notification daemon itself
function Notification() {
    const popups = notifications.bind("popups")
    return Widget.Box({
        class_name: "notification",
        visible: popups.as(p => p.length > 0),
        children: [
            Widget.Icon({
                icon: "preferences-system-notifications-symbolic",
            }),
            Widget.Label({
                label: popups.as(p => p[0]?.summary || ""),
            }),
        ],
    })
}

function Media() {
    const details = Utils.watch({ artist: null, title: null }, mpris, "player-changed", () => {
        if (mpris.players[0]) {
            const { track_artists, track_title } = mpris.players[0]
            return { artist: track_artists.join(", "), title: track_title }
        } else {
            return { artist: null, title: null }
        }
    })

    return Widget.Button({
        class_name: "media",
        hpack: "start",
        on_primary_click: () => mpris.getPlayer("")?.playPause(),
        on_scroll_up: () => mpris.getPlayer("")?.next(),
        on_scroll_down: () => mpris.getPlayer("")?.previous(),
        child: Widget.Box({
            children: [
                Widget.Label({ label: details.as(d => d.artist ?? ""), css: "margin-right: 8px; color: alpha(@theme_fg_color, .6)" }),
                Widget.Label({ label: details.as(d => d.title ?? "") }),
            ]
        })
    })
}

/**
 * @param {string | undefined} playBackStatus
 */
function getIcon(playBackStatus) {
    switch (playBackStatus) {
        case "Playing":
            return "media-playback-pause";
        case "Paused":
            return "media-playback-start";
        case "Stopped":
            return "media-playback-start";
    }
    return "media-playback-start";
}

function MediaControls() {
    const player = mpris.bind("players").as(x => x.at(0));
    const p = () => mpris.getPlayer("");

    return Widget.Box({
        visible: player.as(p => !!p),
        children: [
            Widget.Button({
                child: Widget.Icon({ icon: "media-skip-backward" }),
                onClicked: () => p()?.previous(),
            }),
            Widget.Button({
                child: Widget.Icon({ icon: player.as(p => getIcon(p?.play_back_status)) }),
                onClicked: () => p()?.playPause(),
            }),
            Widget.Button({
                child: Widget.Icon({ icon: "media-skip-forward" }),
                onClicked: () => p()?.next(),
            }),
        ]
    });
}

function Volume() {
    const icons = {
        101: "overamplified",
        67: "high",
        34: "medium",
        1: "low",
        0: "muted",
    }

    function getIcon() {
        const icon = audio.speaker.is_muted ? 0 : [101, 67, 34, 1, 0].find(
            threshold => threshold <= audio.speaker.volume * 100)

        return `audio-volume-${icons[icon]}-symbolic`
    }

    const icon = Widget.Icon({
        icon: Utils.watch(getIcon(), audio.speaker, getIcon),
        css: "padding-right: 8px"
    })

    const label = Widget.Label({
        label: audio.speaker.bind("volume").as(v => Math.round(v * 100).toString() + "%")
    })

    return Widget.Button({
        on_primary_click: () => audio.speaker.is_muted = !audio.speaker.is_muted,
        on_scroll_up: () => audio.speaker.volume += .05,
        on_scroll_down: () => audio.speaker.volume -= .05,
        child: Widget.Box({
            class_name: "volume",
            children: [icon, label],
        })
    });
}


function BatteryLabel() {
    const value = battery.bind("percent").as(p => p > 0 ? p / 100 : 0)
    const icon = battery.bind("percent").as(p =>
        `battery-level-${Math.floor(p / 10) * 10}-symbolic`)

    return Widget.Box({
        class_name: "battery",
        visible: battery.bind("available"),
        children: [
            Widget.Icon({ icon }),
            Widget.LevelBar({
                widthRequest: 140,
                vpack: "center",
                value,
            }),
        ],
    })
}


// function SysTray() {
//     const items = systemtray.bind("items")
//         .as(items => items.map(item => Widget.Button({
//             child: Widget.Icon({ icon: item.bind("icon") }),
//             on_primary_click: (_, event) => item.activate(event),
//             on_secondary_click: (_, event) => item.openMenu(event),
//             tooltip_markup: item.bind("tooltip_markup"),
//         })))
//
//     return Widget.Box({
//         children: items,
//     })
// }


// layout of the bar
function Left(monitor = 0) {
    return Widget.Box({
        spacing: 8,
        children: [
            monitor == 0
                ? Notification()
                : Media()
        ],
    })
}

function Right() {
    return Widget.Box({
        hpack: "end",
        spacing: 8,
        children: [
            Volume(),
            BatteryLabel(),
            Clock(),
            //            SysTray(),
        ],
    })
}

function Bar(monitor = 0, child) {
    return Widget.Window({
        name: `bar-${monitor}`, // name has to be unique
        class_name: "bar",
        layer: "background",
        monitor,
        anchor: ["top", "left", "right"],
        exclusivity: "exclusive",
        heightRequest: 27,
        child,
    })
}

App.config({
    style: "./style.css",
    windows: [
        Bar(0, Widget.CenterBox({
            startWidget: Widget.Box({ children: [MediaControls(), Notification()] }),
            centerWidget: Workspaces(0),
            endWidget: Right(),
        })),
        Bar(1, Widget.CenterBox({
            startWidget: Media(),
            centerWidget: Workspaces(1),
        })),
    ],
})

export { }
