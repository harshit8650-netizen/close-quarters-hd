# Close Quarters HD: Last Standing — v2.0

Upgraded native 3D Android multiplayer FPS prototype with higher-detail procedural graphics, original articulated characters, and optional online CC0 model/material downloads during CI. Godot 4.4.1 + Node.js 22. Native Android rendering; no WebView. This repository contains source, not a prebuilt APK. The server rules were tested locally; Android export and online end-to-end tests must run in GitHub Actions because Godot, Android SDK and the ws dependency were unavailable in the creation environment.

## 1 — Build the Android APK on GitHub

1. Extract the ZIP. Create an empty repository at https://github.com/new (private is fine). Name it `close-quarters-hd` under account `harshit8650-netizen`. Do not initialize with README.
2. Install Git for Windows from https://git-scm.com/download/win. In the extracted project root, double-click `PUSH_TO_GITHUB.cmd` to initialize, commit and push the project. Alternatively, open PowerShell there and run:

```powershell
git init -b main
git add .
git commit -m "Initial Close Quarters game"
git remote add origin https://github.com/harshit8650-netizen/close-quarters-hd.git
git push -u origin main
```

If Git asks for an identity, use `git config user.name "Your Name"` and `git config user.email "your@email.com"` before committing. Make sure `.github/workflows/android.yml` is uploaded; it is a hidden directory on some systems. The project root must contain `game`, `server`, and `.github`, not an extra enclosing folder.

3. In GitHub, open **Actions → Build Android HD APK → Run workflow → Run workflow** (the initial push also triggers it). If Actions are disabled, enable them in the repo settings. The workflow runs unit and integration tests, installs the Godot engine and matching templates, imports the project, checks the script, performs a headless launch, builds and verifies a debug-signed ARM64 APK.
4. After a successful run, open it and download **CloseQuarters-HD-Android-APK** in Artifacts. Extract the downloaded artifact ZIP to get `CloseQuartersHD.apk`. Transfer to Android and allow installs from the file manager if prompted. This is a debug build for testing, not a Play Store release. A fresh debug signing key is generated on each run; uninstall the prior APK before installing an updated build if signatures differ (this also deletes local profile data). For production, create a persistent release signing key and add an AAB export, using GitHub Secrets rather than committing keys.

Optional: In repo **Settings → Secrets and variables → Actions → Variables**, create `GAME_SERVER_URL` with your `wss://` server address; future APKs will pre-fill that server URL. Players can also type the URL on the login screen.

### Graphics and assets

Select Performance, HD (default) or Ultra in the lobby. Performance reduces render resolution and local lights; HD uses 2x MSAA and local lighting; Ultra uses 4x MSAA and higher render resolution. These are quality presets, not guarantees of frame rate or display resolution. Use **3D PREVIEW** before connecting to a room to inspect the selected map and animated outfit/hairstyle without a server. Character motion is code-driven hierarchical articulation, not a realistic motion-capture rig. The preview cycles through idle, run, firing and reload animations. Eliminated remote characters fall over during the match.

The build workflow runs `python3 tools/fetch_hd_assets.py` before Godot imports the project. It attempts to download CC0 desk, sofa and crate models plus five scanned PBR material sets; downloaded models replace supported procedural props. Review `manifest.json` in the build artifact and see `ASSET_CREDITS.md`. Online assets are not bundled in the source ZIP because direct downloads were blocked in the creation environment. Failed downloads are logged, with offline fallback meshes and materials. A strict build is available by adding `--strict` to the workflow download command. No external services are used for graphics at runtime. The downloadable package is not a precompiled APK.

## 2 — Start the multiplayer server (required)

GitHub builds the APK; it does not run a persistent multiplayer game server. Run a Node server on a computer or cloud host. For testing on the same Wi-Fi:

```powershell
cd server
npm install
npm start
```

Allow TCP port 8080 on the host firewall. Run `ipconfig` on the host to obtain its LAN IPv4 address. On the phones, use `ws://192.168.x.x:8080` (replace with that LAN IP). Plain ws is for isolated LAN testing only; Android/network policy may block it. For public use, deploy the server to a provider supporting WebSockets, TLS, a persistent Node process and persistent storage, then enter its **wss://** address. No hosting account or deployment has been provisioned for you. Do not use GitHub Pages or a static Netlify site for this server.

Docker alternative from repository root:

```bash
docker build -f server/Dockerfile -t close-quarters .
docker run -d --name close-quarters -p 8080:8080 -v cq-data:/data --restart unless-stopped close-quarters
```

On a public VPS, configure a TLS reverse proxy with WebSocket upgrade support and a domain; restrict the raw application port to the proxy. On a managed service, use the platform's HTTPS/WSS endpoint and mount a persistent volume at `/data` (or set `DATA_DIR`). `GET /health` returns `ok`; `GET /leaderboard` returns top 50 players. Profile IDs and ranking tokens are saved locally on the phone; server stats are stored in `DATA_DIR/stats.json`. Treat this data as private and back it up. Do not commit it or share tokens. This is single-instance storage, not a production database. For testing multiple server endpoints, clearing app data will reset the local profile token. The server generates a new token for unknown profiles.

## 3 — Play

- Install the same APK on 2–4 ARM64 Android devices. Each player chooses a name, outfit and hairstyle, enters the same server URL, arena and unique room code (3–12 alphanumeric characters). The first player to create the room is host. Host presses Start when at least two players are present.
- Drag on left side to move, drag right side to aim, hold FIRE, tap RELOAD, tap WEAPON to cycle nine weapons. Desktop preview: WASD, right-mouse drag to aim, left click fire, Q weapon, R reload, Escape exit.
- 300-second maximum match. From 60 seconds remaining, the blue safe zone shrinks continuously; being outside drains health. Match can end sooner when only one player survives. If several survive at 300 seconds, highest HP, then kills, then damage, then deterministic ID wins. A simultaneous elimination can end with no survivor. Disconnect during a match counts as elimination.
- Rankings: 100 points per win, 10 participation points for non-winners, 25 per elimination. Server records wins, matches, kills, damage, points. Menu displays top eight, server endpoint top 50. Results return to lobby; leave room and use a new code for another match.

## 4 — Included and limitations

Five distinct single-floor indoor maps remain unchanged in gameplay layout: IT Company, Production Factory, Art Gallery, Residential Building and Hospital. New PBR material maps, procedural detailed props, ceiling lights, articulated 3D characters, outfit colors, hairstyles, animated weapon handling, muzzle flash and death poses. Nine weapons, match timers, rankings and zone mechanics are retained. Server uses simplified planar collision and hit testing; online furniture is scaled to the original box envelope, so visible gaps may still be blocked. Smoke is a visual obscurant. No PUBG assets, code or branding used.

This is an upgraded graphics prototype, not a verified final commercial title or photoreal PUBG-equivalent game. Original models remain stylized, with procedural animation rather than professional skinned characters or motion capture. APK compilation, Godot scene runtime checks, remote asset fetches, actual Android rendering and 4-device multiplayer testing remain unverified. The workflow includes those build-time script and scene checks and a server network integration test. Local rules tests passed 8/8. For production release, commissioned/licensed high-detail humanoid models with skinning and realistic mocap, exact mesh collision, optimization, a persistent signing key, authentication, anti-cheat, moderation, and a production database remain necessary. See ASSET_CREDITS.md for sources and licensing.

## 5 — Development checks

From repository root: `node --test server/engine.test.mjs` (8 tests; no dependencies required). For network integration: `cd server && npm install && node --test integration.test.mjs`. Open `game/project.godot` in Godot 4.4.1 to run desktop preview and edit assets. See https://docs.godotengine.org/en/4.4/tutorials/export/exporting_for_android.html for Android export setup.
