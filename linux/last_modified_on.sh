#!/bin/bash

# Helper function
print_usage() {
    echo "Usage: $0 [-d depth] filename"
    echo "  -d depth    Optional. Max depth to search."
    echo "  filename    Required. The name of the file to search for."
}

# Default
depth_flag=""

# Parse options
while getopts ":d:" opt; do
  case $opt in
    d)
      depth_flag="-maxdepth $OPTARG"
      ;;
    \?)
      echo "Invalid option: -$OPTARG" >&2
      print_usage
      exit 1
      ;;
    :)
      echo "Option -$OPTARG requires an argument." >&2
      print_usage
      exit 1
      ;;
  esac
done

shift $((OPTIND -1))

if [ $# -lt 1 ]; then
    echo "Error: Missing filename argument."
    print_usage
    exit 1
fi

filename="$1"

# Find and sort files by modification time
find . $depth_flag -type f -name "$filename" -printf '%T@ %p\n' |
sort -n |
while read -r line; do
    timestamp=$(echo "$line" | cut -d' ' -f1)
    filepath=$(echo "$line" | cut -d' ' -f2-)
    mod_time=$(date -d @"$timestamp" "+%Y-%m-%d %H:%M:%S")
    echo "$filepath => Last Modified: $mod_time"
done

