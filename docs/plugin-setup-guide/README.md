# Plugin Setup Guide Migration

This directory holds the migration companion for the legacy plugin setup guide.

Source of truth during migration:
- `docs/plugin-setup-guide.md`

Rules:
- Do not edit `docs/plugin-setup-guide.md` while migrating content into the new structure.
- Use the original file as the completeness checklist until every section has a home here.
- Treat the files in this directory as the new destination docs, not the old guide.

Recommended destination docs:
- `docs/plugin-setup-guide/README.md`
  - Entry point for the guide set.
  - Links to the other migration docs.
- `docs/plugin-setup-guide/migration-map.md`
  - Exact section-by-section move map from the original guide.

Planned destination structure:
- `~/workspace/plugin-templates/`
  - Canonical authoring template repo.
  - Shared plugin-contract assets live at repo root.
- Language-specific runtime and toolchain files live under `templates/py/`, `templates/ts/`, and `templates/rs/`.
- `docs/plugin-setup-guide/README.md`
  - High-level migration contract and navigation.
- `docs/plugin-setup-guide/migration-map.md`
  - Current heading to destination mapping.

Scope boundaries:
- Template files should explain what to copy into a plugin repo.
- The migration docs should explain why the split exists and where each section moved.
- The legacy guide stays intact until the migration is complete and verified.
