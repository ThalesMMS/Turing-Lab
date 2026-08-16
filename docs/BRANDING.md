# Turing Lab Brand Identity

Turing Lab is the canonical product and project name.

Use the following identifiers in maintained code and release configuration:

| Surface | Canonical value |
| --- | --- |
| Product name | `Turing Lab` |
| Dart package | `turing_lab` |
| Dart identifier prefix | `TuringLab` / `turingLab` |
| Desktop binary | `turing_lab` |
| Android application ID | `thalesmms.turinglab` |
| Apple bundle ID | `thalesmms.turinglab` |
| Public repository | `https://github.com/ThalesMMS/Turing-Lab` |
| GitHub Pages | `https://thalesmms.github.io/Turing-Lab/` |
| Offline examples | `assets/examples/` |
| Release and QA environment prefix | `TURING_LAB_` |

## Compatibility-only legacy references

The former project name may appear only where changing it would falsify a
historical record or break a live external locator:

- The development repository slug remains `ThalesMMS/Turing-Lab-dev`.
- `release/APP_STORE_CONNECT_RECORDS.md` records the pre-rename App Store
  Connect app, bundle ID, SKU, and artifacts.
- Dated QA records may retain the exact pre-rename bundle IDs and artifact
  names that were observed during those runs.
- The existing Android upload certificate retains its original subject common
  name. Certificate identity is immutable; replacing that text would require a
  signing-key migration, so it is not current product branding.

These values are compatibility locators or historical evidence, not current
branding. Update them only after the corresponding external resource is
migrated, and update every inbound reference in the same change.

Run `./tool/check_branding.sh` before review. CI runs the same check and rejects
the former name in tracked paths or outside the compatibility cases above.
