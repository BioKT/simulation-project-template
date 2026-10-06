# __PROJECT__

One or two sentences: the question this project answers.

Created __DATE__ by __AUTHOR__.

## System

| Field | Value |
|-------|-------|
| System identifier(s) | e.g. `as4` — used as the prefix of every file name |
| Simulation engine and version | e.g. GROMACS 2024.2, OpenMM 8.1, Amber 24 |
| Force field | |
| Water model | |
| Other software (PLUMED, ...) | |

## Where the data lives

Raw output is in `data/` and is not tracked by git. Canonical copy:

| Machine | Path | Backed up to |
|---------|------|--------------|
| | | |

## Naming

Files are named `<system>[_<variant>]_<stage>[_rep<N>].<ext>`.
Replicas are numbered from 0.
Figures are named `<system>_<observable>[_<variant>]_v<N>.<ext>`.

Choices for this project:

- Stages: e.g. `em`, `nvt`, `npt`, `md`
- Variant tags, in this order: e.g. force field, then temperature

## Layout

| Folder | Contents | Tracked |
|--------|----------|---------|
| `data/` | Raw simulation output | no |
| `setup/` | Everything needed to (re)start a run: structures, topologies, force-field files, engine input files | yes |
| `scripts/` | How runs are launched: job submission and driver scripts | yes |
| `analysis/notebooks/` | Jupyter notebooks | yes |
| `analysis/scripts/` | Analysis scripts | yes |
| `analysis/figures/` | Figures | yes |
