#!/usr/bin/env bash
#
# sap500.sh - Fetch an S&P 500 constituents CSV and print
#   Company Name, Headquarters Location, Founding Year
# sorted by founding year (ascending).
#
# Usage:
#   ./sap500.sh [CSV_URL]
#
# Defaults to the datasets/s-and-p-500-companies constituents CSV.

set -euo pipefail

URL="${1:-https://raw.githubusercontent.com/datasets/s-and-p-500-companies/refs/heads/main/data/constituents.csv}"

curl -fsSL "$URL" | awk -F',' '
BEGIN {
    OFS = "\t"
}

# Split a CSV line into fields, honoring double-quoted cells.
function parse_csv(str, arr,    i, c, n, field, in_quotes) {
    n = 0
    field = ""
    in_quotes = 0
    for (i = 1; i <= length(str); i++) {
        c = substr(str, i, 1)
        if (in_quotes) {
            if (c == "\"") {
                if (substr(str, i + 1, 1) == "\"") {
                    field = field "\""
                    i++
                } else {
                    in_quotes = 0
                }
            } else {
                field = field c
            }
        } else {
            if (c == "\"") {
                in_quotes = 1
            } else if (c == ",") {
                n++
                arr[n] = field
                field = ""
            } else {
                field = field c
            }
        }
    }
    n++
    arr[n] = field
    return n
}

NR == 1 {
    # Print header, then skip the CSV header row.
    print "Founded", "Company Name", "Headquarters Location"
    next
}

{
    fields = parse_csv($0, f)

    # Column layout: 1=Symbol 2=Security 3=GICS Sector 4=GICS Sub-Industry
    #                5=Headquarters Location 6=Date added 7=CIK 8=Founded
    name    = f[2]
    hq      = f[5]
    founded = f[8]

    # Extract the first 4-digit year (handles values like "2013 (1888)").
    if (founded ~ /[0-9][0-9][0-9][0-9]/) {
        match(founded, /[0-9][0-9][0-9][0-9]/)
        year = substr(founded, RSTART, RLENGTH)
    } else {
        year = founded
    }

    print year "\t" name "\t" hq
}
' | sort -n -k1,1
