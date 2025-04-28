#!/usr/bin/env bash

# This script updates all scripts in the scripts directory to use the colors.sh utility
# instead of hardcoded ANSI color codes.

# Get the directory of this script
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

# List of scripts to update (excluding this script, run_demo.sh, colors.sh, and already updated scripts)
SCRIPTS=(
  $(find "$SCRIPT_DIR" -name "*.sh" | grep -v "update_colors.sh" | grep -v "run_demo.sh" | grep -v "colors.sh" | grep -v "aws_throttling_A.sh" | grep -v "kubernetes_crashloopbackoff_A.sh")
)

for script in "${SCRIPTS[@]}"; do
  echo "Updating $script..."

  # Add source directive at the beginning of the file
  sed -i.bak '2i\
# Source the colors utility\
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"\
source "$SCRIPT_DIR/colors.sh"\
' "$script"

  # Replace color codes with functions - simple patterns
  sed -i.bak 's/echo -e "\\e\[33m\([^\\]*\)\\e\[0m"/print_yellow "\1"/g' "$script"
  sed -i.bak 's/echo -e "\\e\[31m\([^\\]*\)\\e\[0m"/print_error "\1"/g' "$script"
  sed -i.bak 's/echo -e "\\e\[90m\([^\\]*\)\\e\[0m"/print_detail "\1"/g' "$script"
  sed -i.bak 's/echo -e "\\e\[32m\([^\\]*\)\\e\[0m"/print_info "\1"/g' "$script"

  # Replace color codes with functions - more complex patterns with escaped quotes
  sed -i.bak 's/echo -e "\\e\[33m\([^"]*"[^"]*"[^"]*\)\\e\[0m"/print_yellow "\1"/g' "$script"
  sed -i.bak 's/echo -e "\\e\[31m\([^"]*"[^"]*"[^"]*\)\\e\[0m"/print_error "\1"/g' "$script"
  sed -i.bak 's/echo -e "\\e\[90m\([^"]*"[^"]*"[^"]*\)\\e\[0m"/print_detail "\1"/g' "$script"
  sed -i.bak 's/echo -e "\\e\[32m\([^"]*"[^"]*"[^"]*\)\\e\[0m"/print_info "\1"/g' "$script"

  # Replace empty color lines with echo
  sed -i.bak 's/echo -e "\\e\[33m\\e\[0m"/echo ""/g' "$script"

  # Clean up backup files
  rm -f "$script.bak"

  echo "Updated $script"
done

echo "All scripts have been updated to use the colors.sh utility."
