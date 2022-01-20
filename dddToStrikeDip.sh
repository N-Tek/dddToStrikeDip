#!/bin/bash

# dddToStrikeDip.sh - Script that converts dip/dip_direction measurements to strike/dip
# Copyright © 2022 Necib ÇAPAR <necipcapar@gmail.com>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

if [ $# -eq 0 ]; then
    printf "Usage: %s (-a | -b | -A | -B) [-r] (MEASUREMENT | MEASUREMENT_FILE)...\n" "$0"
    printf "%s\n%s\n%s\n%s\n%s\n%s\n" \
	"       -a    strike in    RHR-azimuth format,  dip direction 90⁰ clockwise from strike" \
	"       -b    strike in    RHR-bearing format,  dip direction 90⁰ clockwise from strike" \
	"       -A    strike in UK-RHR-azimuth format,  dip direction 90⁰ counter-clockwise from strike" \
	"       -B    strike in UK-RHR-bearing format,  dip direction 90⁰ counter-clockwise from strike" \
	"       -d DELIM   use DELIM instead of space as the delimiter of output values" \
	"       -r    print out number of converted and invalid measurements" \
	"       -h    Display help"
    exit 1
fi

converted_measurement=0
converted_infile_measurement=0
invalid_measurement=0
invalid_infile_measurement=0

# ----------------------------- FUNCTION DEFINITIONS ----------------------------- 

check_d_dd_measurement(){
    if [[ "$1" =~ ^[[:digit:]]{1,2}/[[:digit:]]{3}$ ]]; then    # check d/dd format - max 2digit / 3 digit
	if [ $(echo "$1" | cut -d'/' -f 1 -) -gt 90  -o \
	     $(echo "$1" | cut -d'/' -f 2 -) -gt 360 ]; then           
	    return 1
	else
	    return 0
	fi
    else
	return 1
    fi
}

convert_measurement_to_RHR_azimuth(){
    # convert from string to integer
    declare -i dip=$(( 10#$(echo $1 | cut -d '/' -f 1 -) ))
    declare -i dip_direction=$(( 10#$(echo $1 | cut -d '/' -f 2 -) ))

    # convert dip direction to strike with RHR-azimuth (dd 90⁰ CW from strike)
    declare -i strike=$(( ($dip_direction - 90) < 0 ? ($dip_direction - 90 + 360) : ($dip_direction - 90) ))

    # determine direction of dip
    declare direction_of_dip=
    if (( $dip_direction % 360 == 0 )); then 
	direction_of_dip="N"
    elif (( $dip_direction < 90 )); then 
	direction_of_dip="NE"
    elif (( $dip_direction == 90 )); then
	direction_of_dip="E"
    elif (( $dip_direction < 180)); then 
	direction_of_dip="SE"
    elif (( $dip_direction == 180)); then 
	direction_of_dip="S"
    elif (( $dip_direction < 270)); then 
	direction_of_dip="SW"
    elif (( $dip_direction == 270)); then 
	direction_of_dip="W"
    else
	direction_of_dip="NW"
    fi

    if [ -z "$dflag" ]; then
	printf "%03d/%d%s " "$strike" "$dip" "$direction_of_dip"
    else
	printf "%03d/%d%s%s" "$strike" "$dip" "$direction_of_dip" "$dval"
    fi
}

convert_measurement_to_RHR_bearing(){
    #convert from string to integer
    declare -i dip=$(( 10#$(echo $1 | cut -d '/' -f 1 -) ))
    declare -i dip_direction=$(( 10#$(echo $1 | cut -d '/' -f 2 -) ))

    # convert dip direction to strike with RHR-bearing (dd 90⁰ CW from strike)
    # determine direction of dip
    declare strike=
    declare direction_of_dip=
    if (( $dip_direction % 360 == 0 )); then 
	strike="N90W"
	direction_of_dip="N"
    elif (( $dip_direction < 90 )); then 
	strike="N$(( 90 - $dip_direction ))W"
	direction_of_dip="NE"
    elif (( $dip_direction == 90 )); then
	strike="N0W"
	direction_of_dip="E"
    elif (( $dip_direction < 180 )); then 
	strike="N$(( $dip_direction - 90 ))E"
	direction_of_dip="SE"
    elif (( $dip_direction == 180 )); then 
	strike="N90E"
	direction_of_dip="S"
    elif (( $dip_direction < 270 )); then 
	strike="S$(( 270 - $dip_direction ))E"
	direction_of_dip="SW"
    elif (( $dip_direction == 270 )); then 
	strike="S0E"
	direction_of_dip="W"
    else
	strike="S$(( $dip_direction - 270 ))W"
	direction_of_dip="NW"
    fi

    if [ -z "$dflag" ]; then
	printf "%s/%d%s " "$strike" "$dip" "$direction_of_dip"
    else
	printf "%s/%d%s%s" "$strike" "$dip" "$direction_of_dip" "$dval"
    fi
}

convert_measurement_to_UK_RHR_azimuth(){
    #convert from string to integer
    declare -i dip=$(( 10#$(echo $1 | cut -d '/' -f 1 -) ))
    declare -i dip_direction=$(( 10#$(echo $1 | cut -d '/' -f 2 -) ))

    # convert dip direction to strike with UK-RHR-azimuth (dd 90⁰ CCW from strike)
    declare -i strike=$(( ($dip_direction + 90) % 360 ))

    # determine direction of dip 
    declare direction_of_dip=
    if (( $dip_direction % 360 == 0 )); then 
	direction_of_dip="N"
    elif (( $dip_direction < 90 )); then 
	direction_of_dip="NE"
    elif (( $dip_direction == 90 )); then
	direction_of_dip="E"
    elif (( $dip_direction < 180 )); then 
	direction_of_dip="SE"
    elif (( $dip_direction == 180 )); then 
	direction_of_dip="S"
    elif (( $dip_direction < 270 )); then 
	direction_of_dip="SW"
    elif (( $dip_direction == 270 )); then 
	direction_of_dip="W"
    else
	direction_of_dip="NW"
    fi

    if [ -z "$dflag" ]; then
	printf "%03d/%d%s " "$strike" "$dip" "$direction_of_dip"
    else
	printf "%03d/%d%s%s" "$strike" "$dip" "$direction_of_dip" "$dval"
    fi
}

convert_measurement_to_UK_RHR_bearing(){
    #convert from string to integer
    declare -i dip=$(( 10#$(echo $1 | cut -d '/' -f 1 -) ))
    declare -i dip_direction=$(( 10#$(echo $1 | cut -d '/' -f 2 -) ))

    # convert dip direction to strike with UK-RHR-bearing (dd 90⁰ CCW from strike)
    # and determine direction of dip
    declare strike=
    declare direction_of_dip=
    if (( $dip_direction % 360 == 0 )); then 
	strike="N90E"
	direction_of_dip="N"
    elif (( $dip_direction < 90 )); then 
	strike="S$(( 90 - $dip_direction ))E"
	direction_of_dip="NE"
    elif (( $dip_direction == 90 )); then
	strike="S0E"
	direction_of_dip="E"
    elif (( $dip_direction < 180 )); then 
	strike="S$(( $dip_direction - 90  ))W"
	direction_of_dip="SE"
    elif (( $dip_direction == 180 )); then 
	strike="N90W"
	direction_of_dip="S"
    elif (( $dip_direction < 270 )); then 
	strike="N$(( 270 - $dip_direction ))W"
	direction_of_dip="SW"
    elif (( $dip_direction == 270 )); then 
	strike="N0E"
	direction_of_dip="W"
    else
	strike="N$(( $dip_direction - 270 ))E"
	direction_of_dip="NW"
    fi

    if [ -z "$dflag" ]; then
	printf "%s/%d%s " "$strike" "$dip" "$direction_of_dip"
    else
	printf "%s/%d%s%s" "$strike" "$dip" "$direction_of_dip" "$dval"
    fi
}

read_file(){
    while read line
    do
	check_d_dd_measurement "$line"
	if [ $? -eq 0 ]; then
	    if [ ! -z "$2" ]; then
		convert_measurement_to_RHR_azimuth "$line" "$6"
	    fi
	    if [ ! -z "$3" ]; then
		convert_measurement_to_RHR_bearing "$line" "$6"
	    fi
	    if [ ! -z "$4" ]; then
		convert_measurement_to_UK_RHR_azimuth "$line" "$6"
	    fi
	    if [ ! -z "$5" ]; then
		convert_measurement_to_UK_RHR_bearing "$line" "$6"
	    fi

	    printf "\n"
	    (( converted_infile_measurement++ ))
	else
	    (( invalid_infile_measurement++ ))
	fi
    done < "$1"
}

read_measurement(){
    check_d_dd_measurement "$1"
    if [ $? -eq 0 ]; then
	if [ ! -z "$2" ]; then
	    convert_measurement_to_RHR_azimuth "$1" "$6"
	fi
	if [ ! -z "$3" ]; then
	    convert_measurement_to_RHR_bearing "$1" "$6"
	fi
	if [ ! -z "$4" ]; then
	    convert_measurement_to_UK_RHR_azimuth "$1" "$6"
	fi
	if [ ! -z "$5" ]; then
	    convert_measurement_to_UK_RHR_bearing "$1" "$6"
	fi

	printf "\n"
	(( converted_measurement++ ))
    else
	(( invalid_measurement++ ))
    fi
}

print_conversion_report(){
    printf "%s%d\n%s%d\n%s%d\n%s%d\n" \
	"Converted Infile : " "$converted_infile_measurement" \
	"Invalid   Infile : " "$invalid_infile_measurement" \
	"Converted        : " "$converted_measurement" \
	"Invalid          : " "$invalid_measurement"
}

# -------------------------------------------------------------------------------- 

declare aflag=
declare bflag=
declare Aflag=
declare Bflag=
declare dflag=
declare rflag=

while getopts ":aAbBd:rh" name
do
    case "$name"
	in
	a) aflag=1 ;;
	b) bflag=1 ;;
	A) Aflag=1 ;;
	B) Bflag=1 ;;
	d) dflag=1
	    dval="$OPTARG" ;;
	:) echo "[ERROR] : Missing DELIM for option -$OPTARG" 1>&2
	    exit 5 ;;
	r) rflag=1 ;;
	\?) echo "[ERROR] : Unknown option -$OPTARG" 1>&2
	    printf "          Usage: %s (-a | -b | -A | -B) [-r] (MEASUREMENT | MEASUREMENT_FILE)...\n" "$0"
	    printf "%s\n%s\n%s\n%s\n%s\n%s\n" \
		"                 -a    strike in    RHR-azimuth format,  dip direction 90⁰ clockwise from strike" \
		"                 -b    strike in    RHR-bearing format,  dip direction 90⁰ clockwise from strike" \
		"                 -A    strike in UK-RHR-azimuth format,  dip direction 90⁰ counter-clockwise from strike" \
		"                 -B    strike in UK-RHR-bearing format,  dip direction 90⁰ counter-clockwise from strike" \
		"                 -d DELIM   use DELIM instead of space as the delimiter of output values" \
		"                 -r    print out number of converted and invalid measurements" \
		"                 -h    Display help"
	    exit 2 ;;
	h|*) printf "Usage: %s (-a | -b | -A | -B) [-r] (MEASUREMENT | MEASUREMENT_FILE)...\n" "$0"
	    printf "%s\n%s\n%s\n%s\n%s\n%s\n" \
		"       -a    strike in    RHR-azimuth format,  dip direction 90⁰ clockwise from strike" \
		"       -b    strike in    RHR-bearing format,  dip direction 90⁰ clockwise from strike" \
		"       -A    strike in UK-RHR-azimuth format,  dip direction 90⁰ counter-clockwise from strike" \
		"       -B    strike in UK-RHR-bearing format,  dip direction 90⁰ counter-clockwise from strike" \
		"       -d DELIM   use DELIM instead of space as the delimiter of output values" \
		"       -r    print out number of converted and invalid measurements" \
		"       -h    Display help"
	    exit 0 ;;
    esac
done
shift $((OPTIND - 1))

if [ -z "$aflag"  -a  -z "$bflag"  -a  -z "$Aflag"  -a  -z "$Bflag" ]; then
    echo "[ERROR] : Must pick an output format (-a | -b | -A | -B)" 1>&2
    exit 3
fi

if [ -z "$1" ];then
    echo "[ERROR] : Must use at least one MEASUREMENT | MEASUREMENT_FILE as input" 1>&2
    exit 4
fi

for arg
do
    if [ -f "$1" ]; then
	read_file "$1" "$aflag" "$bflag" "$Aflag" "$Bflag" "$dflag"
    else
	read_measurement "$1" "$aflag" "$bflag" "$Aflag" "$Bflag" "$dflag"
    fi

    shift
done

if [ ! -z $rflag ];then
    print_conversion_report
fi
