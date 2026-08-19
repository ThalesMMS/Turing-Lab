# Profiling captures

This folder is for **exported Flutter DevTools artifacts** used to satisfy AC1 of the spec.

Expected artifacts (per graph tier: small / medium / large):

- `*_performance_trace.json` (DevTools Performance export)
- `*_memory_before.png` and `*_memory_after.png` (heap snapshot screenshots) or exported snapshot files
- `metrics.md` (summary table)

If you cannot generate artifacts in the current environment, leave this folder in place and update the spec/QA expectations; as written, the spec requires in-repo captures.
