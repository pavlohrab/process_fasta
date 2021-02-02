#!/bin/bash
#
# AUTHOR: Pavlo Hrab



VERSION=0.1

INPUT_BOOL=0
OUTPUT_BOOL=0
LIN=0
ADD_NUMBERS=0
DELETE_BOOL=0
SPACE_BOOL=0
EXTRACT_HEADER=0
COL_HEADER_BOOL=0
DELIM_HEADER_BOOL=0
REPLACE_BOOL=0
REPLACE_TO_BOOL=0

tmpfile=$(mktemp /tmp/process_fasta.XXXXXX)
exec 5<>"$tmpfile"
rm "$tmpfile"

tmpfile2=$(mktemp /tmp/process_fasta.XXXXXX)
exec 6<>"$tmpfile2"
rm "$tmpfile2"


# If any errors stop script execution
set -e 


# Define the divider function. It's dynamically goes to the current
# width of the terminal
hr() {
  local start=$'\e(0' end=$'\e(B' line='qqqqqqqqqqqqqqqq'
  local cols=${COLUMNS:-$(tput cols)}
  while ((${#line} < cols)); do line+="$line"; done
  printf '%s%s%s\n' "$start" "${line:0:cols}" "$end"
}


# Define the help message
help(){
cat << EOF

Script for fasta processing. Version: ${VERSION}

Usage: -i|--input [FILE]; [-o|--output [FILE]]; [-l|--linearize]; 
       [-a|--add_numbers]; [-d|--delete [FILE]]; [-s|--spaces [CHAR]];
       [-c|--concatenate]; [--extract_header]; [--extract_delim [CHAR]];
       [--extract_column [NUM]]; [--replace [CHAR]] [--replace_to [CHAR]];
       [--add_filename ['start'|'end']]; [--add_delim [CHAR]]; [--split_fasta];
       [-h|--help]; [-v|--version]

The required argument is: -i.

    -i|--input        - input fasta file.

    -o|--output       - output, processed fasta file. 

    -l|--linearize    - linearize fasta file to a format one sequence per line. 
                        Mandatory for other manipulations.

    -a|--add_numbers  - add numbers to duplicated fasta headers. Numbers are 
                        added with an underscore. Must have perl installed.

    -d|--delete       - provide a txt file with fasta headers of sequences 
                        that must be deleted. One header per line. Partial headers
                        are also recognized (they do not have to be a full match)
                        Can be deleted those headers, which contain certain word or 
                        phase (txt file then contain this word or phrase)
    
    -s|--spaces       - provide a character to replaces spaces with in a fasta
                        headers. Please use single quotes. Example: '_'

    -c|--concatenate  - concatenate all the sequence in a multifasta file. Filename
                        will be use as a fasta header.

    --extract_header  - extract the 'subheader' from fasta headers. Use the 
                        chosen delimiter and column numbers (use the delimiter
                        to divide the header to columns). Must to provide
                        --extract_delim and --extract_column flags
    
    --extract_delim   - provide a delimiter (any character) to divide the fasta
                        headers. Part of --extract_header flag
    
    --extract_column  - provide a column number to extract the part of fasta
                        header. Part of --extract_header flag
                        
    --replace         - specify the characters to replace in the fasta sequence.
                        The characters to replace should be defined with 
                        double quotes with spaces between individual replacements. 
                        The length of replacements in this flag should be matched 
                        with the length in --replace_to. Else the character will 
                        be deleted (replaced to empty)

                        Example: ... --replace "\[" "AdpA" --replace_to "_" "_"
    
    --replace_to      - specify the characters replace to in the fasta headers.
                        The characters to replace should be defined with 
                        double quotes with spaces between individual replacements.
                        The length of replacement in this flag should be matched 
                        with the length in --replace. Else th replace_to would
                        not be used (not enough characters to replace)

                        Example: ... --replace "Streptomyces" --replace_to "" "_"
                        (here Streptomyces will be deleted, replaced with "")

    --add_filename    - add filename to the fasta headers. Please specify "start"
                        or "end". If no options are provided the filename will 
                        be added to the end of a header

    --add_delim       - specify the delimeter when adding filename. The default
                        is empty string (concatenate filename and fasta header)

    --split_fasta     - split the multifasta file to the indifidual ones. Fasta
                        header is used as filename. Splitted is done in the end,
                        so all modifications are preserved.

    -h|--help         - print this message and exit

    -v|--version      - print version and exit. 


GitHub page: https://github.com/pavlohrab/process_fasta

Feel free to post any issues!


EOF
}

while (( "$#" )); do
  case "$1" in
    -i|--input)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            INPUT=$2
            INPUT_BOOL=1
            shift 2
          else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
          fi
      ;;
      -o|--output)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            OUTPUT=$2
            OUTPUT_BOOL=1
            shift 2
          else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
          fi
      ;;
    -d|--delete)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            DELETE=$2
            DELETE_BOOL=1
            shift 2
          else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
          fi
      ;;
    -s|--spaces)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            SPACE=$2
            SPACE_BOOL=1
            shift 2
          else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
          fi
      ;;
    --extract_delim)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            DELIM_HEADER=$2
            DELIM_HEADER_BOOL=1
            shift 2
          else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
          fi
      ;;
    --extract_column)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            COL_HEADER=$2
            COL_HEADER_BOOL=1
            shift 2
          else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
          fi
      ;;
    --replace)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            REPLACE=$2
            REPLACE_BOOL=1
            shift
            IFS='--' read -r -a REPLACE_ARR_TMP <<< "$@"
            IFS='-' read -r -a REPLACE_ARR_TMP2 <<< ${REPLACE_ARR_TMP[0]}
            IFS=' ' read -r -a REPLACE_ARR <<< ${REPLACE_ARR_TMP2[0]}
            shift ${#REPLACE_ARR[*]}
          else
            echo "Error: Argument for $1 is missing" >&2
            exit 1
          fi
      ;;
    --replace_to)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            REPLACE_TO=$2
            REPLACE_TO_BOOL=1
            shift
            IFS='--' read -r -a REPLACE_TO_ARR_TMP <<< "$@"
            IFS='-' read -r -a REPLACE_ARR_TMP2 <<< ${REPLACE_ARR_TMP[0]}
            IFS=' ' read -r -a REPLACE_TO_ARR <<< ${REPLACE_TO_ARR_TMP2[0]}
            shift ${#REPLACE_TO_ARR[*]}
          else
            REPLACE_TO=""
            REPLACE_TO_BOOL=1
            echo "Warning: Argument for $1 is possibly missing" >&2
            echo "Using empty string for substitution"
            shift 2
          fi
      ;;
    --add_filename)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            ADD_FILENAME=$2
            ADD_FILENAME_BOOL=1
            shift 2
          else
            ADD_FILENAME="end"
            ADD_FILENAME_BOOL=1
            echo "Warning: Argument for $1 is possibly missing" >&2
            echo "Using end position as a default one"
            shift 1
          fi
      ;;
    --add_delim)
        if [ -n "$2" ] && [ ${2:0:1} != "-" ]; then
            ADD_DELIM=$2
            ADD_DELIM_BOOL=1
            shift 2
          else
            ADD_DELIM=""
            ADD_DELIM_BOOL=1
            echo "Error: Argument for $1 is possibly missing" >&2
            echo "Using empty string as a delimiter (no delimiter)"
            shift 1
          fi
      ;;
    -l|--linearize)
      LIN=1
      shift
      ;;
    --extract_header)
      EXTRACT_HEADER=1
      shift
      ;;
    --split_fasta)
      SPLIT=1
      shift
      ;;
    -c|--concatenate)
      CONCATENATE=1
      shift
      ;;
    -a|--add_numbers)
      ADD_NUMBERS=1
      shift
      ;;
    -h|--help)
      help
      exit 1
      shift
      ;;
    -v|--version)
      echo "Version number is: ${VERSION}"
      exit 1
      shift
      ;;
    -*|--*=) # unsupported flags
      echo "Error: Unsupported flag $1" >&2
      help
      exit 1
      ;;
  esac
done


if [[ $INPUT_BOOL -eq 0 ]]; then
    echo 'Error: No input file is provided'
    echo 'Please provide a fasta file with -i flag'
    hr
    exit 1
fi

INPUT_NAME=$(echo "$INPUT" | awk -F '/' '{print $NF}')
INPUT_NAME_2=$(basename "$INPUT_NAME" | sed 's/\(.*\)\..*/\1/')

if [[ $OUTPUT_BOOL -eq 0 ]]; then
    echo 'Warning: No output file is provided'
    echo "Using ${INPUT_NAME_2}_processed as a filename"
fi
hr

if [[ $LIN -eq 1 ]]; then 
    awk '/^>/ {printf("\n%s\n",$0);next; } { printf("%s",$0);}  END {printf("\n");}' < $INPUT > 5
    INPUT=5
fi
if [[ $ADD_NUMBERS -eq 1 ]]; then
    perl -pe 's/$/_$seen{$_}/ if ++$seen{$_}>1 and /^>/; ' $INPUT > 6
    mv 6 5
    INPUT=5
fi
if [[ $DELETE_BOOL -eq 1 ]]; then
    grep -F -A1 -f "$DELETE" $INPUT > rmfile.fasta
    grep -v -f rmfile.fasta $INPUT > 6
    mv 6 5
    INPUT=5
    rm -f rmfile.fasta
fi
if [[ $SPACE_BOOL -eq 1 ]]; then 
    tr -s ' ' $SPACE < $INPUT > 6
    mv 6 5
    INPUT=5
fi
if [[ $EXTRACT_HEADER -eq 1 ]]; then
    if [[ $DELIM_HEADER_BOOL -eq 0 ]]; then 
        echo "Please use --extract_delim flag to specify the delimiter"
        hr
        exit 1
    else 
        if [[ $COL_HEADER_BOOL -eq 0 ]]; then
            echo "Please specify --extract_column flag (number)"
            hr
            exit 1
        else
            awk -v delim_header="$DELIM_HEADER" -v col_delim="$COL_HEADER" \
            'BEGIN{RS=">";}NR>1{ split($1,a, delim_header); print ">"a[col_delim]"\n"$2;}'\
            $INPUT > 6
            mv 6 5
            INPUT=5
        fi
    fi
    
fi

if [[ $REPLACE_BOOL -eq 1 ]]; then 
    if [[ REPLACE_TO_BOOL -eq 0 ]]; then
        echo "Please use the --replace_to flag to specify to what replace the chosen characters"
        hr
        exit 1
    else
        for i in "${!REPLACE_ARR[@]}"; do 
            echo "${REPLACE_ARR[$i]} will become ${REPLACE_TO_ARR[$i]}"
            sed "s/${REPLACE_ARR[$i]}/${REPLACE_TO_ARR[$i]}/g" <$INPUT > 6
            mv 6 5
            INPUT=5
        done
    fi
fi

if [[ $CONCATENATE -eq 1 ]]; then
    cat $INPUT | grep -v '^\s*--'| grep -v '^>' | grep '^.' | tr -d '[:blank:]' \
    | tr -d '\n' | cat <( echo ">${INPUT_NAME_2}") - > 6
    mv 6 5
    INPUT=5
fi

if [[ $ADD_FILENAME_BOOL -eq 1 ]]; then
    if [[ $ADD_FILENAME == "start" ]]; then
        awk -v name="$INPUT_NAME_2$ADD_DELIM" \
        '/>/{sub(">","&"name);sub(/\.fasta/,x)}1' $INPUT > 6
    else
        awk -v fname="$INPUT_NAME_2" -v del="$ADD_DELIM" '/^>/ {$0=$0 del fname}1' $INPUT > 6
    fi
    mv 6 5
    INPUT=5
fi

if [[ $SPLIT -eq 1 ]]; then
    awk 'BEGIN {RS = ">" ; FS = "\n" ; ORS = ""} {if ($2) print ">"$0}' $INPUT > 6
    mv 6 5
    sed '/^\s*$/d' < 5 > 6
    mv 6 5
    mv 5 $OUTPUT
    awk -F "|" '/^>/ {close(F); ID=$1; gsub("^>", "", ID); F=ID".fasta"} {print >> F}' $OUTPUT
    echo "Processing is complete"
    hr
    exit 1
fi

awk 'BEGIN {RS = ">" ; FS = "\n" ; ORS = ""} {if ($2) print ">"$0}' $INPUT > 6
mv 6 5
sed '/^\s*$/d' < 5 > 6
mv 6 5
if [[ $OUTPUT_BOOL -eq 1 ]]; then
    mv 5 $OUTPUT 
else 
    mv 5 ${INPUT_NAME_2}_processed.fasta
fi

echo "Processing is complete. Please check the ${OUTPUT} file"
hr