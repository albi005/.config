import { MediaControls } from "./MediaControls.js"
import { MediaLabel } from "./MediaLabel.js"
import { Clock } from "./Clock.js"
import { NotificationPopups } from "./NotificationPopup.js"

const hyprland = await Service.import("hyprland")
const notifications = await Service.import("notifications")
const audio = await Service.import("audio")
const battery = await Service.import("battery")
const systemtray = await Service.import("systemtray")

/** @param {number} monitor */
function Workspaces(monitor) {
    const activeId = hyprland.active.workspace.bind("name")
    const workspaces = hyprland.bind("workspaces")
        .as(ws => ws
            .filter(w => w.monitorID == monitor)
            .sort((a, b) => a.id - b.id)
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
            Widget.Icon({
                icon,
                css: "padding-right: 6px"
            }),
            Widget.Label({ label: value.as(p => Math.floor(p * 100) + "%") }),
        ],
    })
}

function SysTray() {
    const items = systemtray.bind("items")
        .as(items => items.map(item => Widget.Button({
            child: Widget.Icon({ icon: item.bind("icon") }),
            on_primary_click: (_, event) => item.activate(event),
            on_secondary_click: (_, event) => item.openMenu(event),
            tooltip_markup: item.bind("tooltip_markup"),
        })))

    return Widget.Box({
        children: items,
    })
}

function Right() {
    return Widget.Box({
        hpack: "end",
        spacing: 8,
        children: [
            SysTray(),
            Volume(),
            BatteryLabel(),
            Clock(),
        ],
    })
}

function Bar(monitor = 0, child) {
    return Widget.Window({
        name: `bar-${monitor}`, // name has to be unique
        class_name: "bar",
        layer: "bottom",
        monitor,
        anchor: ["top", "left", "right"],
        exclusivity: "exclusive",
        heightRequest: 27,
        child,
    })
}

const hostname = Utils.exec("hostname")

/**
 * @param {string} hostname
 */
function getWindows(hostname) {
    switch (hostname) {
        case 'redstone':
            return [
                Bar(0, Widget.CenterBox({
                    startWidget: Widget.Box({ children: [MediaControls(), /* Notification() */] }),
                    centerWidget: Workspaces(0),
                    endWidget: Right(),
                })),
                Bar(1, Widget.CenterBox({
                    startWidget: MediaLabel(),
                    centerWidget: Workspaces(1),
                    endWidget: Right(),
                })),
            ];
    }
    return [
        Bar(0, Widget.CenterBox(
            {
                startWidget: Widget.Box({ children: [MediaControls(), /* Notification() */] }),
                centerWidget: Workspaces(0),
                endWidget: Right(),
            }
        ))
    ];
}

const windows = getWindows(hostname);
windows.push(NotificationPopups());

App.config({
    style: "./style.css",
    windows,
});

export { }
