#!/bin/bash

# Claude Skills Installer

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing Claude Skills..."

# Create directories
mkdir -p "$CLAUDE_DIR/commands"
mkdir -p "$CLAUDE_DIR/skills"

# Copy slash command
cp "$SCRIPT_DIR/commands/initialize-project.md" "$CLAUDE_DIR/commands/"
echo "✓ Installed /initialize-project command"

# Copy skills
cp "$SCRIPT_DIR/skills/"*.md "$CLAUDE_DIR/skills/"
echo "✓ Installed skills:"
ls -1 "$CLAUDE_DIR/skills/" | sed 's/^/  - /'

echo ""
echo "Installation complete!"
echo ""
echo "Usage:"
echo "  1. Open any project folder"
echo "  2. Run Claude Code"
echo "  3. Type: /initialize-project"
echo ""
