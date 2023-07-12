#!/bin/bash

# Path to the database
database="/home/sysop/Documents/GitHub/cc-cedict-tw/tools/tmp/cc-cedict-tw_mini.u8"

# Iterate over each line in the database
while IFS= read -r line; do

  # Extract the definitions
  DEFINITIONS=$(echo "$line" | awk -F '/' '{for (i=2; i<=NF; i++) print $i}')
  temp_dictionaryentry=""
  temp_hanzi=""
  temp_pinyin=""
  temp_hanzi=$(echo "$DEFINITIONS" | awk -F '|' 'match($0, /[^\x00-\x7F]+\[([^\]]+)\]/) {print substr($0, RSTART, RLENGTH)}')
  if [ -n "$temp_hanzi" ]; then
    echo "Reference found: $temp_hanzi"
  fi
  
  temp_pinyin=$(echo "$temp_hanzi" | awk 'match($0, /\[([^\]]+)\]/) {print substr($0, RSTART, RLENGTH)}')
  if [ -n "$temp_pinyin" ]; then
    echo "Original Pinyin: $temp_pinyin"
  fi
  
  temp_hanzi=$(echo "$temp_hanzi" | awk 'match($0, /[^\x00-\x7F]+/) {print substr($0, RSTART, RLENGTH)}')
  if [ -n "$temp_hanzi" ]; then
    echo "Hanzi: $temp_hanzi"
  fi

  # Perform the desired command using $temp_hanzi and $temp_pinyin
    if [ -n "$temp_hanzi" ]; then

    # search database for matching entry and extract it into variable
    temp_dictionaryentry=$(grep "$temp_hanzi \[" "$database")
    if [ -n "$temp_dictionaryentry" ]; then
      echo "Dictionary entry found: $temp_dictionaryentry"
    else
      echo "Dictionary was not found!"
    fi
    echo -e "\n\n"
  fi
done < "$database"
