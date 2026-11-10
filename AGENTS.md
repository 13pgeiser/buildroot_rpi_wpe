# AGENTS.md

## What this repo is
- Buildroot-based custom OS images for Raspberry Pi 4/5 (64-bit) running the
  PaG browser (a modified WebKitGTK browser) under Weston (Wayland) in kiosk mode.
- Buildroot is pinned to version `2026.08.1` (`BUILDROOT_VERSION` in `build.sh`) and
  extracted from the committed `buildroot-2026.08.1.tar.xz` into `buildroot-2026.08.1/`.
  That directory is a build workspace — do not hand-edit it; configure via `build.sh` steps
  or the external tree in `pag/`.

## Commands
- Full build: `./build.sh` — runs all steps in order: `buildroot apt defconfig sdk build release`.
- Single step: `./build.sh <step>` with one of `buildroot`, `apt`, `defconfig`, `sdk`, `build`, `release`.
  Unknown steps fail. Step order matters (apt installs host build deps before defconfig/build).
- Clean: `./clean.sh` (removes `buildroot-*`, `ccache-buildroot`, `release`).
- The `apt` step requires sudo and installs host build deps (make, gcc, ncurses, zstd, ...).
- Build output log: `buildroot-2026.08.1/make.log` (build step tees into it).
- Release artifacts: `release/sdcard.img.zst`, `release/squash.img.zst`.

## Layout / non-obvious wiring
- `pag/` is the Buildroot external tree (`BR2_EXTERNAL=../pag` from the buildroot dir).
  `pag/external.mk` includes all `package/*/*.mk`; `pag/Config.in` sources the package.
- Single package: `pag/package/PaGBrowser` (config + C sources). Binary `PaGBrowser` is built
  from `src/Makefile` via `pkg-config gtk4 webkitgtk-6.0` against upstream WebKitGTK 2.46.6
  (built separately via `make.sh`, cmake/ninja on the host).
- Active defconfig is `pag/configs/raspberrypi5_defconfig` — the `raspberrypi4` line in
  `build.sh` is commented out, so builds currently target Pi 5 only.
- Runtime overlay: `pag/rootfs_overlay` (init script `S99PagBrowser`, Weston kiosk config,
  network/wpa_supplicant, `start.sh`).
- Board firmware config/cmdline: `pag/boards/`; disk images via `pag/post-image*.sh` + `genimage-pag*.cfg`.

## Gotchas
- `buildroot-*`, `ccache-buildroot`, and `release/` are gitignored — never commit build
  outputs or the extracted buildroot tree.
- `build.sh` copies `../../wpa_supplicant.conf` into `pag/rootfs_overlay/etc/` if present
  (sibling path, not part of this repo).
- No tests, lint, formatter, or CI workflows exist for this repo itself; verification is a
  full `./build.sh` run.
- `session-ses_*.md` files are OpenCode session logs, not repo documentation.

## Sources of truth
- `build.sh` and `clean.sh` (scripts) override prose docs; `Readme.rst` is the user-facing summary.
