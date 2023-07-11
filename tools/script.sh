#!/bin/bash

# Path to the database file
database_file="/full/path/to/cedict_ts.u8"

# Read the file line by line
while IFS= read -r line; do
    # Skip comment lines starting with '#'
    if [[ $line =~ ^#.* ]]; then
        continue
    fi

    # Extract fields from the line
    TRADITIONAL=$(echo "$line" | awk -F ' ' '{print $1}')
    SIMPLIFIED=$(echo "$line" | awk -F ' ' '{print $2}')
    TRANSCRIPTION=$(echo "$line" | grep -o '\[.*\]' | tr -d '[]')
    DEFINITIONS=$(echo "$line" | awk -F '/' '{for (i=2; i<=NF; i++) print $i}')

    # Print the variables with multiple definitions on separate lines
    echo "Traditional: $TRADITIONAL"
    echo "Simplified: $SIMPLIFIED"
    echo "Transcription: $TRANSCRIPTION"
    echo "Definitions:"
    while IFS= read -r definition; do
        echo "$definition"
    done <<< "$DEFINITIONS"
    echo "------------------------------"
done < "$database_file"
