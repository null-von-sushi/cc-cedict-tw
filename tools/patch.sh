#!/bin/bash

# Path to the database
database="/home/sysop/Documents/GitHub/cc-cedict-tw/tools/tmp/cc-cedict-tw.u8"

# Iterate over each line in the database
while IFS= read -r line; do

  # Extract the definitions
  DEFINITIONS=$(echo "$line" | awk -F '/' '{for (i=2; i<=NF; i++) print $i}')
  temp_dictionaryentry=""
  temp_full=""
  temp_hanzi=""
  temp_pinyin=""
  temp_full=$(echo "$DEFINITIONS" | awk -F '|' 'match($0, /[^\x00-\x7F]+\[([^\]]+)\]/) {print substr($0, RSTART, RLENGTH)}')
  temp_pinyin=$(echo "$temp_full" | awk 'match($0, /\[([^\]]+)\]/) {print substr($0, RSTART, RLENGTH)}')
  temp_hanzi=$(echo "$temp_full" | awk 'match($0, /[^\x00-\x7F]+/) {print substr($0, RSTART, RLENGTH)}')

  # Perform the desired command using $temp_hanzi and $temp_pinyin
  if [ -n "$temp_hanzi" ]; then

    # search database for matching entry and extract it into variable
    temp_dictionaryentry=$(grep "$temp_hanzi \[" "$database")
    if [ -n "$(echo "$temp_dictionaryentry" | grep "PRC pr. \[")" ]; then
      if [ -n "$temp_dictionaryentry" ]; then
        # mostly debug output
        echo "Reference found: $temp_full"
        echo "Original Pinyin: $temp_pinyin"
        echo "Hanzi (Simplified): $temp_hanzi"
        echo "Relevant dictionary entry/entries: $temp_dictionaryentry"
        echo "Line is: $line"
        # Construct the new line with the desired format
        temp_new_pinyin=$(perl -ne "print if /[^\x00-\x7F]+\\s\Q$temp_hanzi\E\\s\\[([^\\]]+)\\]/" $database | awk -F '[[]' '{print $2}' | awk -F ']' '{print $1}')
        temp_new_hanzi="$temp_hanz"
        temp_new="[$temp_new_pinyin]"
        new_line=$(echo "$line" | perl -pe 's/\Q'"$temp_full"'\E/'"$temp_new"'/g')

        echo "New line will be: $new_line"

      else

        echo "Dictionary was not found!"
      fi
      echo -e "\n\n"
    fi
  fi
done <"$database"

# #!/bin/bash

# # Path to the file
# file="/path/to/your/file"

# # Create a temporary file
# temp_file=$(mktemp)

# # Iterate over each line in the file
# while IFS= read -r line; do
#   # Modify the line as needed
#   # For example, replace "Original" with "New"
#   modified_line=${line//Original/New}

#   # Write the modified line to the temporary file
#   echo "$modified_line" >> "$temp_file"
# done < "$file"

# # Replace the original file with the temporary file
# mv "$temp_file" "$file"
