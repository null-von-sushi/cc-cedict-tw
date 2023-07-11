#!/bin/bash

# Path to the database file
database_file="/full/path/to/cedict_ts.u8"

# Read the file line by line
while IFS= read -r line; do
    # Assign the values to variables
    TRADITIONAL=$(echo "$line" | awk -F ' ' '{print $1}')
    SIMPLIFIED=$(echo "$line" | awk -F ' ' '{print $2}')
    TRANSCRIPTION=$(echo "$line" | awk -F ' ' '{print $3}')
    DEFINITION=$(echo "$line" | awk -F '/' '{print $2}')

    # Print the variables (you can modify this part as per your requirement)
    echo "Traditional: $TRADITIONAL"
    echo "Simplified: $SIMPLIFIED"
    echo "Transcription: $TRANSCRIPTION"
    echo "Definition: $DEFINITION"
    echo "------------------------------"
done < "$database_file"
