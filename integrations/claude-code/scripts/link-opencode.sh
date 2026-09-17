#!/bin/sh
# Symlink this plugin's skills into an opencode project so opencode can
# discover them via its Agent Skills support (which reads .opencode/skills/
# using the same SKILL.md format as Claude Code).
#
# Usage: integrations/claude-code/scripts/link-opencode.sh [target-project-dir]
# Defaults to the current directory when no target is given.
set -eu

script_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
skills_dir="$script_dir/../skills"
target_dir="${1:-.}"
opencode_skills_dir="$target_dir/.opencode/skills"

mkdir -p "$opencode_skills_dir"

link_path="$opencode_skills_dir/codex-security"
if [ -e "$link_path" ] || [ -L "$link_path" ]; then
  echo "error: $link_path already exists; remove it first" >&2
  exit 1
fi

ln -s "$skills_dir" "$link_path"
echo "Linked $skills_dir -> $link_path"
