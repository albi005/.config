const mpris = await Service.import("mpris")
const players = mpris.bind("players")

/** @param {import('types/service/mpris').MprisPlayer} player */
function Player(player) {
    return Widget.Button({
        class_name: "media",
        hpack: "start",
        on_primary_click: () => mpris.getPlayer("")?.playPause(),
        on_scroll_up: () => mpris.getPlayer("")?.next(),
        on_scroll_down: () => mpris.getPlayer("")?.previous(),
        child: Widget.Box({
            children: [
                Widget.Label({
                    label: player.bind("track_artists").transform(a => a.join(", ")),
                    css: "margin-right: 8px; color: alpha(@theme_fg_color, .6)"
                }),
                Widget.Label({
                    label: player.bind("track_title"),
                }),
            ]
        })
    })
}

export function MediaLabel() {
    return Widget.Box({
        visible: players.as(p => p.length > 0),
        children: players.as(p => p.map(Player)),
    })
}
