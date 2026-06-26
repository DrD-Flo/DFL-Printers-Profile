# DFL-Printers-Profile

Vendor configuration bundle for **Digital Fabrication Lab** printers, distributed to
[SuperSlicer DFL](https://github.com/DrD-Flo/SuperSlicerDFL) clients.

This repo is the **live auto-update source** for the DFL-Printers vendor profile. The SuperSlicer DFL
app polls this repo's **git tags** via the GitHub API (configured by
`config_update_github = <owner>/DFL-Printers-Profile` in the bundled `DFL-Printers.ini`) and offers
users any newer config version.

> The app also ships a **bundled copy** of `DFL-Printers.ini` (the offline/first-run baseline) from the
> SuperSlicer DFL profiles submodule — that's a separate, app-side concern. This repo drives the
> **online updates** on top of that baseline. No internet is needed to use the bundled baseline.

## Layout
```
description.ini            # [vendor] id = DFL-Printers
publish.sh                # release helper (use this — see below)
profiles/
  DFL-Printers.ini         # the vendor bundle (its config_version is the INSTALLED version)
  DFL-Printers.idx         # version index / changelog lines
  DFL-Printers/            # printer-model thumbnail PNGs
```

## Publishing a new config version

**Use the script** — it keeps the two version numbers in sync (see the rule below):

```bash
./publish.sh <config_version> ["changelog message"]

./publish.sh 2.5.0 "new ASA profile"     # bump + commit + tag 2.5.0=2.7.61.0 + push
./publish.sh 2.5.1 --no-push             # stage locally, don't push
./publish.sh 2.5.2 "x" --slicer 2.7.61.0 # override the min slicer version (tag right-side)
```

`publish.sh` sets `config_version` in `profiles/DFL-Printers.ini`, prepends a line to
`profiles/DFL-Printers.idx`, commits, creates the tag `<config_version>=<min_slicer_version>`, and
pushes. It validates the version, refuses a duplicate tag, and the tag's version always equals the
`.ini` `config_version` by construction.

### ⚠️ The one rule: the git tag and `config_version` MUST match

The updater reads the **offered** version from the **tag name** (`<config_version>=<min_slicer_version>`)
but the **installed** version from `config_version` **inside the downloaded `.ini`**. If they drift —
e.g. a tag `2.4.8` whose committed `.ini` still says `2.4.7` — the upgrade installs the lower number, so
it never "sticks": the upgrade button appears to do nothing and the app keeps re-offering the update.

**Always publish with `publish.sh`. Do not create tags by hand.** (If you must do it manually: bump
`config_version` in the `.ini`, commit, then tag `<that exact config_version>=2.7.61.0`.)

### Tag format

`<config_version>=<min_slicer_version>`, e.g. `2.5.0=2.7.61.0`.

- **left side** = the config version (must equal the `.ini` `config_version`).
- **right side** = the minimum SuperSlicer DFL version that may receive it; keep at `2.7.61.0` (matches
  `min_slic3r_version` in the `.idx`) unless a profile genuinely requires a newer app.

Clients pick the highest `config_version` among tags whose `min_slicer_version` is `<=` the running app,
and prompt to update if it's newer than what they have installed.

## Notes

- The repo must stay **public** — the app fetches unauthenticated. GitHub allows 60 API requests/hour
  per IP unauthenticated (and the app self-throttles to 25/hour), which is ample for normal use but can
  be exhausted by heavy back-to-back testing ("Too many requests" → wait an hour / relaunch the app).
- Users get the prompt on their next launch with internet (the app re-polls tags at most ~once/day per
  vendor); offline users keep their current config and update when next online.
