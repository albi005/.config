# NixOS GitOps Setup

Pull-based, PR-driven NixOS GitOps modeled after `kir-dev/k8s` (ArgoCD + Renovate + declarative app builder), adapted natively for NixOS across all 5 machines (`iron`, `slime`, `redstone`, `netherite`, `water`).

---

## Architecture

```
App Repo (alb1.hu, StartSCH, ...)
  │  push to main
  ▼
Reusable GitHub Action (in albi005/.config)
  ├─ Native Nix app:        updates nixos/apps/<app>/pin.json (+ deps.json), verifies `nix build`
  └─ Dockerfile app:        builds Dockerfile → exports .tar.gz to GitHub Release/R2 (NO container registry!)
                            → updates nixos/apps/<app>/pin.json with URL + SRI hash
  │  opens PR with GitHub compare diff link
  ▼
Pull Request on albi005/.config  ──►  .github/workflows/ci.yml
  • Detects affected hosts (or all 5 on shared changes)
  • Builds nixosConfigurations.<host>.config.system.build.toplevel on GHA runners
  • Uploads ONLY custom (non-cache.nixos.org) store paths to Cloudflare R2 (~5–80 MB/host)
  • Comments on the PR with an `nvd diff` showing exact package & app version changes
  │  you review & merge
  ▼
Push to main  ──►  .github/workflows/deploy.yml
  • Ensures every host closure is built & cached in Cloudflare R2
  • Atomically advances `deploy/<host>` ONLY after build + R2 upload succeed
  ▼
All 5 NixOS Hosts (`comin`, outbound HTTPS only)
  • iron / slime (role = "server"):  poll `deploy/<host>` every 60s, switch immediately
  • redstone / netherite / water (role = "desktop"): poll every 300s, desktop notification + 2-min window (`gpause` to defer)
  • Pulls 100% prebuilt closures from cache.nixos.org + Cloudflare R2
```

### Why this fits every machine's constraints

| Host | Constraint | How this architecture handles it |
|---|---|---|
| **iron** | Always-on, 2 threads, 100 Mbps | Never compiles locally; `deploy/iron` only advances after CI uploads all custom paths to R2. |
| **slime** | Always-on, isolated tailnet | Pure pull over outbound HTTPS to GitHub + R2; zero cross-tailnet links, zero Tailscale/SSH secrets in CI. |
| **netherite** | Dorm 32 GB/week traffic cap | Only downloads small changed Nix store deltas; weekly flake bumps are PR-gated so you pick when to merge. |
| **redstone** | Beefy home desktop, powered off often | Zero need to leave it running as a cache/builder; auto-updates from R2 whenever you boot it. |
| **water** | 2017 MacBook Air, 128 GB NixOS disk | Zero local builds for updates; aggressive GC (`7d`, `min-free = 5 GiB`, `bootEntryLimit = 5`, `auto-optimise-store`). |
| **Dotfiles** | Hot-reload (Hyprland, Helix, ...) | Unchanged! `~/.config` stays a manual git checkout; `comin` only manages `nixos/` from GitHub. |

---

## One-Time Setup (~10 minutes)

### 1. Create the Cloudflare R2 binary cache (uses your existing Cloudflare account)

No separate account or client login is needed on your NixOS machines — reads happen over public HTTPS (`https://cache.alb1.hu`) verified by your Nix signing key, and only GitHub Actions holds the write token.

1. In the **Cloudflare Dashboard → R2 Object Storage**, create a bucket (e.g. `nix-cache`).
2. In the bucket's **Settings → Public Access → Custom Domains**, connect `cache.alb1.hu` (Cloudflare auto-creates the DNS record).
3. In **R2 → Manage R2 API Tokens**, create an API token with **Object Read & Write** scoped to the `nix-cache` bucket. Note:
   - `Access Key ID`
   - `Secret Access Key`
   - S3 API endpoint: `https://<YOUR_ACCOUNT_ID>.r2.cloudflarestorage.com`

### 2. Generate a Nix binary cache signing keypair

Run once on any machine with Nix:

```bash
nix-store --generate-binary-cache-key cache.alb1.hu-1 /tmp/nix-cache-sec.key /tmp/nix-cache-pub.key
cat /tmp/nix-cache-pub.key
# Example: cache.alb1.hu-1:AbCdEf...=
```

Keep `/tmp/nix-cache-sec.key` ONLY in GitHub Actions Secrets (delete it from `/tmp` afterwards).

### 3. Add GitHub Actions Variables & Secrets on `albi005/.config`

In **GitHub → `albi005/.config` → Settings → Secrets and variables → Actions**:

**Variables:**
- `R2_BUCKET` = `nix-cache`
- `R2_ENDPOINT` = `https://<YOUR_ACCOUNT_ID>.r2.cloudflarestorage.com`
- `R2_CACHE_URL` = `https://cache.alb1.hu`
- `R2_PUBLIC_KEY` = contents of `/tmp/nix-cache-pub.key`

**Secrets:**
- `R2_ACCESS_KEY_ID` = R2 token Access Key ID
- `R2_SECRET_ACCESS_KEY` = R2 token Secret Access Key
- `NIX_SIGNING_KEY` = contents of `/tmp/nix-cache-sec.key`

Also enable **Settings → Actions → General → Workflow permissions → Allow GitHub Actions to create and approve pull requests** (for the weekly `update-pins.yml` PRs).

### 4. Wire the public cache URL & key into NixOS

In [`nixos/modules/gitops.nix`](./modules/gitops.nix), set the defaults (or set in `base.nix`):

```nix
albi.gitops.cache = {
  url = "https://cache.alb1.hu";
  publicKey = "cache.alb1.hu-1:...";
};
```

### 5. Create a Fine-Grained PAT for your app repos

Create one fine-grained GitHub PAT scoped ONLY to `albi005/.config` with **Contents: Read and write** and **Pull requests: Read and write**. Add it as `CONFIG_REPO_TOKEN` in each app repo that should open deployment PRs.

### 6. Bootstrap each host once

Merge this branch to `main` (which runs `deploy.yml`, populates R2, and creates `deploy/<host>` branches), then run one final manual switch on each host so `comin` is installed and running:

```bash
cd ~/.config && git pull
rb
```

After that, check status anytime with `gs` (`comin status`), force an immediate poll with `gf` (`comin fetch`), or pause automatic updates while hacking locally with `gpause` / `gresume`.

---

## Deploying Your Apps

### Option A: Native Nix App (recommended — zero Docker)

See [`nixos/apps/alb1/`](./apps/alb1/) for the live reference implementation.

1. Create `nixos/apps/<app>/pin.json` (`kind = "nix"`, `owner`, `repo`, `rev`, `version`, `hash`) and `nixos/apps/<app>/package.nix`.
2. Export `<app>` in `nixos/flake.nix` under `packages.x86_64-linux`.
3. Declare it on your target host using `albi.apps.<app>` (`runtime = "systemd"`).
4. Add `.github/workflows/deploy.yml` in your app repo:

```yaml
name: Deploy
on:
  push:
    branches: [main]
  workflow_dispatch:

jobs:
  deploy:
    uses: albi005/.config/.github/workflows/reusable-deploy-nix-app.yml@main
    with:
      app: alb1
    secrets:
      CONFIG_REPO_TOKEN: ${{ secrets.CONFIG_REPO_TOKEN }}
```

### Option B: Dockerfile App (zero container registry!)

See [`nixos/apps/_examples/dockerfile-app/`](./apps/_examples/dockerfile-app/) for a ready-to-copy template.

1. Create `nixos/apps/<app>/pin.json` (`kind = "dockerfile"`).
2. Declare it on your target host using `albi.apps.<app>` with `runtime = "oci"` and `inherit (pin) image imageFile;`.
3. Add `.github/workflows/deploy.yml` in your app repo:

```yaml
name: Deploy
on:
  push:
    branches: [main]
  workflow_dispatch:

permissions:
  contents: write

jobs:
  deploy:
    uses: albi005/.config/.github/workflows/reusable-deploy-dockerfile-app.yml@main
    with:
      app: startsch
      dockerfile: StartSch/Dockerfile
    secrets:
      CONFIG_REPO_TOKEN: ${{ secrets.CONFIG_REPO_TOKEN }}
```

For private app repos, set `storage: r2` plus `r2_bucket`, `r2_endpoint`, `r2_public_url`, and pass `R2_ACCESS_KEY_ID` / `R2_SECRET_ACCESS_KEY`.

### Option C: Pinned 3rd-Party OCI Images

Add the image to [`nixos/pins/images.json`](./pins/images.json) and reference it via `pins.imageRef "<name>"`. Every image is cryptographically pinned to `@sha256:...` and automatically bumped via weekly PRs from `.github/workflows/update-pins.yml` (or locally with `./scripts/ci/update-image-pins.sh`).

---

## Testing Ephemeral Changes (`testing/<host>`)

Want to test a risky change on `iron` without touching `main` or writing a boot entry? Push a branch named `testing/iron`:

```bash
git push origin HEAD:testing/iron
```

`comin` will run `switch-to-configuration test` — if anything breaks, a simple reboot restores the last known-good `deploy/iron` generation. Delete the branch (`git push origin :testing/iron`) when done.
