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
| Public web app | `https://thalesmms.github.io/Turing-Lab/` |
| Public marketing page | `https://thalesmms.github.io/Turing-Lab/marketing.html` |
| Public support | `https://thalesmms.github.io/Turing-Lab/support.html` |
| Public privacy policy | `https://thalesmms.github.io/Turing-Lab/privacy.html` |
| Offline examples | `assets/examples/` |
| Release and QA environment prefix | `TURING_LAB_` |

## Compatibility-only legacy references

The former project name may appear only where changing it would falsify a
historical record or break a live external locator:

- The development repository slug remains `ThalesMMS/Turing-Lab-dev`.
- Dated QA records may retain the exact pre-rename bundle IDs and artifact
  names that were observed during those runs.
- The existing Android upload certificate retains its original subject common
  name. Certificate identity is immutable; replacing that text would require a
  signing-key migration, so it is not current product branding.

`thalesmmsradio@gmail.com` is the support contact, not a GitHub Pages account.
Do not derive a `thalesmmsradio.github.io` host from that email address.

The private `ThalesMMS/Turing-Lab-dev` repository is a development surface. Do
not use its Pages path for App Store support, privacy, or marketing metadata.

These values are compatibility locators or historical evidence, not current
branding. Update them only after the corresponding external resource is
migrated, and update every inbound reference in the same change.
