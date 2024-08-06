// based on https://github.com/Aylur/ags/blob/main/example/media-widget/Media.js

const mpris = await Service.import("mpris")
const players = mpris.bind("players")

const PLAY_ICON = "media-playback-start-symbolic"
const PAUSE_ICON = "media-playback-pause-symbolic"
const PREV_ICON = "media-skip-backward-symbolic"
const NEXT_ICON = "media-skip-forward-symbolic"

/** @param {import('types/service/mpris').MprisPlayer} player */
function Player(player) {
    const playPause = Widget.Button({
        on_clicked: () => player.playPause(),
        visible: player.bind("can_play"),
        child: Widget.Icon({
            icon: player.bind("play_back_status").transform(s => {
                switch (s) {
                    case "Playing": return PAUSE_ICON
                    case "Paused":
                    case "Stopped": return PLAY_ICON
                }
            }),
        }),
    })

    const prev = Widget.Button({
        on_clicked: () => player.previous(),
        visible: player.bind("can_go_prev"),
        child: Widget.Icon(PREV_ICON),
    })

    const next = Widget.Button({
        on_clicked: () => player.next(),
        visible: player.bind("can_go_next"),
        child: Widget.Icon(NEXT_ICON),
    })

    return Widget.Box([
        prev,
        playPause,
        next,
    ])
}

export function MediaControls() {
    return Widget.Box({
        visible: players.as(p => p.length > 0),
        children: players.as(p => p.map(Player)),
    })
}
