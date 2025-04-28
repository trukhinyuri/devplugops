#!/usr/bin/env bash

# ANSI color codes for shell output
export RED='\e[31m'
export GREEN='\e[32m'
export YELLOW='\e[33m'
export BLUE='\e[34m'
export MAGENTA='\e[35m'
export CYAN='\e[36m'
export GRAY='\e[90m'
export BOLD='\e[1m'
export UNDERLINE='\e[4m'
export RESET='\e[0m'

# Function to print colored text
# Usage: colorize "text" $COLOR
colorize() {
  local text="$1"
  local color="$2"
  # Use printf instead of echo for more consistent behavior across different environments
  printf "${color}%s${RESET}\n" "$text"
}

# Shorthand functions for common colors
print_red() {
  colorize "$1" "$RED"
}

print_green() {
  colorize "$1" "$GREEN"
}

print_yellow() {
  colorize "$1" "$YELLOW"
}

print_blue() {
  colorize "$1" "$BLUE"
}

print_gray() {
  colorize "$1" "$GRAY"
}

print_error() {
  print_red "$1"
}

print_warning() {
  print_yellow "$1"
}

print_info() {
  print_green "$1"
}

print_detail() {
  print_gray "$1"
}
