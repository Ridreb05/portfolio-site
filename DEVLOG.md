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

1. **Mobile tap-to-warp likely broken.** `hoverMonitor` is derived from `mouseCurrent`,
   which only updates on `mousemove`/`touchmove` (index.html, mouse tracking block).
   There's no `touchstart` handler that records tap position — it only sets
   `uniforms.uIsTouch.value = 1.0`. A plain tap (no drag) fires `click` while
   `mouseCurrent` is still stale (often screen center), so `hoverMonitor` is false and
   the warp never triggers. Needs a `touchstart` listener that also sets `mouseTarget`
   from the touch position.
2. **No WebGL / load-failure fallback.** `new THREE.WebGLRenderer(...)` isn't wrapped in
   try/catch; no feature detection, no `<noscript>`. If WebGL is unavailable or three.js
   fails to load, visitor gets a black screen + spinner forever, `cursor: none`, no
   error message.
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
- Not yet started: terminal overlay, unlock animation, OS desktop shell, actual
  portfolio content.
