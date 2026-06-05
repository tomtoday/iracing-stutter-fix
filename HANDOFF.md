# Handoff — iRacing stutter-fix UX work

Working context for resuming on a Windows PC. **Not part of the guide** — keep this
file out of the upstream PR (see "Git" below).

## North star
Make the guide easier to follow for "future me a year from now," and ship two things:
1. A **clean PR to upstream** (`rcsracing93/iracing-stutter-fix`) with generic, non-editorial improvements.
2. A **personal branch** on the fork with rig-specific customizations (never PR'd).

## Git setup
- `origin` = `tomtoday/iracing-stutter-fix` (your fork — push here)
- `upstream` = `rcsracing93/iracing-stutter-fix` (fetch only; push URL set to `DISABLE`)
- `main` tracks `origin/main`
- Working branch: **`ux-enhancements`** (the PR branch)
- **Rules I follow:** never run git/`gh` commands that mutate state — I propose the exact
  command, you run it. No `Co-Authored-By` lines in commits.
  ⚠️ These rules live in `~/.claude/CLAUDE.md` on the Mac and **won't transfer to the PC** —
  recreate them there if you want the same behavior.

## Done (on `ux-enhancements`)
- **README.md** — overview, file table, live-site + CapFrameX links, safety warning.
- **pre_iracing_launch.bat** — all per-machine values hoisted into one `CONFIG` block;
  fixed a real bug (instance IDs had `^&` carets *inside quotes* → reg targeted bogus
  keys; now expanded from CONFIG vars so the real key is hit); affinity apply is now a
  loop over instances; expanded `NV_CPU_MASK` docs.
- **guide.html Section 05** — added "Choosing your target core" + "Computing the
  AssignmentSetOverride mask" (SMT pairing, `1 << cpu`, AutoGpuAffinity, little-endian
  warning for CPU 8+).
- **find_my_values.bat** — new read-only helper that prints the CONFIG values
  (NV_BASE/instances, driver, POWER_GUID) + CPU topology hint. Wired into README.
- **guide.html UX** — hover-`#` permalink anchors on every heading (auto-ids for
  subsections); "← Overview" back-link to index; back-to-top button; smooth scroll;
  removed the dead "upload the JSON file here" line; linkified ~30 "Section NN"
  cross-references into clickable anchors.

## Decisions
- Deliverable = **both** (PR + personal branch).
- Script values = **single CONFIG block** with example/placeholder values + `find_my_values.bat`.
- Affinity **reframe** (demoting it as experimental) = **personal branch only**, not the PR.
- **Declined** (deemed editorial, out of scope): fixing index.html worst-frame-time number
  (`8.80ms`/`↓67%` math mismatch) and verifying the app.ini keys (`carPreloadAll` etc.)
  are real. Focus is follow-ability, not results accuracy.

## ⚠️ NEEDS WINDOWS TESTING (do first on the PC)
The `.bat` files were written/edited on macOS and have **not run**. Verify:
1. **find_my_values.bat** — run (ideally as admin). Confirm the PowerShell one-liners
   parse, `NV_INST*` lists your GPU's registry instances, and `POWER_GUID` is extracted.
2. **pre_iracing_launch.bat** — run as admin, then `reg query` one affinity key to confirm
   `DevicePolicy` / `AssignmentSetOverride` / `DevicePriority` landed on the **real**
   device key (this validates the caret-bug fix). Then LatencyMon to confirm DPC load
   moved to the target CPU, not CPU 0.
3. Confirm the **for-loop quoting** in the affinity section applies to all instances.
4. If you ever target **CPU 8+**, sanity-check the little-endian claim (CPU 8 = `0001`,
   not `0100`) with `reg query` + LatencyMon.

## Remaining work
**PR branch (`ux-enhancements`):**
- Apply any fixes that fall out of Windows testing.
- Push to fork; open PR `tomtoday:ux-enhancements` → `rcsracing93:main`.

**Personal branch (create off `ux-enhancements`):**
- Drop `progress.html` and remove its card/links from `index.html`.
- Reframe Section 05 affinity as experimental + add a TL;DR of the *proven* fixes
  (graphics settings, disabling services, removing RTSS).
- Fill the CONFIG block with your real values (run `find_my_values.bat`).

## Key technical notes
- iRacing's sim thread is pinned to **CPU 0**; goal is to move GPU interrupts to a
  different **physical** core (default CPU 4). EAC blocks process-affinity changes, so
  this is done via interrupt affinity, not process affinity.
- `AssignmentSetOverride` is `REG_BINARY`, **little-endian**: CPU 0–7 = one byte (`1<<cpu`
  → `01/02/04/.../80`); CPU 8+ = multi-byte LE (easy to get wrong by hand — let
  AutoGpuAffinity write it).
- Win11 MSI-mode affinity is unreliable; the progress log itself called interrupt affinity
  "unresolved" — which is why the reframe (personal branch) demotes it relative to the
  fixes that demonstrably worked.
