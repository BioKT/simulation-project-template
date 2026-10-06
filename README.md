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

## Installation

Requires bash and git. For `--github`, the
[GitHub CLI](https://cli.github.com) logged in with `gh auth login`.

```bash
git clone git@github.com:BioKT/simulation-project-template.git
mkdir -p ~/bin
ln -s "$PWD/simulation-project-template/new_simulation_project.sh" ~/bin/
```

Make sure `~/bin` is on your `PATH`. The script finds the `template/`
folder through the symlink, so `git pull` in the clone updates both.

## Changing the template

Edit the files under `template/`. Changes affect new projects only.
