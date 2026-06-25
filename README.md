# DFL-Printers-Profile

Vendor configuration bundle for **Digital Fabrication Lab** printers, distributed to
[SuperSlicer DFL](https://github.com/DrD-Flo/SuperSlicerDFL) clients.

This single repo is the source of truth for the DFL-Printers vendor profile. It serves both:

- **Build-time bundling** — `download_vendor_bundles.py` in SuperSlicer DFL clones this repo and bakes
  `profiles/DFL-Printers.ini` into the packaged app, so the profile ships with every install
  (works fully offline).
- **Live auto-update** — the app's preset updater polls this repo's **git tags** via the GitHub API
  (`config_update_github = DrD-Flo/DFL-Printers-Profile` in the `.ini`), and offers users newer config
  versions. No internet is required to use the bundled baseline; updates are an online top-up.

## Layout
```
description.ini            # [vendor] id = DFL-Printers   (read by download_vendor_bundles.py)
profiles/
  DFL-Printers.ini         # the vendor bundle
  DFL-Printers.idx         # version index (changelog lines)
  DFL-Printers/            # printer-model thumbnail PNGs
```

## Publishing a new config version
1. Edit `profiles/DFL-Printers.ini` and bump `config_version` (e.g. `2.4.3` -> `2.4.4`).
2. Add a matching changelog line to the top of `profiles/DFL-Printers.idx`.
3. Commit and push:
   ```bash
   git add -A
   git commit -m "DFL-Printers 2.4.4: <what changed>"
   git push
   ```
4. Tag the release as `<config_version>=<min_slicer_version>` and push the tag — this is what the
   updater reads:
   ```bash
   git tag '2.4.4=2.7.61.0'
   git push origin '2.4.4=2.7.61.0'
   ```
   The `min_slicer_version` half gates which app builds receive it; keep it at your minimum supported
   SuperSlicer DFL version (matches `min_slic3r_version` in the `.idx`).

Clients pick the highest `config_version` among tags whose `min_slicer_version` is <= the running app,
and prompt to update if it is newer than what they have installed.

> The repo must stay **public** (the app fetches unauthenticated). GitHub's API allows 60 requests/hr
> per IP unauthenticated, which is ample for normal use.
