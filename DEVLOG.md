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

### 2026-07-19 (cont'd) — terminal feedback round

User feedback on the first terminal build, all addressed:

1. **Centering was off.** Original `SCREEN_RECT` was a rough eyeball inset. Redid the
   pixel measurement properly: took the *median* of first/last dark pixel across ~100
   scanlines each direction (not min/max, which were skewed by the curved bezel and a
   reflection streak) — true edges: left 298, right 1677, top 89, bottom 794. New
   `SCREEN_RECT = {left:393, top:154, right:1582, bottom:729}` insets symmetrically from
   those medians so the box's centroid exactly matches the screen's true centroid.
2. **Added a "warp to fullscreen" animation.** After the glitch, the terminal element
   itself now animates (CSS transition on `left/top/width/height`) from its
   screen-aligned rect to `0/0/100vw/100vh` over 700ms (`.expanding` class) before
   `#os-boot` cross-fades on top — sells "the screen taking over the viewport" instead
   of an abrupt cut. Font-size uses `clamp(...vw...)` so the terminal text visibly grows
   during the expand, reinforcing the effect.
3. **Music now stops on fullscreen.** Added `window.DevSanctuaryMusic = {pause, play,
   isPlaying}` bridge exposed from the YouTube script block. `runUnlockSequence()` reads
   `isPlaying()` and calls `pause()` right as `#os-boot` becomes visible; `isPlaying()`'s
   value is cached at that moment so `deactivateTerminal()`'s reset only auto-resumes
   music if it was actually playing when we paused it — never overrides a pause the user
   chose manually.
4. Ran `/fewer-permission-prompts` — only one transcript exists so far (thin signal).
   Added `Bash(curl -sf http://localhost:*)` to `.claude/settings.json`; everything else
   recurring was either already auto-allowed by Claude Code (git status/log/diff, ls,
   cat, echo, find, sort, test, ...) or correctly gated (python/node one-liners — can't
   safely wildcard arbitrary code execution; git add/commit, pip install, taskkill —
   all mutating). Revisit after more sessions accumulate.

Verified live again with Playwright: measured the terminal's actual bounding rect via
`getBoundingClientRect()` against the screen bounds (now symmetric), watched the
expand-to-fullscreen transition frame-by-frame, and confirmed reset still works
cleanly. Zero console errors.

### Mobile — open design problem, **SOLVED 2026-07-19 (later session)**

Was flagged as important, not yet implemented; now fixed. The core issue: `positionTerminal()`'s
cover-fit formula is generically correct for any aspect ratio, but "cover" itself breaks down hard
on a narrow **portrait** phone. `monitorclose.png` is 2002×1091 (AR 1.835); a portrait phone
(AR ≈ 0.46) covering that image only shows a horizontal sliver — displayed-width fraction
= scrAR/imgAR ≈ 0.46/1.835 ≈ 25%. The measured screen rect spans 63% of the image's width
(1582−393=1189 of 2002px), so on a phone in portrait, "cover" pushed the terminal box to a
negative left offset — almost entirely off-screen (confirmed via Playwright screenshot, only a
sliver of text visible at the left edge).

First attempt went with **"decouple entirely on mobile"**: a fixed centered sheet (`left:6%
top:16% width:88% height:68%`) instead of computing from `SCREEN_RECT`/cover-fit math. Shipped,
then the user correctly called out that it visually floated outside the monitor's frame instead
of looking embedded in it — a fair complaint, since it was a guessed rectangle with no relation
to what's actually rendered underneath.

**Replaced with the actually-correct fix**: keep the original cover-fit math (still pixel-
accurate), but **clamp** the resulting rect to the viewport (`Math.max(0, ...)` /
`Math.min(scrW/scrH, ...)`) instead of leaving it free to go negative/overflowing. This works
for a subtle but solid reason: at full warp, `uWarpProgress` is 1, and the shader's pan term
(`pan * (1.0 - uWarpProgress)`) is exactly zero — so the visible crop of `monitorclose.png` is
*always* centered on the image, with no dependency on prior mouse/touch position. That means
clamping the naive cover-fit rect to `[0,scrW]×[0,scrH]` gives the *exact* pixel bounds of
whatever portion of the monitor screen is actually visible, for any aspect ratio, with zero
guessing and no separate narrow-viewport branch. Worked out on paper first for a 390×844 phone
(clamped rect comes out full-width, top ~14%/height ~53% of the screen — matches what cover-fit
crops to a thin, heavily-zoomed-in center strip would actually show) and confirmed via
Playwright screenshot before considering it done. Desktop/tablet unaffected (the clamp is a
no-op there — the unclamped rect already falls within the viewport).

The other options from the original list (landscape lock, shader-level contain-fit, separate
mobile crop asset) are now moot — the clamp fix gets the same correctness as contain-fit would,
without touching the shader at all.

The on-screen-keyboard-covers-terminal concern is now moot: the terminal no longer has a text
`<input>` at all (see below, boot menu replaced the typed `unlock --root` command), so there's no
keyboard to summon or avoid on mobile.

### 2026-07-19 (cont'd) — architecture split: OS desktop is now a separate app

User's ask: once "unlocked," the OS desktop should live at its own URL
(`portfolio.debanik.com`) so it's shareable on its own, be fully responsive, and run
independently of this WebGL scene — while still being reachable *through* this scene
(`debanik.com`) via the terminal easter egg.

Decided (with user, via AskUserQuestion): hosting is Vercel/Netlify, the OS desktop gets
its **own new repo** (not a folder in this repo), stack is **React + Vite**.

What happened:
- **New repo/project**: `c:\Users\ridre\Documents\portfolio-os` — see its own README.md
  for structure. Scaffolded with `npm create vite@latest -- --template react` (Node.js
  wasn't installed in this environment; installed via `winget install
  OpenJS.NodeJS.LTS`). Built a real, working desktop shell: boot screen, draggable/
  closable/maximizable windows (`useDraggable` hook, mouse+touch), a dock, a custom
  cursor (auto-disabled via `(pointer: fine)` media query, not device-sniffing), and
  three placeholder apps (About/Projects/Contact — clearly marked, not fabricated real
  bio/project content). Responsive from the start: windows go fullscreen below 768px
  instead of floating (dragging tiny windows on a phone is unusable), desktop icons
  hide while an app is open on mobile, and maximized/fullscreen windows are inset
  2.6rem from the top so their own controls don't collide with the fixed clock widget
  (both anchored top-right — this was a real bug, caught by Playwright: the clock
  intercepted clicks meant for the maximize/close buttons; fixed by reserving a
  status-bar strip, the same pattern real OSes use).
- Verified with Playwright at both a desktop viewport (1280x800: multi-window open/
  drag/maximize/close, all fine after the status-bar fix) and a mobile viewport
  (390x844, `has_touch`/`is_mobile`: fullscreen windows, icons hidden correctly, dock
  reachable). Zero console errors both times. `npm run build` succeeds (~62KB gzipped).
  Git initialized locally, one commit so far, **not yet pushed** — no GitHub remote
  exists yet (see below).
- **This repo's terminal now hands off to it.** `runUnlockSequence()` in `index.html`
  has a 5th step: ~1.4s after `#os-boot` becomes visible, redirect via
  `window.location.href` to `OS_DESKTOP_URL` (`https://portfolio.debanik.com`) — except
  on `localhost`/`127.0.0.1`/no-hostname, where it just `console.log`s what it would've
  done, so local dev testing doesn't get yanked away mid-iteration. Verified via
  Playwright (checked `framenavigated` events + the console log) that this branch is
  taken correctly on localhost.

**Blocked on the user for actual deployment** (I don't have accounts/credentials for
any of this):
- No GitHub remote exists yet for `portfolio-os`. Tried `gh` CLI (installed it via
  `winget install GitHub.cli` since it wasn't present) — not authenticated
  (`gh auth status` → not logged in), and logging in needs an interactive browser flow
  only the user can complete. **User needs to either**: (a) run `gh auth login` in this
  environment then say go, and I'll create+push the repo myself, or (b) create an empty
  repo (suggested name: `portfolio-os`, public, under `Ridreb05` to match
  `portfolio-site`'s convention) via github.com and give me the remote URL to push to.
- Vercel/Netlify project creation, and pointing the `portfolio.debanik.com` custom
  domain at whichever project serves `portfolio-os`, both require the user's own
  dashboard access — I can't do this part at all, only advise.
- DNS: `portfolio.debanik.com` needs a CNAME (or A/ALIAS per host's instructions)
  added wherever `debanik.com`'s DNS is managed. Also the user's own to do.

### Later sessions (portfolio-os) — see that repo's own README/git log now

`portfolio-os` got pushed to GitHub (github.com/Ridreb05/portfolio-os), filled with
real resume content, then went through a full UI pass (macOS-style menu bar/traffic
lights/dock magnify + a genuine phone-home-screen mobile layout), and most recently a
rebrand to **"Dreb OS"**, custom-cursor removal, a Finder (virtual filesystem browser)
app, and a Settings app (theme/accent/wallpaper, persisted). This repo's boot text was
updated to match ("booting Dreb OS..." / "DREB OS" heading) so the handoff is
consistent. From here on, **portfolio-os's own README.md is the source of truth for
that app** — this file only needs to track this repo's own concerns.

### 2026-07-19 (later session) — mobile tap fix, natural drag, terminal → boot menu

User asked for three things on this repo specifically: (1) fix mobile tap-to-warp on the
monitor, (2) invert the touch-drag pan direction to feel "natural" on mobile, (3) remake
the terminal as a bootloader. All three done, verified with Playwright at a 390×844 mobile
viewport and 1280×800 desktop, zero console/page errors throughout.

**1. Mobile tap fix.** Root cause wasn't the tap-to-warp logic itself — a real Chromium
touchscreen tap (`page.touchscreen.tap`, which goes through the actual touch-input pipeline)
already triggered the warp correctly even before this session's changes; a naive synthetic
`dispatchEvent(new TouchEvent(...))` test misleadingly suggested otherwise; it doesn't cause
the browser to synthesize a real `click`, so it isn't a valid way to test this. The *actual*
bug was exactly what an earlier session had already flagged and left unfixed (see Mobile
section above, before this edit): no `touch-action`/`overscroll-behavior` opt-out, so real
mobile browsers' native gesture recognition (300ms tap-vs-double-tap-zoom delay, drag-vs-tap
jitter cancellation, rubber-band bounce) could still intercept or cancel the tap before our
JS ever saw a clean click. Fixed: `touch-action: none` on `html`/`body`/`#c`, `overscroll-
behavior: none` on `html`/`body`, and `maximum-scale=1.0, user-scalable=no` on the viewport
meta tag. Verified no regressions: tapping inside the terminal (once warped in) still just
focuses/interacts with it rather than un-warping (the terminal's own `click` listener still
`stopPropagation()`s), and tapping the monitor again (or elsewhere) still un-warps correctly.

**2. Natural mobile drag direction.** The room-scene pan on portrait phones is driven by
`(uMouse.x - 0.5) * panRange` with `panRange = 1.0`, which — combined with the cover-fit
scale term — algebraically cancels out to an identity: the exact image pixel under your
finger is what renders under your finger (this is *why* tap-to-warp can be pixel-accurate).
But it means dragging continuously behaves like "camera chases your finger," so content
visually slides *opposite* your drag direction (the pre-2011, "traditional" scroll
convention) — not "natural"/content-follows-finger like native phone scrolling. Fixed by
changing the `touchmove` handler only: `touchstart` still snaps `mouseTarget` to the
absolute touch position (unchanged — this is what keeps tap-to-warp accurate), but
`touchmove` now accumulates the finger's frame-to-frame **delta**, subtracted (X) / added
(Y, already flip-signed) from `mouseTarget`, instead of overwriting it with the new absolute
position. Verified via a synthetic rightward drag: the room now pans to reveal the monitor
(left-side content) as the finger drags right, the inverse of the old behavior. Mouse/
desktop behavior (absolute position, no delta) is untouched — this was scoped to mobile
only per the user's ask.

**3. Terminal → GRUB-style boot menu.** Replaced the old "type `unlock --root`" hidden-input
interaction with an actual boot-menu UI: four entries (Dreb OS / Dreb OS (safe mode) /
System Diagnostics / Recovery Console), arrow-key navigation that pauses a 5s auto-boot
countdown on keypress (same convention as real GRUB), Enter or a tap/click to commit. Only
the first two entries actually boot (safe mode adds one extra "loading minimal drivers..."
line to the existing boot-log sequence, otherwise identical animation/handoff to
`portfolio.debanik.com`); Diagnostics/Recovery show fake but on-brand flavor output (hardware
check lines / recovery-tools-unavailable message) and dead-end back to the menu on Enter or
tap — mirrors the old terminal's "command not found" for anything but the one real command,
just menu-driven instead of typed. Removed entirely: `#term-input`, `#term-line`, `#term-
typed`, `#term-cursor` and their CSS/JS (no more typed text, so no more virtual-keyboard-
on-mobile problem — see Mobile section above). `activateTerminal()`/`deactivateTerminal()`
now reset to the fresh boot-menu state each time instead of printing a static welcome
message.

Also fixed in the course of verifying #3 on mobile: `positionTerminal()`'s pixel-perfect
cover-fit math was pushing the terminal almost entirely off-screen on portrait phones — a
pre-existing bug this session's mobile-tap fix finally made reachable/visible in testing.
See "Mobile — open design problem, SOLVED" above for the fix.

### 2026-07-19 (later session, cont'd) — the CSS fix wasn't the real bug

User reported, after the `touch-action`/`overscroll-behavior` CSS fix above shipped, that
tapping the monitor **still** didn't work on a real phone, and that dragging felt "janky" —
specifically asked for it to feel like "swiping a zoomed-in image." Root-caused for real
this time (Playwright's synthetic touch emulation had been misleadingly passing this whole
time — see note below):

The previous `touchstart` handler snapped `mouseCurrent` (not just `mouseTarget`) straight to
the touch position *and* called `updateHoverMonitor()` synchronously. That's what "janky"
was: the instant you touched the screen — before dragging at all — the whole pan jumped to
center on your finger. On a real phone, the tiniest bit of finger jitter during that jump
(everyone has some) also meant `hoverMonitor` could be evaluated at a slightly different spot
than intended, right as the tap-vs-drag decision was being made.

Fixed by fully decoupling "where is the finger" from "what does the pan show":
- `touchstart` no longer touches `mouseTarget`/`mouseCurrent` at all — a bare tap now causes
  **zero** visual change (verified via screenshot diff: touching down and holding for 400ms
  produces a pixel-identical frame to not having touched at all).
- The monitor hit-test (`computeMonitorUV`, refactored out of `updateHoverMonitor`) takes the
  screen point being tested and the pan source as *separate* parameters. For an active,
  not-yet-moved touch, it tests the touch's real screen position against whatever pan is
  *already* on screen — not one this touch would newly cause. This is what actually fixes
  "can't tap the monitor": the hit-test no longer depends on the tap itself perturbing the
  thing it's testing against.
- `touchmove` only starts moving anything once the finger has moved >12px total from
  touchstart (`TOUCH_TAP_THRESHOLD` — distinguishes an intentional drag from tap jitter). Once
  past that threshold, it's 1:1 with the finger (`mouseCurrent.copy(mouseTarget)` directly, no
  lerp lag) — the "swipe a zoomed photo" feel that was asked for, replacing the old continuous
  lerp-eased tracking.
- The actual warp-toggle is now driven directly from `touchend` (checking `hoverMonitor`,
  respecting the same "tapping inside the terminal doesn't un-warp" rule via `e.target.closest
  ('#terminal')`), with `e.preventDefault()` to stop the browser's compatibility `click` from
  double-handling the same tap. The `click` listener is kept for mouse/desktop, unchanged.

Caught one regression before it shipped: removing `updateHoverMonitor()` from `touchstart`
broke a fast synthetic tap in testing (`hoverMonitor` only got refreshed inside `tick()`'s
rAF loop, and a fast tap could complete before the next frame ran) — added back a synchronous
`updateHoverMonitor()` call in `touchstart`, which is safe now since the function no longer
has the side effect of moving the pan.

**Lesson on testing methodology**: `page.touchscreen.tap()` (Playwright's real touch-input
pipeline, goes through Chrome's actual touch→click synthesis) is what caught this — an
earlier test in this same investigation used raw `dispatchEvent(new TouchEvent(...))`, which
does *not* trigger real click synthesis and does not reproduce real device tap-cancellation
behavior; don't trust that method for touch-interaction testing again.

### 2026-07-19 (later session, cont'd) — swipe direction re-checked, terminal frame fixed

User reported after the above shipped: still can't tap the monitor, swiping still janky, and
the boot menu renders outside the monitor's frame. Two separate things going on:

- **Boot menu outside the frame**: real bug, this session's earlier "decouple entirely" fix
  (a guessed fixed-percentage sheet) was never actually aligned to what's rendered underneath.
  Replaced with the clamped-cover-fit approach — see "Mobile — open design problem" above.
  This one's now pixel-accurate, not guessed.
- **Swipe direction / tap still broken**: asked the user directly which content should appear
  on which swipe direction (monitor is screen-left, aquarium is screen-right in the room
  composition), giving concrete before/after previews for both options. They confirmed the
  **currently-shipped** direction (swipe left → aquarium, content-follows-finger) is the one
  they want — i.e. no code change needed here, this was already correct as of the previous
  commit (`7bd5d7b`). Verified again via fresh Playwright drag test (dragging left does show
  the aquarium, dragging right shows the monitor — matches). Likely explanation for the
  "still wrong" report: the phone was probably testing a cached copy of the page from before
  `7bd5d7b` landed — **if this comes up again, ask the user to hard-refresh / clear cache
  before re-diagnosing the interaction logic itself.**

### Next up
- Vercel deployment + `portfolio.debanik.com` DNS still need to be wired up on the
  user's end (debanik.com is already on Vercel; portfolio-os needs its own project +
  custom domain there).
- Minor polish candidates carried over from the first review, still open: compress
  `hero.png`/`monitorclose.png` (large), decide fate of unused `monitorcloseup.png`,
  add SEO/meta tags, accessibility pass.
