#!/usr/bin/env bash
# Create a new simulation project from the BioKT template:
# standard folders, README to fill in, .gitignore, a local git repository
# with an initial commit and, with --github, a private GitHub repository.
set -euo pipefail

ROOT="${HOME}/Research/Projects"
ORG="BioKT"
GITHUB=0

usage() {
    cat <<EOF
Usage: $(basename "$0") [options] <Category>/<Project>

Creates <root>/<Category>/<Project> from the project template.

Options:
  --github        Also create a private GitHub repository and push to it
  --org NAME      GitHub organisation (default: ${ORG})
  --root DIR      Projects root (default: ${ROOT})
  -h, --help      Show this help

Example:
  $(basename "$0") --github IDPs/as4_fibril
EOF
}

die() { echo "Error: $*" >&2; exit 1; }

while [ $# -gt 0 ]; do
    case "$1" in
        --github) GITHUB=1; shift ;;
        --org)  [ $# -ge 2 ] || die "--org needs a value";  ORG="$2";  shift 2 ;;
        --root) [ $# -ge 2 ] || die "--root needs a value"; ROOT="$2"; shift 2 ;;
        -h|--help) usage; exit 0 ;;
        -*) die "unknown option $1 (see --help)" ;;
        *) break ;;
    esac
done
[ $# -eq 1 ] || { usage >&2; exit 1; }

# --- Parse and validate <Category>/<Project> -------------------------------
SPEC="${1%/}"
case "$SPEC" in
    */*/*|/*) die "expected <Category>/<Project>, got '$1'" ;;
    */*) ;;
    *) die "expected <Category>/<Project>, got '$1'" ;;
esac
CATEGORY="${SPEC%%/*}"
PROJECT="${SPEC#*/}"
NAME_RE='^[A-Za-z0-9][A-Za-z0-9_-]*$'
[[ "$CATEGORY" =~ $NAME_RE ]] || die "invalid category '$CATEGORY' (letters, digits, _ and - only)"
[[ "$PROJECT"  =~ $NAME_RE ]] || die "invalid project name '$PROJECT' (letters, digits, _ and - only)"

# --- Locate the template next to this script (following symlinks) ----------
src="${BASH_SOURCE[0]}"
while [ -L "$src" ]; do
    dir="$(cd -P "$(dirname "$src")" && pwd)"
    src="$(readlink "$src")"
    case "$src" in /*) ;; *) src="$dir/$src" ;; esac
done
TEMPLATE="$(cd -P "$(dirname "$src")" && pwd)/template"
[ -d "$TEMPLATE" ] || die "template folder not found at $TEMPLATE"

# --- Check everything before creating anything ------------------------------
[ -d "$ROOT" ] || die "projects root $ROOT does not exist"
TARGET="$ROOT/$CATEGORY/$PROJECT"
[ -e "$TARGET" ] && die "$TARGET already exists"

AUTHOR="$(git config user.name || true)"
[ -n "$AUTHOR" ] && [ -n "$(git config user.email || true)" ] \
    || die "set git user.name and user.email first"

if [ "$GITHUB" -eq 1 ]; then
    command -v gh >/dev/null 2>&1 \
        || die "GitHub CLI 'gh' not found; install it or drop --github"
    gh auth status >/dev/null 2>&1 \
        || die "'gh' is not logged in; run 'gh auth login' or drop --github"
    gh repo view "$ORG/$PROJECT" >/dev/null 2>&1 \
        && die "GitHub repository $ORG/$PROJECT already exists; choose another project name"
fi

# --- Create the project -----------------------------------------------------
[ -d "$ROOT/$CATEGORY" ] || echo "Note: creating new category $ROOT/$CATEGORY"
mkdir -p "$ROOT/$CATEGORY"
cp -R "$TEMPLATE" "$TARGET"

esc() { printf '%s' "$1" | sed 's/[&|\\]/\\&/g'; }
sed -e "s|__PROJECT__|$(esc "$PROJECT")|g" \
    -e "s|__DATE__|$(date +%Y-%m-%d)|g" \
    -e "s|__AUTHOR__|$(esc "$AUTHOR")|g" \
    "$TARGET/README.md" > "$TARGET/README.md.tmp"
mv "$TARGET/README.md.tmp" "$TARGET/README.md"

cd "$TARGET"
git init -q
git symbolic-ref HEAD refs/heads/main
git add -A
git commit -q -m "Initial project skeleton from simulation-project-template"
echo "Created $TARGET"

if [ "$GITHUB" -eq 1 ]; then
    if gh repo create "$ORG/$PROJECT" --private --source . --remote origin --push >/dev/null; then
        echo "Created private repository https://github.com/$ORG/$PROJECT"
    else
        echo "Warning: the local project was created, but creating $ORG/$PROJECT on GitHub failed." >&2
        echo "Retry from $TARGET with:" >&2
        echo "  gh repo create $ORG/$PROJECT --private --source . --remote origin --push" >&2
        exit 1
    fi
else
    echo "No GitHub repository created. To add one later, from $TARGET run:"
    echo "  gh repo create $ORG/$PROJECT --private --source . --remote origin --push"
fi

echo "Next: fill in README.md (system, engine, force field, where the data lives)."
