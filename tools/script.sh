#!/bin/bash

# set this to a line to force --read to only read that specific line. WIP feature, will be used for something later
#checkline=500

# Used for parameters
read_flag=false
header_flag=false
output_file_format="u8"
DEBUG=false

dprint() {
  if [[ $DEBUG == true ]]; then
    echo "$1"
  fi
}

# Function to replace text after Chinese characters with correct transcription
replace_transcriptions() {
  local line
  while IFS= read -r line; do
    chinese_chars=$(echo "$line" | awk '{match($0, /[\p{Script=Hani}]+/); print substr($0, RSTART, RLENGTH)}')
    if [[ -n $chinese_chars ]]; then
      trans_line=$(grep "^$chinese_chars " "$output_file")
      if [[ -n $trans_line ]]; then
        new_transcription=$(echo "$trans_line" | awk '{print $3}')
        line=$(echo "$line" | awk -v new_trans="$new_transcription" '{sub(/.*/, new_trans); print}')
      fi
    fi
    echo "$line"
  done
}

# code for echoing a database
read_db() {

  process_line() {
    local line="$1"

    # Skip comment lines starting with '#'
    if [[ $line =~ ^#.* ]]; then
      continue
    fi

    # Extract traditional and simplified
    TRADITIONAL=$(echo "$line" | awk -F ' ' '{print $1}')
    SIMPLIFIED=$(echo "$line" | awk -F ' ' '{print $2}')

    # Extract the transcription
    temp="${line}"
    TRANSCRIPTION=$(echo "$temp" | awk -F '[[]' '{print $2}' | awk -F ']' '{print $1}')

    # Extract the definitions
    DEFINITIONS=$(echo "$temp" | awk -F '/' '{for (i=2; i<=NF; i++) print $i}')

    # Check if TW transcription is present
    if [[ "$DEFINITIONS" == *"Taiwan pr. ["* ]]; then
      # Extract TW transcription
      TWTRANSCRIPTION=$(echo "$DEFINITIONS" | awk -F 'Taiwan pr. \\[' '{print $2}' | awk -F '\\]' '{print $1}' | tr -d '\n')
      if [[ ! -z "$TWTRANSCRIPTION" ]]; then
        echo "TW: $TWTRANSCRIPTION"
      fi
    fi

    # Print the variables with multiple definitions on separate lines
    echo "Traditional: $TRADITIONAL"
    echo "Simplified: $SIMPLIFIED"
    echo "Transcription: $TRANSCRIPTION"
    echo "Definitions:"
    while IFS= read -r definition; do
      echo "$definition"
    done <<<"$DEFINITIONS"
    echo "------------------------------"
  }

  if [[ -n "$checkline" ]]; then
    line=$(sed "${checkline}q;d" "$database_file")
    if [[ -z "$line" ]]; then
      echo "Invalid line number: $checkline"
      exit 1
    fi

    # Call the function to process the specific line
    process_line "$line"

  else
    while IFS= read -r line; do
      # Skip comment lines starting with '#'
      if [[ $line =~ ^#.* ]]; then
        continue
      fi

      # Call the function to process each line
      process_line "$line"

    done <"$database_file"
  fi

}

# code for creating a new DB
create_db() {

  process_lineCreate() {
    local line="$1"
    # only accept valid file formats
    if [[ $output_file_format != "u8" && $output_file_format != "pleco" ]]; then
      echo "Error: Invalid output file format \"$output_file_format\"."
      exit 1
    fi

    #to prevent bugs and garbage output
    #rm -f $output_file

    # Extract traditional and simplified
    TRADITIONAL=$(echo "$line" | awk -F ' ' '{print $1}')
    SIMPLIFIED=$(echo "$line" | awk -F ' ' '{print $2}')
    dprint "TRADITIONAL: $TRADITIONAL, SIMPLIFIED $SIMPLIFIED"
    # Extract the transcription
    temp="${line}"
    TRANSCRIPTION=$(echo "$temp" | awk -F '[[]' '{print $2}' | awk -F ']' '{print $1}')

    # Extract the definitions
    DEFINITIONS=$(echo "$temp" | awk -F '/' '{for (i=2; i<=NF; i++) print $i}')

    # Reset TWTRANSCRIPTION
    TWTRANSCRIPTION=""
    dprint "DEFINITIONS: $DEFINITIONS"
    # Check if TW transcription is present

    if [[ $DEFINITIONS =~ Taiwan\ pr\.\ \[[A-Za-z0-9[:space:]]+\] ]]; then
      # ❯ echo "trash, refuse, garbage, (coll.) of poor quality, Taiwan pr. [le4 se4]" | grep -P "Taiwan pr\. \[[A-Za-z0-9[:space:]]+\]"
      dprint "Found TW definition!"
      # Extract TW transcription
      TWTRANSCRIPTION=$(echo "$DEFINITIONS" | awk -F 'Taiwan pr. \\[' '{print $2}' | awk -F '\\]' '{print $1}' | tr -d '\n')

      # Make a new definion for TW centric entries
      TWDEFINITIONS=""
      TWDEFINITIONS=$(echo "$DEFINITIONS" | sed -E "s/Taiwan pr. \[(.+?)\]/PRC pr. [$TRANSCRIPTION]/g")
    fi

    # Use a different variable to make it easier to have an overview of everything
    # Ensure that the definition used is TWDEFINITION if we are dealing with a word that has a ROC PRC pronounciation difference
    if [[ -z "$TWTRANSCRIPTION" ]]; then
      DEFINITIONS_SAVED=$DEFINITIONS
    else
      DEFINITIONS_SAVED=$TWDEFINITIONS
    fi
    # Deal with newlines and format DEFINITIONS so it is back in the format of the original CC-CEDICT
    DEFINITIONS_SAVED=$(echo "$DEFINITIONS_SAVED" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')
    DEFINITIONS_SAVED="/${DEFINITIONS_SAVED//$'\n'//}/"

    # Write the extracted data to the output file
    if [ "$output_file_format" == "u8" ]; then
      # u8 / CC-CEDICT format
      if [[ -z "$TWTRANSCRIPTION" ]]; then
        echo "$TRADITIONAL  $SIMPLIFIED [$TRANSCRIPTION] $DEFINITIONS_SAVED" >>"$output_file"
      else
        echo "$TRADITIONAL  $SIMPLIFIED [$TWTRANSCRIPTION] $DEFINITIONS_SAVED" >>"$output_file"
      fi
    elif [ "$output_file_format" == "pleco" ]; then
      DEFINITIONS_SAVED="$(echo $DEFINITIONS_SAVED | sed 's|^/||; s|/$||' | sed 's/\///g')"
      if [[ -z "$TWTRANSCRIPTION" ]]; then
        echo "$SIMPLIFIED[$TRADITIONAL]	$TRANSCRIPTION	$DEFINITIONS_SAVED" >>"$output_file"
      else
        echo "$SIMPLIFIED[$TRADITIONAL]	$TWTRANSCRIPTION	$DEFINITIONS_SAVED" >>"$output_file"
      fi
    else
      echo "Error writing data: cannot proceed because $output_file_format is not recognized as a format (this should be impossible...)"
    fi
  }

  if [[ -n "$checkline" ]]; then
    line=$(sed "${checkline}q;d" "$database_file")
    if [[ -z "$line" ]]; then
      echo "Invalid line number: $checkline"
      exit 1
    fi

    # Call the function to process the specific line
    process_lineCreate "$line"

  else
    while IFS= read -r line; do
      # Skip comment lines starting with '#'
      if [[ $line =~ ^#.* ]]; then
        continue
      fi

      # Call the function to process each line
      process_lineCreate "$line"

    done <"$database_file"
  fi

  # remove empty linebreaks before headers are written
  sed -i '/^$/d' $output_file

  # Write headers
  if [ "$output_file_format" == "u8" ]; then
    # u8 / CC-CEDICT format
    # Count the number of non-empty lines that do not start with '#'
    count=$(awk '!/^#/ && NF > 0 { count++ } END { print count }' "$output_file")

    #echo "Number of non-empty lines (excluding lines starting with '#'): $count"

    # Create a temporary file for the header
    temp_dbfile=$(mktemp)
    temp_headerfile=$(mktemp)
    #header
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

    # Redirect the header to the temporary file we made
    {
      printf "%s\n" "${header_one[@]}"
      echo "#! version=0"
      echo "#! subversion=1"
      echo "#! format=ts"
      echo "#! charset=UTF-8"
      echo "#! entries=$count"
      echo "#! license=https://creativecommons.org/licenses/by-sa/4.0/"
      echo "#! date=$(date -u +\"%Y-%m-%dT%H:%M:%S%Z\")"
      echo "#! time=$(date +%s)"
    } >"$temp_headerfile"

    # Merge the deader and database we just made into a new temporary db file
    cat "$temp_headerfile" $output_file >$temp_dbfile
    # Replace DB with the new one we just made
    mv $temp_dbfile $output_file # Overwrite db with the version containing the combined output

    #  Remove the temporary files
    rm "$temp_headerfile"

    # fix formatting issues
    # this one is for extra linebreaks and spaces at the end
    sed -i -e 's/[[:space:]]*$//' -e '${/^$/d;}' $output_file

    # this one is for the spacing between simp and trad
    temp_dbfile=$(mktemp)
    awk '{gsub(/[[:space:]]+/," ")}1' $output_file >$temp_dbfile
    mv $temp_dbfile $output_file # replace db with the version we just fixed
  elif [ "$output_file_format" == "pleco" ]; then
    echo "Skipping header as Pleco does not use any"
  else
    echo "Error writing headers: cannot proceed because $output_file_format is not recognized as a format (this should be impossible...)"
  fi

  # Just to make sure, remove empty linebreaks before final scripts are executed
  sed -i '/^$/d' $output_file

  # Finished building the DB using CC-CEDICT or similar as base
  # but only if output is u8, as this is the main format we are using.
  if [ "$output_file_format" == "u8" ]; then
    # execute scripts in ./extra/complex.first or complex.last folder. Intended for any changes to the DB base before other things are done
    extra_complex() {

      # Change directory to relevant folder
      includefiles="extra/$1/"

      # Loop through all files in the directory and execute them using source (.)
      for file in "$includefiles"*; do
        # Check if the file is executable
        if [ -x "$file" ]; then
          # Execute the file using source
          source ./"$file"
          # You can also use the following line instead, which is equivalent:
          # source ./"$file"
        else
          chmod +x ./"$file"
          source ./"$file"
        fi
      done
    }
    extra_complex complex.first

    line_exists() {
      grep -Fq "$1" "$output_file"
    }

    # Function to replace a line with another using awk
    replace_line() {
      1=$(echo "$1" | sed 's/\[/\\\[/g' | sed 's/\]/\\\]/g')
      2=$(echo "$2" | sed 's/\[/\\\[/g' | sed 's/\]/\\\]/g')
      awk -i inplace -v old="$1" -v new="$2" '{gsub(old, new)} 1' "$output_file"
    }

    # Process replacements
    echo "Replacing entries as defined in extra/replace/"
    echo "Input file will be output of last process: $output_file"

    # Define the directory path
    includefiles="extra/replace/"

    # Use a for loop to iterate through files in the directory
    for file in "$includefiles"*; do
      # reset variables
      OLD=""
      NEW=""
      WHY=""
      # Load lines to edit
      source "$file"
      if line_exists "$OLD"; then
        temp_filtered_content=$(mktemp)

        # Use grep -v to exclude the lines containing the search string and save to another temp file
        grep -Fv "$OLD" "$output_file" >$temp_filtered_content

        # Append the modified content to the filtered file
        echo "$NEW" >>$temp_filtered_content

        # Replace the original file with the modified content
        mv $temp_filtered_content "$output_file"
        echo "Done: $WHY"
      else
        echo "Processing: $WHY"
        echo "Error: The line \"$OLD\" does not exist. Skipping..."
      fi
    done
  fi


  # Add new definitions
  if [ "$output_file_format" == "u8" ]; then
  echo "Adding definitions from extra/include/"
  echo "Input file will be output of last process: $output_file"

  # Define the directory path
  includefiles="extra/include/"

  # Use a for loop to iterate through files in the directory
  for file in "$includefiles"*; do
    # reset variables
    NEW=""
    WHY=""
    # Load lines to edit
    source "$file"
    if line_exists "$NEW"; then
      echo "Processing: $WHY"
      echo "Error: The line \"$NEW\" already exists. Skipping..."

    else
      temp_filtered_content=$(mktemp)

      # Append the modified content to the filtered file
      echo "$NEW" >>"$output_file"
      echo "Done: $WHY"
    fi
  done
  fi

}

help_lines=(
  "Example (Create a new Database):"
  "script.sh --input=/path/to/CC-CEDICT-dictionary.u8 --output=/where/to/store/the/result --create"
  ""
  "Example (Reads existing database):"
  "script.sh --input=/path/to/CC-CEDICT-dictionary.u8 --read"
  ""
  "Parameters:"
  "--help     Shows this screen"
  "--input    Path to input file"
  "--output   Select where to save result of --create"
  "--format   Select between \"u8\" (default) and \"pleco\" formats for output file"
  "--create   Create a new database file"
  "--read     Don't create anything, just read an existing database file"
  " "
  "Please note that the \"pleco\" format may not support everything. For best results, create a u8"
  "file first, then run the script on the created file to turn the u8 into a pleco file."
  "This is because the post processing does not support pleco directly, so some important edits may be skipped"
)

# Parse command line arguments
# Parameters for settings first
for arg in "$@"; do
  case $arg in
  --input=*)
    database_file="${arg#*=}"
    ;;
  --output=*)
    output_file="${arg#*=}"
    ;;
  --format=*)
    output_file_format="${arg#*=}"
    ;;
  esac
done

# Parse command line arguments
# Actions second
for arg in "$@"; do
  case $arg in
  --input=*) ;;

  --output=*) ;;

  --format=*) ;;

  --help)
    help_flag=true
    printf "%s\n" "${help_lines[@]}"
    exit
    ;;
  --read)
    if [ "$create_flag" = true ]; then
      echo "Error: Cannot use --create and --read together."
      exit 1
    fi
    read_flag=true
    read_db
    ;;
  "")
    # Handle unrecognized arguments or show usage
    echo -e "Error: No action specified. Use --create or --read.\n"
    exit 1
    ;;
  --create)
    if [ "$read_flag" = true ]; then
      echo "Error: Cannot use --create and --read together."
      exit 1
    fi
    create_flag=true
    create_db
    ;;
  *)
    # Handle unrecognized arguments or show usage
    echo "Error: Unrecognized argument: $arg"
    exit 1
    ;;
  esac
done

# Check if no arguments were provided
if [ $# -eq 0 ]; then
  help_flag=true
  printf "%s\n" "${help_lines[@]}"
fi
