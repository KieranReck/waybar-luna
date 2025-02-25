#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"
OUTPUT_FILE="$SCRIPT_DIR/tmp/current_output"
LOCK_FILE="$SCRIPT_DIR/tmp/animating.lock"

# Ensure the tmp directory exists
mkdir -p "$SCRIPT_DIR/tmp"

# Reference date: January 6, 2000
date1="2000-01-06"
# Current date
date2=$(date +'%Y-%m-%d')
# Convert dates to seconds since 1970-01-01
d1=$(date -d "$date1" +%s)
d2=$(date -d "$date2" +%s)
# Calculate difference in seconds and convert to days
daysSince=$(( (d2 - d1) / 86400 ))

# Length of a synodic month (in seconds)
synodicMonth=29.53058770576

# Calculate moon age using modulo operation
moonDay=$(awk "BEGIN {print (($daysSince) % $synodicMonth)}")
moonAge=$(awk "BEGIN {print $moonDay / $synodicMonth * 100.0}")

# Initialize counter file if it doesn't exist
if [[ ! -f "$OUTPUT_FILE" ]]; then
    echo $moonAge > "$OUTPUT_FILE"
fi

# Check for the prescence of a lock file which would indicate we are animating
# If it has somehow been around for too long, remove it to free up the script
if [[ -f "$LOCK_FILE" ]]; then
    current_time=$(date +%s)
    file_mod_time=$(stat -c %Y "$LOCK_FILE")
    time_diff=$((current_time - file_mod_time))
    
    # If the file is older than 1 minute (60 seconds), remove it
    # useful in the event that the animation was interrupted somehow
    # otherwise it might get perpetually stuck
    if (( time_diff > 60 )); then
        rm "$LOCK_FILE"
    fi
else
    # If the lock file doesn't exist, initialize OUTPUT_FILE with the current moon age
    echo $moonAge > "$OUTPUT_FILE"
fi


# If we pass 'animate' to the script
if [[ "$1" == "animate" ]]; then
    touch "$LOCK_FILE"
    for i in $(seq 0 12.5 200); do
            result=$(awk "BEGIN {print $moonAge + $i}")
            if [[ "$result" > "100" ]]; then
                result=$(awk "BEGIN {print $result % 100}")
            fi
        echo $result # good for troubleshooting in terminal
        echo $result > "$OUTPUT_FILE"
        pkill -SIGRTMIN+10 waybar # Notify Waybar to update instantly
        sleep 0.01 # animation speed - note: waybar signal stuff, and therefore animation speed) seems to be affected by whether your laptop is charging. Maybe power profiles related?
    done
    rm -f "$LOCK_FILE"
    exit 0
fi

# Determine the moon phase type
# This has to be done separate to the statements below to stop it changing during animation
if [ $(echo "$moonDay > 0" | bc) -eq 1 ] && [ $(echo "$moonDay <= 1" | bc) -eq 1 ]; then
    moonType="New Moon"
elif [ $(echo "$moonDay > 1" | bc) -eq 1 ] && [ $(echo "$moonDay <= 6.382647" | bc) -eq 1 ]; then
    moonType="Waxing Crescent"
elif [ $(echo "$moonDay > 6.382647" | bc) -eq 1 ] && [ $(echo "$moonDay <= 8.382647" | bc) -eq 1 ]; then
    moonType="First Quarter"
elif [ $(echo "$moonDay > 8.382647" | bc) -eq 1 ] && [ $(echo "$moonDay <= 13.765294" | bc) -eq 1 ]; then
    moonType="Waxing Gibbous"
elif [ $(echo "$moonDay > 13.765294" | bc) -eq 1 ] && [ $(echo "$moonDay <= 15.765294" | bc) -eq 1 ]; then
    moonType="Full Moon"
elif [ $(echo "$moonDay > 15.765294" | bc) -eq 1 ] && [ $(echo "$moonDay <= 21.147941" | bc) -eq 1 ]; then
    moonType="Waning Gibbous"
elif [ $(echo "$moonDay > 21.147941" | bc) -eq 1 ] && [ $(echo "$moonDay <= 23.147941" | bc) -eq 1 ]; then
    moonType="Third Quarter"
elif [ $(echo "$moonDay > 23.147941" | bc) -eq 1 ] && [ $(echo "$moonDay <= 28.530588" | bc) -eq 1 ]; then
    moonType="Waning Crescent"
elif [ $(echo "$moonDay > 28.530588" | bc) -eq 1 ] && [ $(echo "$moonDay <= 29.530588" | bc) -eq 1 ]; then
    moonType="New Moon"
else
    moonPhase="!!lunaError!!"
fi

# get the value written to the output file earlier to determine which phase currently needs to be displayed
current_value=$(cat "$OUTPUT_FILE")
# turn it into a 'day' rather than a percentage (I used to use percentage for display on waybar, but it turns out the moons phases arent the same length)
current_day=$(awk "BEGIN {print (($current_value / 100) * $synodicMonth)}")

#---PHASE LENGTHS: OPTION 1(default) - EQUAL SPACING---
# Determine the moon phase symbol - Phase lengths here matche those on Omni Calc https://www.omnicalculator.com/everyday-life/moon-phase
if [ $(echo "$current_day > 0" | bc) -eq 1 ] && [ $(echo "$current_day <= 1" | bc) -eq 1 ]; then
    moonPhase="1"
    #moonType="New Moon"
elif [ $(echo "$current_day > 1" | bc) -eq 1 ] && [ $(echo "$current_day <= 6.382647" | bc) -eq 1 ]; then
    moonPhase="2"
    #moonType="Waxing Crescent"
elif [ $(echo "$current_day > 6.382647" | bc) -eq 1 ] && [ $(echo "$current_day <= 8.382647" | bc) -eq 1 ]; then
    moonPhase="3"
    #moonType="First Quarter"
elif [ $(echo "$current_day > 8.382647" | bc) -eq 1 ] && [ $(echo "$current_day <= 13.765294" | bc) -eq 1 ]; then
    moonPhase="4"
    #moonType="Waxing Gibbous"
elif [ $(echo "$current_day > 13.765294" | bc) -eq 1 ] && [ $(echo "$current_day <= 15.765294" | bc) -eq 1 ]; then
    moonPhase="5"
    #moonType="Full Moon"
elif [ $(echo "$current_day > 15.765294" | bc) -eq 1 ] && [ $(echo "$current_day <= 21.147941" | bc) -eq 1 ]; then
    moonPhase="6" 
    #moonType="Waning Gibbous"
elif [ $(echo "$current_day > 21.147941" | bc) -eq 1 ] && [ $(echo "$current_day <= 23.147941" | bc) -eq 1 ]; then
    moonPhase="7"
    #moonType="Third Quarter"
elif [ $(echo "$current_day > 23.147941" | bc) -eq 1 ] && [ $(echo "$current_day <= 28.530588" | bc) -eq 1 ]; then
    moonPhase="8"
    #moonType="Waning Crescent"
elif [ $(echo "$current_day > 28.530588" | bc) -eq 1 ] && [ $(echo "$current_day <= 29.530588" | bc) -eq 1 ]; then
    moonPhase="9"
    #moonType="New Moon"
else
    moonPhase="!!lunaError!!"
fi

#---PHASE LENGTHS: OPTION 2 - SIGNIFICANT QUARTERS---
# Determine the moon phase symbol - Phase lengths for 1st Quarter, Full, 3rd Quarter, and New moon are only a single day, so that they look special
# If you want to use this option, comment out '<<COMMENT' and 'COMMENT', aka uncommenting the whole section below
: <<'COMMENT'
# <--- comment this out if you want to use
#ALTERNATE SPACING where significant stages only last for a single day
# this is cool, for example, if you want to know at a glance whether the moon is 'exactly' full/new
# **to use, remove the "<<comment" above, and "comment" below
crescentAndGibbousLength=6.382646926
if [ $(echo "$current_day > 0" | bc) -eq 1 ] && [ $(echo "$current_day <= 0.5" | bc) -eq 1 ]; then
    moonPhase="1"
    #moonType="New Moon"
elif [ $(echo "$current_day > 0.5" | bc) -eq 1 ] && [ $(echo "$current_day <= 0.5+$crescentAndGibbousLength" | bc) -eq 1 ]; then
    moonPhase="2"
    #moonType="Waxing Crescent"
elif [ $(echo "$current_day > 0.5+$crescentAndGibbousLength" | bc) -eq 1 ] && [ $(echo "$current_day <= 1.5+$crescentAndGibbousLength" | bc) -eq 1 ]; then
    moonPhase="3"
    #moonType="First Quarter"
elif [ $(echo "$current_day > 1.5+$crescentAndGibbousLength" | bc) -eq 1 ] && [ $(echo "$current_day <= 1.5+(2*$crescentAndGibbousLength)" | bc) -eq 1 ]; then
    moonPhase="4"
    #moonType="Waxing Gibbous"
elif [ $(echo "$current_day > 1.5+(2*$crescentAndGibbousLength)" | bc) -eq 1 ] && [ $(echo "$current_day <= 2.5+(2*$crescentAndGibbousLength)" | bc) -eq 1 ]; then
    moonPhase="5"
    #moonType="Full Moon"
elif [ $(echo "$current_day > 2.5+(2*$crescentAndGibbousLength)" | bc) -eq 1 ] && [ $(echo "$current_day <= 2.5+(3*$crescentAndGibbousLength)" | bc) -eq 1 ]; then
    moonPhase="6" 
    #moonType="Waning Gibbous"
elif [ $(echo "$current_day > 2.5+(3*$crescentAndGibbousLength)" | bc) -eq 1 ] && [ $(echo "$current_day <= 3.5+(3*$crescentAndGibbousLength)" | bc) -eq 1 ]; then
    moonPhase="7"
    #moonType="Third Quarter"
elif [ $(echo "$current_day > 3.5+(3*$crescentAndGibbousLength)" | bc) -eq 1 ] && [ $(echo "$current_day <= 3.5+(4*$crescentAndGibbousLength)" | bc) -eq 1 ]; then
    moonPhase="8"
    #moonType="Waning Crescent"
elif [ $(echo "$current_day > 3.5+(2*$crescentAndGibbousLength)" | bc) -eq 1 ] && [ $(echo "$current_day <= $synodicMonth" | bc) -eq 1 ]; then
    moonPhase="9"
    #moonType="New Moon"
else
    moonPhase="!!lunaError!!"
fi
COMMENT
# <--- comment the above out if you want to use

# round moonDay to no decimal places for a nicer tooltip text
moonDay=$(printf "%.0f" "$moonDay")

# echo out the JSON formatted output for waybar to use
echo "{\"alt\": \"$moonPhase\", \"tooltip\":\"$moonType (~$moonDay days)\", \"percentage\":\"$current_value\"}"

# List of moon phase emojis, just in case you need them
# 🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘 🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘 🌑
