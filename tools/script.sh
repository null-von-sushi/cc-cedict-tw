#!/bin/bash

# set this to a line to force --read to only read that specific line. WIP feature, will be used for something later
# checkline=60

# Used for parameters
read_flag=false
header_flag=false

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

  #to prevent bugs and garbage output
  rm $output_file

  # Read the file line by line
  while IFS= read -r line; do
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

    # Reset TWTRANSCRIPTION
    TWTRANSCRIPTION=""

    # Check if TW transcription is present
    if [[ "$DEFINITIONS" == *"Taiwan pr. ["* ]]; then
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
    if [[ -z "$TWTRANSCRIPTION" ]]; then
      echo "$TRADITIONAL  $SIMPLIFIED [$TRANSCRIPTION] $DEFINITIONS_SAVED" >>"$output_file"
    else
      echo "$TRADITIONAL  $SIMPLIFIED [$TWTRANSCRIPTION] $DEFINITIONS_SAVED" >>"$output_file"
    fi
  done <"$database_file"

  # Write header
  # Count the number of non-empty lines that do not start with '#'
  count=$(awk '!/^#/ && NF > 0 { count++ } END { print count }' "$output_file")

  #echo "Number of non-empty lines (excluding lines starting with '#'): $count"

  # Create a temporary file for the header
  temp_dbfile=$(mktemp)
  temp_headerfile=$(mktemp)

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
)

# Parse command line arguments
for arg in "$@"; do
  case $arg in
  --input=*)
    database_file="${arg#*=}"
    ;;
  --output=*)
    output_file="${arg#*=}"
    ;;
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
