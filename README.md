# Process fasta script

![Visitor count](https://shields-io-visitor-counter.herokuapp.com/badge?page=pavlohrab.process_fasta&style=for-the-badge)
![GitHub](https://img.shields.io/github/license/pavlohrab/process_fasta?style=for-the-badge)
![GitHub Repo stars](https://img.shields.io/github/stars/pavlohrab/process_fasta?style=for-the-badge)

This script is just a collection of one-liners, with which I was processing fasta sequences frequently. Therefore I made one single script out of them. All the one-liners are freely available on different forums.
# Dependencies
The script is inthended to be run under Linux, using only the basic bash functionality. The only one, that need to be installed is a perl programming language (must be available for pretty much any Linux distro) for adding numbers to duplicated headers. Also awk and sed must be installed (they should be installed by default, so no need to worry)
# Usage
The only mandatory flag is `-i <input-file>`. All other flags are optional. The general usage example is as such:

```bash
sh process_fasta.sh -i <input-file> ....
```
# Features
The full list of options for fasta processing is available under `sh process_fasta.sh -h`:
 ```
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

-c|--concatenate  - concatenate all the sequence in a multifasta file. 
                    Filename will be use as a fasta header.

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
 ```

