# Dev Sanctuary — Project Log

This file is the running memory for this project: current state, known issues, and
the roadmap. Read this before re-exploring the codebase — update it instead of
letting context live only in chat.

---

## What this project is

A single-file WebGL portfolio site. [index.html](index.html) renders a static bedroom
photo (`hero.png`) through a Three.js fragment shader that layers animated fish in an
aquarium, water caustics, coffee steam, fairy-light throb, PC RGB glow, a cursor-glow
effect, and background YouTube audio. No build tooling — `serve.ps1` is a Windows-only
static file server for local dev.

Files:
- `index.html` — everything (HTML/CSS/shader/JS in one file)
- `serve.ps1` — local dev server (Windows/PowerShell only)
- `hero.png` — main scene image (~5.6MB)
- `monitor.png` — monitor-screen overlay texture, used during hover/warp
- `monitorclose.png` — close-up of the monitor, shown at full warp (`uWarpProgress = 1`)
- `monitorcloseup.png` — **currently unused/unreferenced**, 2.7MB, orphaned from earlier iteration

## The core interaction (as built today)

- Cursor hover near the monitor → glow bloom effect (`uMonitorHover`)
- Click on monitor → `isWarped` toggles → camera zooms/pans into the monitor
  (`uWarpProgress` 0→1), cross-fading from `hero.png` → `monitor.png` → `monitorclose.png`
- Click again (anywhere) while warped → zooms back out

All of this lives in the fragment shader (`FRAG` template string) + a small Three.js
setup script in `index.html`. Shader uniforms of note: `uWarpProgress`, `uMonitorHover`,
`uMouse`, `uLoop` (0..1 periodic, 8s loop), `uTime` (raw elapsed).

## Vision / roadmap (the actual goal)

The site should become a portfolio disguised as a "hack into the OS" experience:

1. User warps into the monitor (existing feature) and lands on `monitorclose.png`.
2. Inside the blank/dark screen area of that close-up, show a **realistic terminal**
   (blinking cursor, typed characters, monospace font, CRT-ish feel).
3. User types `unlock --root` into the terminal.
4. A "cool" unlock animation plays (glitch/boot sequence, or scanline wipe, etc.).
5. The interface goes **fullscreen** and boots into an **OS-like desktop** — custom
   cursor, icons/windows — and that desktop IS the portfolio (projects, about, resume,
   contact, etc. presented as apps/windows/files in this fake OS).

### Implementation notes / open questions for this feature
- Typing text into a fragment shader is painful — the terminal should almost certainly
  be a **real DOM overlay** (HTML input + rendered text, monospace, styled to look like
  a CRT terminal), positioned/faded in over the blank screen region of `monitorclose.png`
  as `uWarpProgress` approaches 1. Need to find the actual pixel/UV rect of the blank
  screen area in `monitorclose.png` to align the overlay div convincingly (check if the
  screen is front-on or angled — may need a CSS transform: perspective to sell it).
- The "boot into OS" step is a distinct, separate full-screen HTML/CSS/JS layer — not
  shader-driven. This is effectively a second, bigger sub-app (fake desktop environment)
  that takes over once "unlocked."
- Real portfolio content (projects, bio, links, resume, contact) does not exist
  anywhere yet — it needs to be authored as part of building the OS desktop UI. This
  should probably be the actual delivery vehicle for that content.
- The unlock animation, terminal fake-command handling (only `unlock --root` needs to
  "work"; everything else can either no-op or give a fake "command not found"), and OS
  shell are all still to be designed/built.

## Known issues / bugs (found in review, 2026-07-19)

1. ~~**Mobile tap-to-warp likely broken.**~~ **FIXED 2026-07-19.** `touchstart` now
   snaps `mouseTarget`/`mouseCurrent` to the tap position and calls a shared
   `updateHoverMonitor()` synchronously (extracted from `tick()`), so a bare tap is
   recognized before the `click` handler runs, no lerp/rAF delay.
2. ~~**No WebGL / load-failure fallback.**~~ **FIXED 2026-07-19.** `#fallback` overlay
   added; `renderer` creation wrapped in try/catch, checks `renderer.getContext()`,
   checks `typeof THREE === 'undefined'`, and hero.png load failure all route to
   `showFallback()` (hides canvas, restores cursor, shows a message + mailto link).
   monitor.png/monitorclose.png failures still degrade silently since the warp is
   optional, not the core scene.
3. **Large, sequential image loads.** `hero.png` (5.6MB) → `monitor.png` (290KB) →
   `monitorclose.png` (1.4MB) load one after another before the loading screen fades:
   >7MB before first paint. Should compress/resize (WebP, downscale to actual display
   res).
4. **`monitorcloseup.png` is dead weight** — 2.7MB, not referenced anywhere in
   `index.html`. Either wire it in or delete it.
5. **No `.gitignore`**, and as of 2026-07-19, `monitor.png`, `monitorclose.png`, and
   `monitorcloseup.png` are untracked, plus `index.html` had ~150 lines of uncommitted
   changes implementing the whole warp feature. Risk of losing this work to a stray
   `git clean`/reset.
6. No SEO/social meta tags (description, Open Graph, favicon).
7. No accessibility affordances — `cursor: none` everywhere, canvas has no ARIA
   fallback/text alternative, no keyboard path for the warp toggle.
8. `serve.ps1` is Windows-only; no cross-platform dev instructions, no `package.json`.
9. Cover-fit/pan UV math is duplicated between the fragment shader and the JS `tick()`
   hover-detection code — a future tweak to one without the other will silently desync
   the hover box from what's actually rendered.
10. No actual portfolio content anywhere yet (name, bio, projects, links, resume,
    contact) — see Vision section above, this is the whole point of the OS-desktop
    feature.

## Session log

### 2026-07-19
- Did a full first-pass review of the project (structure, uncommitted work, bugs,
  perf, a11y, missing content). Findings captured above.
- User shared the vision: monitorclose.png → terminal overlay → `unlock --root` →
  animation → fullscreen OS-style portfolio desktop. Recorded above as the roadmap.
- Fixed the mobile tap-to-warp bug and added a WebGL/load-failure fallback (see
  Known issues #1/#2, both marked FIXED).
- Verified with a Playwright smoke test (installed headless Chromium via
  `pip install playwright` + `playwright install chromium`, since no Node/npm is
  available in this environment — python -m http.server used as the static server
  instead of serve.ps1 for the automated test only): scene renders correctly (fish,
  aquarium, dog, monitor all visible), zero console/page errors, and clicking the
  monitor region successfully warps in to `monitorclose.png`'s blank screen — this is
  the surface the terminal overlay needs to be built on top of.
- Committed as `d4de819`: the warp feature, both bug fixes, `monitor.png` and
  `monitorclose.png` (now tracked), and this DEVLOG.md.
- `monitorcloseup.png` remains untracked and unused — left alone (not deleted) per
  "prefer reversible over destructive"; still needs a decision (wire in or remove).
- Not yet started: terminal overlay, unlock animation, OS desktop shell, actual
  portfolio content.

### 2026-07-19 (cont'd) — Terminal built

Built the terminal overlay end-to-end and verified it live (Playwright, screenshots of
every stage, zero console errors):

- **Screen-rect math solved analytically, not just eyeballed.** Confirmed via the
  fragment shader source that at full warp (`uWarpProgress` → 1) `uCloseTex` is sampled
  with `uvClose = mix((uv-0.5)*1.1+0.5, uv, uWarpProgress)`, which collapses to exactly
  `uv` (the plain cover-fit coordinate) once `uWarpProgress = 1` — the 0.28/0.53/0.35
  "zoom to monitor" (`uvBase`) only ever affects `uTex`/`uMonitorTex` sampling, never
  `uCloseTex`. Confirmed `hero.png`/`monitor.png` (2814×1536, AR 1.832) and
  `monitorclose.png` (2002×1091, AR 1.835) share the same aspect ratio, so at full warp
  the close-up is shown with **plain CSS `background-size:cover` behavior** relative to
  its own pixel dimensions — no perspective/rotation, no mouse/pan dependency (pan is
  zeroed at `uWarpProgress = 1`). This meant the DOM overlay position could be computed
  with a plain cover-fit formula (`positionTerminal()` in index.html) instead of needing
  to reverse-engineer the shader's full transform chain.
- **Measured the screen's pixel rect** in `monitorclose.png` with a small Python/PIL
  script (threshold-scanning for near-black pixels, restricted to the monitor region to
  avoid other dark objects in the shot). True edges: left≈298, right≈1663–1677, top
  noisy 80–106 (a faint reflection streak crosses the screen), bottom≈792–806. Used a
  safely-inset rect `{left:340, top:150, right:1610, bottom:760}` (in the 2002×1091
  source) to clear the curved bezel and the streak — see `SCREEN_RECT` in index.html.
- **Built:** `#terminal` (monospace, scanline overlay, blinking cursor block, real
  hidden `<input>` overlaying the whole box so mobile gets a native keyboard), a fake
  shell (`guest@dev-sanctuary:~$`, unknown commands print `command not found: X`),
  `unlock --root` as the one working command, a boot-line sequence + CSS glitch
  keyframe, and `#os-boot` — a fullscreen placeholder ("DEV-SANCTUARY OS / booting
  desktop environment…") that stands in for the real desktop shell.
- **Wired to warp state**, not to clicks directly: `tick()` calls
  `activateTerminal()`/`deactivateTerminal()` on `uWarpProgress` crossing 0.92 (show) /
  0.5 (hide), with hysteresis so it doesn't flicker mid-animation. Exiting warp (click
  outside the terminal, or Escape — added an Escape-to-exit-warp handler too) fully
  resets terminal/boot state, so the flow is repeatable without a page reload.
- Terminal clicks call `e.stopPropagation()` (same pattern as the music button) so
  focusing the input doesn't bubble up and trigger the window's click-to-exit-warp
  handler.
- Verified: scene renders, warp-in aligns the terminal precisely inside the screen
  bezel, bad commands show the error line, `unlock --root` runs the full boot → glitch
  → fullscreen OS-boot transition, and clicking the OS-boot placeholder resets cleanly
  back to the normal scene. Zero console/page errors throughout.

### Next up
- **The actual OS desktop is the big remaining piece** — `#os-boot` is currently just a
  placeholder ("booting desktop environment…"); it needs to become a real fake-desktop
  UI (custom OS-style cursor, icons/windows) that IS the portfolio content.
- No real portfolio content exists yet (bio, projects, resume, contact) — this still
  needs to be authored, presumably as "apps"/"files" in the desktop shell.
- Minor polish candidates carried over from the first review, still open: compress
  `hero.png`/`monitorclose.png` (large), decide fate of unused `monitorcloseup.png`,
  add SEO/meta tags, accessibility pass.
