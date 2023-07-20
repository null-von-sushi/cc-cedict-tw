#!/bin/bash

# DEBUG: set this to a line to force --read to only read that specific line.
#checkline=51
#checkline=65

# Path to the database
database="/home/sysop/Documents/GitHub/cc-cedict-tw/tools/tmp/cc-cedict-tw_mini.u8"
databaseblacklist="$database.blacklist"

# Iterate over each line in the database
processText() {

  # Extract the definitions
  DEFINITIONS=$(echo "$line" | awk -F '/' '{for (i=2; i<=NF; i++) print $i}')
  temp_dictionaryentry=""
  temp_full=""
  temp_hanzi=""
  temp_pinyin=""

  # try to extract both if possible
  temp_full=$(echo "$DEFINITIONS" | awk -F '|' 'match($0, /([A-Za-z0-9]|[^\x00-\x7F])+\|([A-Za-z0-9]|[^\x00-\x7F])+\[([^\]]+)\]/) {print substr($0, RSTART, RLENGTH)}')
  # If no traditional specifically is not available, fall back to alternative method which just gets any characters
  if [[ -z "$temp_full" ]]; then
    # get simplified
    temp_full=$(echo "$DEFINITIONS" | awk -F '|' 'match($0, /[^\x00-\x7F]+\[([^\]]+)\]/) {print substr($0, RSTART, RLENGTH)}')
    temp_pinyin=$(echo "$temp_full" | awk 'match($0, /\[([^\]]+)\]/) {print substr($0, RSTART, RLENGTH)}')
    temp_hanzi=$(echo "$temp_full" | awk 'match($0, /[^\x00-\x7F]+/) {print substr($0, RSTART, RLENGTH)}')
  # if both are available, use both
  else
    # get traditional
    # first extract pinyin
    temp_pinyin=$(echo "$temp_full" | awk 'match($0, /\[([^\]]+)\]/) {print substr($0, RSTART, RLENGTH)}')

    temp_hanzi=$(echo "$temp_full" | awk '{ gsub(/\[[^\]]+\]/, "") } 1')

    # try to replace the | with the correct space
    temp_hanzi_a=$(echo $temp_hanzi | perl -nle 'print $& if /([A-Za-z0-9]|[^\x00-\x7F])+\|/')
    #remove `|`
    temp_hanzi_a=${temp_hanzi_a%"|"}

    #get simplified
    temp_hanzi_b=$(echo $temp_hanzi | perl -nle 'print $& if /\|([A-Za-z0-9]|[^\x00-\x7F])+/')
    #remove `|`
    temp_hanzi_b=${temp_hanzi_b#"|"}
    temp_hanzi=$(echo "$temp_hanzi_a $temp_hanzi_b")

    # define hanzi-only version for searching the database
    # use temp_full, and remove the pinyin parts

  fi

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
          true
        else

          # Prepare variable for verification. We need to temporarily drop the part of the trad-simp group...

          if [[ $temp_hanzi == *" "* ]]; then
            temp_hanzi_search=$(echo $temp_hanzi | awk -F ' ' '{print $1}')
          else
            temp_hanzi_search=$temp_hanzi
          fi

          # Check if the two words are even the same. We don't want [xi1] to randomly turn into [ge4 ben1 dong1 xi1]...
          if [ "$(echo "$temp_dictionaryentry" | awk -F ' ' '{print $1}')" = "$temp_hanzi_search" ]; then

            temp_new_pinyin=$(perl -ne "print if /[^\x00-\x7F]+\\s\Q$temp_hanzi\E\\s\\[([^\\]]+)\\]/" $database | awk -F '[[]' '{print $2}' | awk -F ']' '{print $1}')

            # Construct the new line with the desired format (needs special treatment depending on whether we're using trad or simp strings)
            if [[ $temp_hanzi == *" "* ]]; then
              #trad
              temp_new_pinyin=$(perl -ne "print if /\Q$temp_hanzi\E\\s\\[([^\\]]+)\\]/" $database | awk -F '[[]' '{print $2}' | awk -F ']' '{print $1}')

              #also change the temp_hanzi variable to only reference simp, should be safe to do now
              #temp_hanzi=$(echo $temp_hanzi | awk '{ sub(/[^ ]+ /, "") } 1')

              #also change the temp_hanzi variable to not have a space anymore
              temp_hanzi=$(echo $temp_hanzi | awk '{ sub(/ /, "|") } 1')
            else
              #simp
              temp_new_pinyin=$(perl -ne "print if /[^\x00-\x7F]+\\s\Q$temp_hanzi\E\\s\\[([^\\]]+)\\]/" $database | awk -F '[[]' '{print $2}' | awk -F ']' '{print $1}')
            fi

            temp_new="$(echo -e $temp_hanzi\[$temp_new_pinyin\])"
            # a bad attempt at trying to create a new line
            new_line=$(echo "$line" | perl -pe 's/\Q'"$temp_full"'\E/'"$temp_new"'/g')
            search_string=$temp_full
            # Escape brackets in search_string
            escaped_search_string=$(echo "$search_string" | sed 's/\[/\\\[/g' | sed 's/\]/\\\]/g')

            # Get index of part we need to replace
            index=$(echo "$line" | awk -v search="$escaped_search_string" 'BEGIN{FS="/"} {for (i=1; i<=NF; i++) if (index($i, search) > 0) print i-1}' 2>/dev/null)
            # No idea why this is needed, but it is
            ((index = index + 1))
            # make it a new variable
            temp_replace=$(echo "$line" | awk -v idx="$index" 'BEGIN{FS="/"} {if (idx >= 0 && idx < NF) print $idx}')

            # make it so it will only proceed if we're still matching the right text.
            # all barely works and it's better to skip entries than to have a wrong/broken DB
            # so: check if text we're about to modify includes the text we're searching for to begin with
            if [[ $temp_replace == *"$temp_full"* ]]; then

              # Load a file with a blacklist of things to skip since we don't know how to work around some issues
              # right now, and will this be manually speifying some things to skip
              if ! grep -qF "$temp_full" "$databaseblacklist" 2>/dev/null; then
                # Debug
                echo -e "Reference found for:\n\"$temp_full\"\nFound in \n\"$line\""
                # echo -e "Reference consists of the following data:\nHanzi (Simplified): \n$temp_hanzi\nPinyin: \n$temp_pinyin"
                echo -e "Relevant dictionary entry/entries found in database: \n\"$temp_dictionaryentry\""
                # echo "Conclusion: $temp_pinyin => [$temp_dictionaryentry_pinyin]"

                echo -e "Line was: \n\"$line\""
                echo -e "Line will be new: \n\"$new_line\""
                echo -e "\n\n"

                # write changes to db
                # Escape slashes in the line and new_line to prevent issues with sed
                escaped_line=$(printf "$line" | awk '{ gsub(/\//, "\\/"); print }')
                escaped_new_line=$(printf "$new_line" | awk '{ gsub(/\//, "\\/"); print }')

                # Perform the search and replace using awk
                awk -v line="$escaped_line" -v new_line="$escaped_new_line" '{ if ($0 == line) $0 = new_line } 1' "$database" >"$database.tmp"

                # Check if the backup already exists
                if [ -e "$database.bak" ]; then
                  # since backup already exists, just continue as usual
                  mv "$database.tmp" "$database"
                else
                  # since backup does not already exists, make a backup first
                  cp "$database" "$database.bak"
                  mv "$database.tmp" "$database"
                fi
              else
                # Skipping due to blacklist
                echo "skipped due to blacklist: $line"
                true
              fi

            else
              # Text would not have matched what we're looking for
              true

            fi

          fi

        fi

      else
        echo "Error! Dictionary was not found!"
      fi
    fi
  fi

}

if [[ -n "$checkline" ]]; then
  line=$(sed "${checkline}q;d" "$database")
  if [[ -z "$line" ]]; then
    echo "Invalid line number: $checkline"
    exit 1
  fi

  # Call the function to process the specific line
  processText "$line"

else
  while IFS= read -r line; do
    # Skip comment lines starting with '#'
    if [[ $line =~ ^#.* ]]; then
      continue
    fi

    # Call the function to process each line
    processText "$line"

  done <"$database"
fi
