# iRacing Stutter Fix — AMD Ryzen X3D + NVIDIA

A field-tested troubleshooting guide for eliminating frame-time spikes (stutters) in
iRacing on AMD Ryzen 7000/9000 **X3D** systems paired with NVIDIA GPUs on Windows 11.

The guide is symptom-first: you capture a session with [CapFrameX](https://www.capframex.com/),
identify **which kind** of stutter you have, and only then apply the matching fix — instead
of blindly toggling settings.

## What's here

| File | What it is |
|------|------------|
| [`index.html`](index.html) | Landing page — overview, results, prioritized fix list |
| [`guide.html`](guide.html) | The full guide — decision tree, fixes A–F, checklists, revert reference |
| [`progress.html`](progress.html) | Capture-by-capture research log |
| [`find_my_values.bat`](find_my_values.bat) | Run **once** at setup — prints your machine-specific values (read-only) |
| [`pre_iracing_launch.bat`](pre_iracing_launch.bat) | **Template** to run before racing — customize three values, then run as admin |
| [`pre_iracing_launch_example.bat`](pre_iracing_launch_example.bat) | The author's real filled-in script — reference only, won't work as-is on your system |
| [`post_iracing_session.bat`](post_iracing_session.bat) | Run **after** racing — restarts the background services the pre-launch script stopped |

**Live guide:** https://rcsracing93.github.io/iracing-stutter-fix/ — or open the HTML files directly in a browser.

## Using the scripts

> [!WARNING]
> The pre-launch script makes aggressive, temporary changes for a racing session: it
> **disables Windows Update**, **suspends Windows Defender real-time monitoring**
> (requires Tamper Protection off), stops background services, and closes apps such as
> OneDrive and Chrome. **Run `post_iracing_session.bat` afterward** to restart the
> services — note it does **not** re-enable Defender real-time monitoring, so confirm
> Defender is back on after your session.

1. Run [`find_my_values.bat`](find_my_values.bat) once. It prints your NVIDIA device
   instances, AMD power-plan GUID, and driver version (it changes nothing).
2. Open [`pre_iracing_launch.bat`](pre_iracing_launch.bat) and replace the three
   `=== CUSTOMIZE ===` values with what you found. Use
   [`pre_iracing_launch_example.bat`](pre_iracing_launch_example.bat) as a reference for a
   complete, filled-in script.
3. Run the scripts **as Administrator**: `pre_iracing_launch.bat` before you race,
   `post_iracing_session.bat` when you're done.

## Notes

This is a community guide based on real capture data. Results vary by hardware and
configuration — read the guide and understand each change before applying it. A revert
reference for every change is included at the end of [`guide.html`](guide.html).
