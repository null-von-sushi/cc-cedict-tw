#!/bin/bash

# Used for parameters
create_flag=false
read_flag=false





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
        done <<< "$DEFINITIONS"
        echo "------------------------------"
    done < "$database_file"
}

# code for creating a new DB
create_db() {
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
            echo "$TRADITIONAL  $SIMPLIFIED [$TRANSCRIPTION] $DEFINITIONS_SAVED" >> "$output_file"
        else
            echo "$TRADITIONAL  $SIMPLIFIED [$TWTRANSCRIPTION] $DEFINITIONS_SAVED" >> "$output_file"
        fi
    done < "$database_file"


    # Replace transcriptions in DEFINITIONS_SAVED
    # mv "$output_file" "$output_file.tmp"
    #replace_transcriptions < "$output_file.tmp" > "$output_file"
    #rm "$output_file.tmp"
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
    --create)
      if [ "$read_flag" = true ]; then
        echo "Error: Cannot use --create and --read together."
        exit 1
      fi
      create_flag=true
      create_db
      ;;
    --read)
      if [ "$create_flag" = true ]; then
        echo "Error: Cannot use --create and --read together."
        exit 1
      fi
      read_flag=true
      read_db
      ;;
    --help)
      help_flag=true
      printf "%s\n" "${help_lines[@]}"
      ;;
    "")
      # Handle unrecognized arguments or show usage
      echo -e "Error: No action specified. Use --create or --read.\n"
      exit 1
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
