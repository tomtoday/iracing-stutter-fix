# iRacing Stutter Fix — AMD Ryzen X3D + NVIDIA

A field-tested troubleshooting guide for eliminating frame-time spikes (stutters) in
iRacing on AMD Ryzen 7000/9000 **X3D** systems paired with NVIDIA GPUs on Windows 11.


## What's here

| File | What it is |
|------|------------|
| [`index.html`](index.html) | Landing page — overview, results summary, script downloads |
| [`guide.html`](guide.html) | The full guide — diagnostic decision tree, fixes A–F, checklists, revert reference |
| [`progress.html`](progress.html) | Capture-by-capture research log |
| [`pre_iracing_launch.bat`](pre_iracing_launch.bat) | Run **before** racing — applies the optimizations |
| [`post_iracing_session.bat`](post_iracing_session.bat) | Run **after** racing — restores everything the pre-launch script changed |

**Live guide:** https://rcsracing93.github.io/iracing-stutter-fix/ — or open the HTML files directly in a browser.

## Using the scripts

> [!WARNING]
> The pre-launch script **disables Windows Update** and **adds Windows Defender
> exclusions** for iRacing, and stops a number of background services. This is fine for a
> racing session, but you should **always run `post_iracing_session.bat` afterward** to
> re-enable updates and services. Leaving Windows Update disabled indefinitely is a
> security risk.

1. The scripts contain **system-specific values** (NVIDIA device IDs, AMD power-plan GUID,
   driver version). Edit the `CONFIG` block at the top of `pre_iracing_launch.bat` with
   your own values before first use — see the guide for how to find each one.
2. Run both scripts **as Administrator**.
3. `pre_iracing_launch.bat` before you race; `post_iracing_session.bat` when you're done.

## Notes

This is a community guide based on real capture data from one system. Results vary by
hardware and configuration — read the guide and understand each change before applying it.
A revert reference for every change is included at the end of [`guide.html`](guide.html).
