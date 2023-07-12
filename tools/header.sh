#!/bin/bash

# Check if the file parameter is provided
if [ $# -eq 0 ]; then
  echo "Usage: $0 <file>"
  exit 1
fi

# Get the file path from the command-line argument
file="$1"

# Check if the file exists
if [ ! -f "$file" ]; then
  echo "File not found: $file"
  exit 1
fi

# Count the number of non-empty lines that do not start with '#'
count=$(awk '!/^#/ && NF > 0 { count++ } END { print count }' "$file")

echo "Number of non-empty lines (excluding lines starting with '#'): $count"

header_one=(
"# CC-CEDICT-TW"
"# 自由詞典"
"# "
"# Based on, but not affiliated with, CC-CEDICT published by MDBG"
"# "
"# License:"
"# Creative Commons Attribution-ShareAlike 4.0 International License"
"# https://creativecommons.org/licenses/by-sa/4.0/"
"# "
"# Referenced works:"
"# CEDICT - Copyright (C) 1997, 1998 Paul Andrew Denisowski"
"# CC-CEDICT - CC BY-SA 4.0 (https://www.mdbg.net/chinese/dictionary?page=cc-cedict)"
"# "
"# CC-CEDICT-TW can be found at:"
"# https://github.com/null-von-sushi/cc-cedict-tw"
"# "
"# ")
printf "%s\n" "${header_one[@]}"
echo "#! version=0"
echo "#! subversion=1"
echo "#! format=ts"
echo "#! charset=UTF-8"
echo "#! entries=$count"
echo "#! license=https://creativecommons.org/licenses/by-sa/4.0/"
echo "#! date=$(date -u +\"%Y-%m-%dT%H:%M:%S%Z\")"
echo "#! time=$(date +%s)"
