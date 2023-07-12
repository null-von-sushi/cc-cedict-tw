#!/bin/bash

# Path to the database
database="/home/sysop/Downloads/out.u8"

# Iterate over each line in the database
while IFS= read -r line; do
  temp_hanzi=""
  temp_pinyin=""
  temp_hanzi=$(echo "$line" | awk -F '|' 'match($0, /[^\x00-\x7F]+\[([^\]]+)\]/) {print substr($0, RSTART, RLENGTH)}')
  if [ -n "$temp_hanzi" ]; then
    echo "temp_hanzi after first awk: $temp_hanzi"
  fi
  
  temp_pinyin=$(echo "$temp_hanzi" | awk 'match($0, /\[([^\]]+)\]/) {print substr($0, RSTART, RLENGTH)}')
  if [ -n "$temp_pinyin" ]; then
    echo "temp_pinyin: $temp_pinyin"
  fi
  
  temp_hanzi=$(echo "$temp_hanzi" | awk 'match($0, /[^\x00-\x7F]+/) {print substr($0, RSTART, RLENGTH)}')
  if [ -n "$temp_hanzi" ]; then
    echo "temp_hanzi after second awk: $temp_hanzi"
  fi

  # Perform the desired command using $temp_hanzi and $temp_pinyin
    if [ -n "$temp_hanzi" ]; then
    echo "$temp_hanzi $temp_pinyin"
    echo -e "\n\n"
  fi
done < "$database"
