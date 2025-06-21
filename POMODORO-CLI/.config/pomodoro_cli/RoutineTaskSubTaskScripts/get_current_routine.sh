#!/bin/bash

# Get the current date in Букмекерлар-MM-DD format
current_date=$(date +%Y-%m-%d)

# Define the planner file name using the current date variable
PLANNER_FILE="/home/aditya/obsidian/All Things/Journal/Daily Journal/${current_date}.md"

# Define a static output file name
OUTPUT_FILE="current_routine.txt"

# Inform user about the output file location before starting, and overwrite the file
echo "🚀 Script will capture logs into: $(pwd)/$OUTPUT_FILE" > "$OUTPUT_FILE"
echo "Starting Routine retrieval for $current_date at $(date)" | tee -a "$OUTPUT_FILE"
echo "--------------------------------------------------------" | tee -a "$OUTPUT_FILE"

# Get the current hour and minute
current_hour=$(date +%H)
current_minute=$(date +%M)

# Convert current time to total minutes from midnight
current_total_minutes=$((10#$current_hour * 60 + 10#$current_minute))

# Check if the planner file exists
if [ ! -f "$PLANNER_FILE" ]; then
    echo "Error: Planner file '$PLANNER_FILE' not found for today!" | tee -a "$OUTPUT_FILE"
    echo "Please make sure a planner file for today exists at that path." | tee -a "$OUTPUT_FILE"
    exit 1
fi

# Initialize an empty array to store all matched routine descriptions
matched_routines=()

# Loop through the planner file line by line
while IFS= read -r line || [[ -n "$line" ]]; do
    # Check if the line contains a time pattern (e.g., "HH:MM - HH:MM")
    if [[ "$line" =~ ([0-9]{2}:[0-9]{2})\ -\ ([0-9]{2}:[0-9]{2}) ]]; then
        start_time_str="${BASH_REMATCH[1]}"
        end_time_str="${BASH_REMATCH[2]}"

        routine_description_raw="${line#*- \[ \] }"
        # Use sed to remove ONLY the time pattern, keeping any text that follows it.
        # Use xargs to aggressively trim leading/trailing whitespace, including non-breaking spaces
        routine_description_final=$(echo "$routine_description_raw" | sed -E 's/\s*([0-9]{2}:[0-9]{2})\s*-\s*([0-9]{2}:[0-9]{2})\s*//' | xargs)

        # Extract hour and minute from start time
        start_hour=${start_time_str%:*}
        start_minute=${start_time_str#*:}

        # Extract hour and minute from end time
        end_hour=${end_time_str%:*}
        end_minute=${end_time_str#*:}

        # Convert start and end times to total minutes from midnight
        start_total_minutes=$((10#$start_hour * 60 + 10#$start_minute))
        end_total_minutes=$((10#$end_hour * 60 + 10#$end_minute))

        # Check if current time falls within the routine's time slot
        # This condition handles both normal and cross-midnight routines
        if (( current_total_minutes >= start_total_minutes && current_total_minutes < end_total_minutes )) || \
           ( (( end_total_minutes < start_total_minutes )) && \
             ( (current_total_minutes >= start_total_minutes) || (current_total_minutes < end_total_minutes) ) ) ; then

            # Add the trimmed routine's description to our array
            matched_routines+=("$routine_description_final")
        fi
    fi
done < "$PLANNER_FILE"

# After looping through the entire file, determine the output based on matched_routines array
if [ ${#matched_routines[@]} -gt 0 ]; then
    # If one or more routines were found
    if [ ${#matched_routines[@]} -eq 1 ]; then
        found_routine="Currently scheduled Routine:"
        routine_details="${matched_routines[0]}" # If only one, no need to join
    else
        found_routine="Currently scheduled Routine(s):"
        # Pure Bash loop to join all matched routines with " | "
        routine_details=""
        separator=""
        for routine_item in "${matched_routines[@]}"; do
            routine_details+="${separator}${routine_item}"
            separator=" | "
        done
    fi
else
    # No routines found for the current time - Changed to "NONE"
    found_routine="NONE"
    routine_details=""
fi


echo "--------------------------------------------------------" | tee -a "$OUTPUT_FILE"
if [[ "$found_routine" == "Currently scheduled Routine:" || "$found_routine" == "Currently scheduled Routine(s):" ]]; then
    echo "$routine_details" | tee -a "$OUTPUT_FILE"
else
    echo "$found_routine" | tee -a "$OUTPUT_FILE"
fi
echo "--------------------------------------------------------" | tee -a "$OUTPUT_FILE"
echo "Script finished at $(date)" | tee -a "$OUTPUT_FILE"
echo "Output captured in: $(pwd)/$OUTPUT_FILE" | tee -a "$OUTPUT_FILE"
