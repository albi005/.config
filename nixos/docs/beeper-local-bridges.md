# Beeper + local/self-hosted bridges

Research notes for Albi's setup, 2026-11-02.

## TL;DR

Beeper now has **three** different things people call "bridges":

| Mode | Where the bridge runs | What it is good for |
|---|---|---|
| **On-Device Connection** | Inside the Beeper app on one device | Best privacy and reliability for supported networks. No server, no NixOS work. |
| **Beeper Cloud** | Beeper's servers | Works across all devices with zero setup. Required for Slack/Discord. |
| **Self-hosted (`bbctl`)** | Your own Linux machine | Keeps bridge processing/encryption on your hardware, still connects to your Beeper account. Needed for Zulip. |

Important: `bbctl` **does not replace Beeper with your own Matrix homeserver**. It registers an appservice bridge against Beeper's server (`*.beeper.local`) and uses your Beeper account. There is no supported way to log it into an independent Synapse/Matrix account.

Recommendation for your networks:

- **Messenger** → On-Device in Beeper Desktop. This is the most reliable option; the self-hosted `mautrix-meta` path uses Facebook cookies and breaks more often.
- **Telegram** → On-Device.
- **Slack / Discord** → Beeper Cloud. They are not available as On-Device connections. Self-host with `bbctl` only if you specifically do not want Beeper servers handling those messages.
- **Zulip** → Beeper has no Zulip support. Self-host `mautrix-zulip` via `bbctl` (new, still rough), or use `matterbridge` into a Beeper Matrix room as a fallback.
- **Matrix** → Beeper is already a Matrix account. You cannot attach an existing Matrix/Synapse account; you can only federate and chat with Matrix users/rooms from your Beeper MXID. Keep using your own Matrix client for that account.

Account limit: Beeper Free is 5 accounts, Beeper Plus is 10. Self-hosted bridges still count as connections on your Beeper account. If you really use Messenger + Slack + Discord + Telegram + Zulip + Matrix, check the limit before assuming everything fits.

## Current Beeper support matrix (from Beeper's help center)

**On-Device** supported networks:

WhatsApp, Instagram, Facebook Messenger, LinkedIn, Signal, Telegram, X, Google Voice, Tumblr DMs, WeChat, Viber.

**Beeper Cloud** supported networks:

WhatsApp, Instagram, Facebook Messenger, Discord, Google Chat, LinkedIn, LINE, Signal, Slack, Telegram, X, Google Messages, Google Voice, Tumblr DMs, WeChat, Viber.

Not supported by either: **Zulip**, generic Matrix account import, IRC, Mattermost, etc. (those need self-hosted/custom bridges).

On-Device behaviour:

- Runs only on the device where it was set up; it does not appear on your other Beeper devices.
- Messages never go to Beeper servers; only state such as archive/pin/reminder syncs.
- Logging out of the device deletes the connection.
- To switch from Cloud to On-Device you must remove the Cloud connection and re-add it as On-Device. There is no toggle.
- Setup: Beeper Settings → Accounts → Add account → choose the network → choose the On-Device option.

## Where the open-source bridge code actually lives

Yes — the bridges are open source, but they are split across two GitHub orgs:

- **`github.com/beeper/*`** — Beeper-owned projects: `bridge-manager`, `mautrix-meta` (a fork of `mautrix/meta`), iMessage/LINE/GroupMe/Teams/Chatwoot bridges, `synapse` (Beeper's Synapse fork), `babbleserv`, etc.
- **`github.com/mautrix/*`** — the canonical home of most bridges Beeper uses: `meta` (Messenger + Instagram), `slack`, `discord`, `telegram`, `signal`, `whatsapp`, `zulip`, `googlechat`, `gmessages`, `gvoice`, `twitter`, `bluesky`, `imessage`, `linkedin`, `irc`. Beeper maintains/sponsors these.

`beeper/self-host` (the old Ansible guide) is **archived**; `beeper/bridge-manager` is the current supported path and is Apache-2.0.

Licensing is a mix: most mautrix bridges are **AGPL-3.0**, while `bridge-manager` is Apache-2.0 and some smaller bridges are MIT/Apache-2.0. This does not change the setup: `bbctl run` downloads the bridge binaries/containers for you.

Open source bridges do **not** mean the whole Beeper stack is open source. The Beeper Desktop/mobile clients are closed-source forks of Element, and the hosted Beeper server is not a supported self-host replacement. What is open is the bridge/bridge-manager layer, plus Beeper's Synapse fork and experimental homeserver code. That is why `bbctl` still requires a Beeper account.

You can of course clone and build a bridge yourself (e.g. `mautrix/meta`, `mautrix/slack`) and point it at your own Synapse/Conduit homeserver. That is the "fully self-hosted Matrix" path, not the Beeper path. For Beeper, use `bbctl` or `bbctl config --type bridgev2` and let the bridge connect to Beeper's appservice websocket.

## How `bbctl` works

`bbctl` is Beeper's bridge manager:

- `bbctl login` authenticates to your Beeper account.
- `bbctl run sh-<name>` downloads, configures, registers, and runs an official Beeper/mautrix bridge.
- Bridges talk to Beeper over an appservice websocket; no inbound ports, TLS certificates, or public DNS are required.
- State lives in `~/.local/share/bbctl/<name>`; the login token lives in `~/.config/bbctl/config.json`.
- The bridge bot is `@<name>bot:beeper.local`. You DM it `help`, then log in to the chat network there.

Official bridge types usable with `bbctl run`:

`telegram`, `whatsapp`, `signal`, `discord`, `slack`, `gmessages`/`rcs`/`sms`, `gvoice`, `meta`/`facebook`/`instagram`, `googlechat`, `twitter`, `bluesky`, `imessage`, `imessagego`, `linkedin`, `heisenbridge`/`irc`.

Note: Messenger's type is **`meta`**, not `messenger`. The name `sh-messenger` does not contain a recognised type identifier, so pass `--type meta` explicitly.

## What I added to `~/.config/nixos`

Files:

- `pkgs/bbctl.nix` — packages the official static `bbctl` v0.15.0 release binary (not in nixpkgs).
- `modules/beeper-bridges.nix` — NixOS module that creates one systemd service per bridge.
- `flake.nix` — exposes it as `nix build .#bbctl`.

The module runs bridges as your normal user, because `bbctl` reads the login token from that user's home. It does **not** put tokens or cookies in the Nix store.

Example: enable it on `iron` (the always-on server):

```nix
# hosts/iron/configuration.nix
{
  imports = [
    # ...
    ../../modules/beeper-bridges.nix
  ];

  services.beeperBridges = {
    enable = true;
    user = "albi";

    bridges = {
      # Messenger: type is "meta"; name must be sh-*
      messenger = { name = "sh-messenger"; type = "meta"; };
      slack     = { name = "sh-slack";     type = "slack"; };
      discord   = { name = "sh-discord";   type = "discord"; };
      telegram  = { name = "sh-telegram";  type = "telegram"; };
    };
  };
}
```

Then:

```bash
# Build the package (optional sanity check)
nix build ~/.config/nixos#bbctl

# Log in ONCE as the service user, on the machine that will run the bridges.
# If Beeper Desktop is installed for the same user, bbctl can reuse its login;
# otherwise this emails a code:
bbctl login --no-desktop --email you@example.com

# Apply the NixOS config
sudo nixos-rebuild switch --flake ~/.config/nixos#iron

# Check status / logs
systemctl status beeper-bridge-messenger
journalctl -u beeper-bridge-messenger -f
```

If you prefer not to log in on the server, run `bbctl login` on your desktop first (it offers to reuse the Beeper Desktop login), then copy `~/.config/bbctl/config.json` to the server's `/home/albi/.config/bbctl/config.json` with mode `0600`.

## Logging each bridge into its network

Open Beeper, search for the bot `@sh-messengerbot:beeper.local`, start a DM, and send `help`. Then:

### Messenger (`mautrix-meta`)

```
login facebook        # or: login messenger
login messenger-lite  # username/password fallback
```

For cookie login, open `facebook.com` or `messenger.com` in a private window, open DevTools → Network → XHR, filter for `graphql`, log in, right-click a request → Copy → Copy as cURL (POSIX), and paste the whole thing into the bot. Required cookies are `datr`, `c_user`, `sb`, `xs`. Meta may temporarily block the account and ask for a captcha/phone confirmation; 2FA reduces that risk. This is exactly why On-Device is the better choice for Messenger.

### Slack (`mautrix-slack`)

```
login token <xoxc-token> <d-cookie>
```

Get the `xoxc-` token from `localStorage` in the Slack web app (`JSON.parse(localStorage.localConfig_v2).teams.<TEAM_ID>.token`) and the `d` cookie (`xoxd-...`) from DevTools. There is also an app/bot login mode (`login app`) if you want relay mode.

### Discord (`mautrix-discord`)

```
login-qr
# or
login-token user <token>
```

QR is easier but can hit CAPTCHAs. Token login: DevTools → Network → any `api` request → request header `Authorization`. Discord may ban suspicious self-bot use; a bot account is safer but more limited. Slack/Discord are still simpler as Beeper Cloud connections.

### Telegram (`mautrix-telegram`)

```
login qr
# or
login phone +123456789
```

Telegram sends the code to another logged-in Telegram client, not SMS. 2FA password is requested in the room. Telegram may flag brand-new accounts on third-party clients.

## Zulip (the unsupported one)

There is an official-ish mautrix bridge: `mautrix/zulip` (Matrix ↔ Zulip puppeting, built on bridgev2). It is new and not in `bbctl`'s official bridge list, so `bbctl run` will not install it. The path is:

```bash
# Generate a bridgev2 appservice config + registration for Beeper.
bbctl config --type bridgev2 sh-zulip
```

Then build/run `mautrix-zulip` (Go 1.26+; Dockerfile is in the repo) with that generated config, adding the `network` section. `bbctl config` prints the config path and the `@sh-zulipbot:beeper.local` bot name. Because it is bridgev2, it can use Beeper's appservice websocket directly — no `bbctl proxy` needed.

Login in the bot DM:

```
login
https://yourteam.zulipchat.com
you@example.com
<Zulip API key>
```

Get the API key from Zulip → Personal settings → Account & privacy → Manage your API key.

Caveat: `mautrix-zulip` is early-stage (12 GitHub stars at the time of writing, no release). If it misbehaves, the pragmatic fallback is `42wim/matterbridge` (Zulip ↔ Matrix room) with a dedicated Beeper/Matrix bot account. It relays messages into a room rather than puppeting your Zulip account, but it is much more mature.

## Matrix

Beeper is a Matrix homeserver account (`@you:beeper.com`). Consequences:

- You can DM `@someone:matrix.org` and join `#room:matrix.org` from Beeper.
- You cannot add your existing Matrix/Synapse account as a "chat network"; Beeper has no Matrix-to-Matrix bridge, and `bbctl` explicitly only supports Beeper accounts.
- If you want your existing Matrix identity in the same inbox, there is no clean supported path. Use a Matrix client for that account, or migrate your Matrix presence to the Beeper MXID and join the same rooms.

## Security notes

- Self-hosted bridges still send messages through Beeper's servers unless the network/bridge supports end-to-bridge encryption. Beeper says third-party bridges without E2BE expose message contents to Beeper servers.
- On-Device Messenger keeps messages off Beeper servers, but Facebook Messenger is not end-to-end encrypted by default.
- Slack tokens, Discord tokens, Facebook cookies and Zulip API keys are credentials. They live only in the service user's home, never in the Nix store. Keep `/home/albi/.config/bbctl` and `/home/albi/.local/share/bbctl` at `0700`.
- `bbctl delete <name>` removes the bridge and its rooms from Beeper; deleting through the Beeper UI leaves the local bridge database behind.

## If you want a fully self-hosted Matrix stack instead

NixOS has modules for `services.mautrix-meta`, `mautrix-discord`, `mautrix-signal`, `mautrix-telegram`, `mautrix-whatsapp`, plus Synapse/Conduit/continuwuity. That gives you a real Matrix homeserver and Element clients, but it is a different product from Beeper, requires a domain/TLS and federation decisions, and still has no Zulip module. `bbctl` is the lower-effort option if the goal is "Beeper UI, bridges on my hardware".

## Sources

- Beeper Bridge Manager (`bbctl`): https://github.com/beeper/bridge-manager
- Beeper self-host FAQ: https://www.beeper.com/faq
- Beeper help, connection types: https://help.beeper.com/en_US/chat-networks/using-on-device-chat-network-connections-in-beeper
- Beeper help, on-device vs cloud: https://help.beeper.com/en_US/troubleshooting/beeper-on-device-vs-beeper-cloud-what-goes-to-beeper-servers
- Beeper help, what self-hosting does: https://help.beeper.com/en_US/troubleshooting/what-beeper-self-hosting-does-and-which-account-it-uses
- Beeper help, Matrix chats: https://help.beeper.com/en_US/quick-references/using-matrix-chats-in-beeper
- mautrix-meta: https://github.com/mautrix/meta and https://docs.mau.fi/bridges/go/meta/authentication.html
- mautrix-slack: https://docs.mau.fi/bridges/go/slack/authentication.html
- mautrix-discord: https://docs.mau.fi/bridges/go/discord/authentication.html
- mautrix-telegram: https://docs.mau.fi/bridges/go/telegram/authentication.html
- mautrix-zulip: https://github.com/mautrix/zulip
- matterbridge: https://github.com/42wim/matterbridge
