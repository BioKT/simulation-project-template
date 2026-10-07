# simulation-project-template

Standard layout for molecular simulation projects in the BioKT group,
independent of the simulation engine (GROMACS, Amber, OpenMM, ...).

Every project gets the same top-level folders, a README to fill in, and a
`.gitignore` that keeps raw simulation output out of git. Everything else
(subfolders, stage names, tag order) is up to each project and recorded in
its README.

```
<Project>/
├── data/                # raw simulation output, never tracked
├── setup/               # everything needed to (re)start a run
├── scripts/             # job submission and driver scripts
├── analysis/
│   ├── notebooks/
│   ├── scripts/
│   └── figures/
├── README.md
└── .gitignore
```

## Usage

```bash
new_simulation_project.sh IDPs/as4_fibril
```

This creates `~/Research/Projects/IDPs/as4_fibril/` and initialises a git
repository with an initial commit. Add `--github` to also create a private
repository `BioKT/as4_fibril` on GitHub with that commit pushed to it:

```bash
new_simulation_project.sh --github IDPs/as4_fibril
```

| Option | Effect |
|--------|--------|
| `--github` | Also create a private GitHub repository and push to it |
| `--org NAME` | GitHub organisation (default `BioKT`) |
| `--root DIR` | Projects root (default `~/Research/Projects`) |

The script checks everything first (name, existing folder, git identity and,
with `--github`, the `gh` login and whether the GitHub repository already
exists) and creates nothing if a check fails.

## Examples

`examples/` holds engine-specific starting points. They are **not** copied
into new projects; copy what you need by hand.

| Path | What it is |
|------|------------|
| `examples/gromacs/run_md.sh` | Schematic GROMACS setup script: topology, box, solvent, ions, EM, then NVT, NPT and production for each replica, one explicit step after another, with every file name built from system, force field, water model, temperature and replica. Copy to `scripts/` and adapt. |
| `examples/gromacs/mdp/ions.mdp` | The `.mdp` for the `.tpr` that `genion` reads: cutoff electrostatics, so `grompp` does not warn about PME with a net charge. Copy to `setup/mdp/`. |

The other `.mdp` templates (`em`, `nvt`, `npt`, `md`) are not provided:
cutoffs and related settings depend on the force field. The script is
explained in Chapter 3, §6.1 of the
[BIOKT Lab Handbook](https://github.com/BioKT/lab-handbook).

## Installation

Requires bash and git. For `--github`, the
[GitHub CLI](https://cli.github.com) logged in with `gh auth login`.

```bash
git clone git@github.com:BioKT/simulation-project-template.git
mkdir -p ~/.local/bin
ln -s "$PWD/simulation-project-template/new_simulation_project.sh" ~/.local/bin/
```

Make sure `~/.local/bin` is on your `PATH`. On most Linux systems it is added
automatically at your next login once the folder exists. On macOS and on HPC
clusters you may need to add it yourself, e.g. in `~/.zshrc` or `~/.bashrc`:

```bash
export PATH="$HOME/.local/bin:$PATH"
```

The script finds the `template/` folder through the symlink, so `git pull` in
the clone updates both.

## Changing the template

Edit the files under `template/`. Changes affect new projects only.
