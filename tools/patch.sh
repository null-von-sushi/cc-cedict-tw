#!/bin/bash

# Path to the database
database="/home/sysop/Documents/GitHub/cc-cedict-tw/tools/tmp/cc-cedict-tw.u8"
databaseblacklist="$database.blacklist"

# Iterate over each line in the database
while IFS= read -r line; do

  # Extract the definitions
  DEFINITIONS=$(echo "$line" | awk -F '/' '{for (i=2; i<=NF; i++) print $i}')
  temp_dictionaryentry=""
  temp_full=""
  temp_hanzi=""
  temp_pinyin=""

  # try to extract both if possible
  temp_full=$(echo "$DEFINITIONS" | awk -F '|' 'match($0, /([A-Za-z0-9]|[^\x00-\x7F])+\|([A-Za-z0-9]|[^\x00-\x7F])+/) {print substr($0, RSTART, RLENGTH)}')
  # If no traditional specifically is not available, fall back to alternative method which just gets any characters
  if [[ -z "$temp_full" ]]; then
    temp_full=$(echo "$DEFINITIONS" | awk -F '|' 'match($0, /[^\x00-\x7F]+\[([^\]]+)\]/) {print substr($0, RSTART, RLENGTH)}')
  # if both are available, use both
  else
    # get traditional
    temp_full_a=$(echo $temp_full | perl -nle 'print $& if /([A-Za-z0-9]|[^\x00-\x7F])+\|/')
    #remove `|`
    temp_full_a=${temp_full_a%"|"}
    #get simplified
    temp_full_b=$(echo $temp_full | perl -nle 'print $& if /\|([A-Za-z0-9]|[^\x00-\x7F])+/')
    #remove `|`
    temp_full_b=${temp_full_b#"|"}
    temp_full=$(echo "$temp_full_a $temp_full_b")
  fi

  temp_pinyin=$(echo "$temp_full" | awk 'match($0, /\[([^\]]+)\]/) {print substr($0, RSTART, RLENGTH)}')
  temp_hanzi=$(echo "$temp_full" | awk 'match($0, /[^\x00-\x7F]+/) {print substr($0, RSTART, RLENGTH)}')

  # Perform the desired command using $temp_hanzi and $temp_pinyin
  if [ -n "$temp_hanzi" ]; then

    # search database for matching entry and extract it into variable
    temp_dictionaryentry=$(grep "$temp_hanzi \[" "$database" | grep "PRC pr. \[")
    if [ -n "$(echo "$temp_dictionaryentry" | grep "PRC pr. \[")" ]; then
      if [ -n "$temp_dictionaryentry" ]; then

        # get pinyin of dictionary entry
        temp_dictionaryentry_pinyin=$(echo $temp_dictionaryentry | awk -F '[[]' '{print $2}' | awk -F ']' '{print $1}')

        # If the pronounciation is already the same, no need to do anything
        if [ "$temp_pinyin" = "[$temp_dictionaryentry_pinyin]" ]; then
          # echo "The variables have the same value."
          true
        else
          # Check if the two words are even the same. We don't want [xi1] to randomly turn into [ge4 ben1 dong1 xi1]...
          if [ "$(echo "$temp_dictionaryentry" | awk -F ' ' '{print $1}')" = "$temp_hanzi" ]; then
            # # Debug
            # echo -e "Reference found for\n\"$temp_full\"\nFound in \n\"$line\""
            # echo -e "Reference consists of the following data:\nHanzi (Simplified): \n$temp_hanzi\nPinyin: \n$temp_pinyin"
            echo -e "Relevant dictionary entry/entries found in database: \n$temp_dictionaryentry"
            # echo "Conclusion: $temp_pinyin => [$temp_dictionaryentry_pinyin]"

            echo "Line was: $line"
            # Construct the new line with the desired format
            temp_new_pinyin=$(perl -ne "print if /[^\x00-\x7F]+\\s\Q$temp_hanzi\E\\s\\[([^\\]]+)\\]/" $database | awk -F '[[]' '{print $2}' | awk -F ']' '{print $1}')
            temp_new_hanzi="$temp_hanz"
            temp_new="[$temp_new_pinyin]"
            new_line=$(echo "$line" | perl -pe 's/\Q'"$temp_full"'\E/'"$temp_new"'/g')
            echo -e "Temp full $temp_full"
            echo "Line will be: $new_line"

            search_string=$temp_full
            # Escape brackets in search_string
            escaped_search_string=$(echo "$search_string" | sed 's/\[/\\\[/g' | sed 's/\]/\\\]/g')

            # Get index of part we need to replace
            index=$(echo "$line" | awk -v search="$escaped_search_string" 'BEGIN{FS="/"} {for (i=1; i<=NF; i++) if (index($i, search) > 0) print i-1}' 2>/dev/null)
            # No idea why this is needed, but it is
            ((index = index + 1))
            # make it a new variable
            temp_replace=$(echo "$line" | awk -v idx="$index" 'BEGIN{FS="/"} {if (idx >= 0 && idx < NF) print $idx}')
            echo "searching for in \"$search_string\" (index $index) in \"$temp_full\". Escaped search string is: \"$escaped_search_string\""
            echo "$temp_replace"

            # make it so it will only proceed if we're still matching the right text.
            # all barely works and it's better to skip entries than to have a wrong/broken DB
            # so: check if text we're about to modify includes the text we're searching for to begin with
            if [[ $temp_replace == *"$temp_full"* ]]; then
              echo "yes"
              echo -e "$temp_full"
              echo "$temp_replace"

              # Load a file with a blacklist of things to skip since we don't know how to work around some issues
              # right now, and will this be manually speifying some things to skip
              if ! grep -qF "$temp_full" "$databaseblacklist"; then
                echo "Can continue with $temp_full"
              else
                echo "Skipping $temp_full due to blacklist"
              fi

            else
              echo "no"
            fi

          fi

        fi

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
