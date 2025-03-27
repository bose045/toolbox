#!/bin/bash

print_usage() {
    echo "Usage: $0 [-d depth] (--first | --last | --line N) filename"
    echo "  -d depth       Optional. Max depth to search."
    echo "  --first        Show the first line of each matching file."
    echo "  --last         Show the last line of each matching file."
    echo "  --line N       Show the N-th line of each matching file."
    echo "  filename       Required. The name of the file to search for."
}

# Defaults
depth_flag=""
mode=""
line_number=""

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        -d)
            depth_flag="-maxdepth $2"
            shift 2
            ;;
        --first)
            mode="first"
            shift
            ;;
        --last)
            mode="last"
            shift
            ;;
        --line)
            mode="nth"
            line_number="$2"
            shift 2
            ;;
        -*)
            echo "Unknown option: $1"
            print_usage
            exit 1
            ;;
        *)
            filename="$1"
            shift
            ;;
    esac
done

if [ -z "$filename" ] || [ -z "$mode" ]; then
    echo "Error: Missing filename or mode."
    print_usage
    exit 1
fi

# Main logic
find . $depth_flag -type f -name "$filename" -print0 |
while IFS= read -r -d '' file; do
    case "$mode" in
        first)
            line=$(head -n 1 "$file")
            ;;
        last)
            line=$(tail -n 1 "$file")
            ;;
        nth)
            if ! [[ "$line_number" =~ ^[0-9]+$ ]]; then
                echo "Invalid line number: $line_number"
                exit 1
            fi
            line=$(sed -n "${line_number}p" "$file")
            ;;
    esac
    echo "$file => Line: $line"
done

