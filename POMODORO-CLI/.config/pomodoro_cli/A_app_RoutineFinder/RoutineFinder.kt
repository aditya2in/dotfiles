package com.example.routinefinder // Adjust package name as per your Android project

import android.content.Context
import android.util.Log
import java.io.File
import java.text.SimpleDateFormat
import java.util.*
import java.util.regex.Pattern

// Data class to hold the parsed routine information
data class RoutineInfo(
    val routineName: String = "No Routine",
    val categoryAction: String = "",
    val task: String = "",
    val subTask: String = "",
    val miniTask: String = ""
)

class RoutineFinder(private val context: Context) {

    private val TAG = "RoutineFinder"

    // --- Script Configuration (Adjust these paths for Android) ---
    // IMPORTANT: These paths need to be accessible by your Android app.
    // For a real app, you'd likely use Android's Storage Access Framework (SAF)
    // to let the user pick the vault folder, as direct file paths like /sdcard/Obsidian
    // might not be universally accessible or might require specific permissions (MANAGE_EXTERNAL_STORAGE)
    // which are highly restricted.
    // For this prototype, we'll assume direct access for simplicity.
    private val JOURNAL_DIR = "/sdcard/Obsidian/All Things/Journal/Daily Journal" // Example path
    private val OBSIDIAN_VAULT_ROOT = "/sdcard/Obsidian" // Example path

    private val current_date_format = SimpleDateFormat("yyyy-MM-dd", Locale.getDefault())

    fun findCurrentRoutine(): RoutineInfo {
        val currentDate = current_date_format.format(Date())
        val plannerFile = File(JOURNAL_DIR, "$currentDate.md")

        if (!plannerFile.exists()) {
            Log.w(TAG, "Journal file '${plannerFile.absolutePath}' not found.")
            return RoutineInfo(routineName = "Journal file not found.")
        }

        val lines = plannerFile.readLines()
        val activeRoutines = mutableListOf<Pair<Int, String>>() // Pair of (lineNum, description)

        val calendar = Calendar.getInstance()
        val currentHour = calendar.get(Calendar.HOUR_OF_DAY)
        val currentMinute = calendar.get(Calendar.MINUTE)
        val currentTimeInMinutes = currentHour * 60 + currentMinute

        Log.d(TAG, "Current time: $currentHour:$currentMinute ($currentTimeInMinutes minutes).")

        // Corrected regex to match bash script's capturing groups
        // Group 1: (.*) - text before time
        // Group 2: ([0-9]{2}:[0-9]{2}) - start time
        // Group 3: ([0-9]{2}:[0-9]{2}) - end time
        // Group 4: (.*) - text after time
        val timePattern = Pattern.compile("(.*)([0-9]{2}:[0-9]{2})\\s*-?\\s*([0-9]{2}:[0-9]{2})(.*)")

        lines.forEachIndexed { index, line ->
            val matcher = timePattern.matcher(line)
            if (matcher.matches()) {
                val routineTextBeforeTime = matcher.group(1) ?: ""
                val start = matcher.group(2) ?: ""
                val end = matcher.group(3) ?: ""
                val routineTextAfterTime = matcher.group(4) ?: ""

                val fullDescriptiveText = "$routineTextBeforeTime$routineTextAfterTime"
                // Remove leading checkbox pattern: "- [ ] "
                val description = fullDescriptiveText.replaceFirst("^[\\s]*- ?\\[ ?\\] ?".toRegex(), "").trim()

                val sh = start.substringBefore(":").toInt()
                val sm = start.substringAfter(":").toInt()
                val eh = end.substringBefore(":").toInt()
                val em = end.substringAfter(":").toInt()

                val startMin = sh * 60 + sm
                val endMin = eh * 60 + em

                Log.d(TAG, "  - Matched: Start='$start', End='$end', Desc='$description'")
                Log.d(TAG, "  - Start time in minutes: $startMin, End time in minutes: $endMin")

                if (startMin > endMin) { // Routine spans across midnight
                    Log.d(TAG, "  - Routine spans across midnight. Checking if current time ($currentTimeInMinutes) is >= $startMin OR < $endMin.")
                    if (currentTimeInMinutes >= startMin || currentTimeInMinutes < endMin) {
                        activeRoutines.add(Pair(index + 1, description))
                        Log.d(TAG, "  - Routine identified as ACTIVE (spans midnight): Line ${index + 1}, Desc: '$description'")
                    } else {
                        Log.d(TAG, "  - Routine NOT active (spans midnight).")
                    }
                } else { // Routine within same day
                    Log.d(TAG, "  - Routine within same day. Checking if current time ($currentTimeInMinutes) is >= $startMin AND < $endMin.")
                    if (currentTimeInMinutes >= startMin && currentTimeInMinutes < endMin) {
                        activeRoutines.add(Pair(index + 1, description))
                        Log.d(TAG, "  - Routine identified as ACTIVE: Line ${index + 1}, Desc: '$description'")
                    } else {
                        Log.d(TAG, "  - Routine NOT active (same day).")
                    }
                }
            } else {
                Log.d(TAG, "  - Line does not match routine time pattern: '$line'")
            }
        }

        if (activeRoutines.isEmpty()) {
            Log.d(TAG, "No active routine found.")
            return RoutineInfo(routineName = "No active routine found.")
        }

        // For simplicity, we'll take the first active routine found, similar to the shell script's behavior
        // if it only processes one. If multiple can be active, this logic needs refinement.
        val (routineLineNum, routineDescription) = activeRoutines.first()
        val fullRoutineLineContent = lines[routineLineNum - 1] // Adjust for 0-based index

        Log.d(TAG, "Processing active routine: Line $routineLineNum, Desc: '$routineDescription'")

        val collectedSubtasks = mutableListOf<String>()
        val collectedRoutineLinkedNotes = mutableListOf<String>()
        val collectedSubtaskLinkedNotes = mutableListOf<String>()

        // --- Extract linked notes from the full routine line content ---
        val rawRoutineNotes = "\\[\\[(.*?)\\]\\]".toRegex().findAll(fullRoutineLineContent).map { it.groupValues[1] }.toList()
        rawRoutineNotes.forEach { note ->
            collectedRoutineLinkedNotes.add(note)
            Log.d(TAG, "  - Found routine linked note: $note")
        }

        // --- Collect Subtasks and their Linked Notes ---
        val routineLeadingIndent = getLeadingSpaces(fullRoutineLineContent)
        for (i in routineLineNum until lines.size) {
            val lineContent = lines[i]
            if (lineContent.isBlank()) {
                Log.d(TAG, "  - Empty line encountered, stopping subtask scan for this routine.")
                break
            }

            val currentIndent = getLeadingSpaces(lineContent)
            if (currentIndent > routineLeadingIndent) {
                collectedSubtasks.add(lineContent)
                Log.d(TAG, "  - Collected subtask: '$lineContent'")

                val rawSubtaskNotes = "\\[\\[(.*?)\\]\\]".toRegex().findAll(lineContent).map { it.groupValues[1] }.toList()
                rawSubtaskNotes.forEach { note ->
                    collectedSubtaskLinkedNotes.add(note)
                    Log.d(TAG, "    - Collected subtask linked note: $note")
                }
            } else {
                Log.d(TAG, "  - Line has less or equal indentation, stopping subtask scan for this routine.")
                break
            }
        }

        // --- Tag Search Logic ---
        val tagDefinitions = mapOf(
            "#CurrentCategoryOrAction" to "Current Category/Action",
            "#CurrentTask" to "Current Task",
            "#CurrentSubTask" to "Current SubTask",
            "#CurrentMiniTask" to "Current MiniTask"
        )

        val tagDisplayOrder = listOf(
            "#CurrentCategoryOrAction",
            "#CurrentTask",
            "#CurrentSubTask",
            "#CurrentMiniTask"
        )

        val foundTagsResults = mutableMapOf<String, String>() // tag to cleaned content

        // Helper to resolve Obsidian note path (simplified for Android)
        // This currently only checks the root of the vault. For a real app, you'd need
        // a more robust search that traverses subdirectories or uses Obsidian's internal index.
        fun resolveObsidianNotePath(noteNameRaw: String): File? {
            val noteName = noteNameRaw.removePrefix("[[").removeSuffix("]]")
            val potentialFile = File(OBSIDIAN_VAULT_ROOT, "$noteName.md")
            if (potentialFile.exists()) {
                return potentialFile
            }
            // Basic case-insensitive search (might be slow for large vaults)
            // For a real app, consider indexing or more robust search
            File(OBSIDIAN_VAULT_ROOT).walkTopDown().forEach { file ->
                if (file.isFile && file.extension == "md" && file.nameWithoutExtension.equals(noteName, ignoreCase = true)) {
                    return file
                }
            }
            return null
        }

        // Search function
        fun searchForTag(content: String, tag: String): String? {
            if (content.contains(tag)) {
                // Clean the content similar to get_ultra_cleaned_tag_content from bash script
                var cleanedContent = content
                // Remove leading linked note pattern: "[[...]]: - "
                cleanedContent = cleanedContent.replaceFirst("\\[\\[.*?\\]\\]\\s*:\\s*-?\\s*".toRegex(), "")
                // Remove leading checkbox pattern: "- [ ] "
                cleanedContent = cleanedContent.replaceFirst("^[\\s]*-?\\s*\\[ ?\\]\\s*".toRegex(), "")
                // Remove the tag itself and trim whitespace
                cleanedContent = cleanedContent.replace(tag, "").trim()
                return cleanedContent
            }
            return null
        }

        for (tag in tagDisplayOrder) {
            if (foundTagsResults.containsKey(tag)) continue // "first match wins"

            // Priority 1: Subtasks
            for (subtaskContent in collectedSubtasks) {
                val cleaned = searchForTag(subtaskContent, tag)
                if (cleaned != null) {
                    foundTagsResults[tag] = cleaned
                    break
                }
            }
            if (foundTagsResults.containsKey(tag)) continue

            // Priority 2: Routine Linked Notes (content of the linked note file)
            for (noteNameRaw in collectedRoutineLinkedNotes) {
                val linkedNoteFile = resolveObsidianNotePath(noteNameRaw)
                if (linkedNoteFile != null && linkedNoteFile.exists()) {
                    val noteContent = linkedNoteFile.readText()
                    val cleaned = searchForTag(noteContent, tag)
                    if (cleaned != null) {
                        foundTagsResults[tag] = cleaned
                        break
                    }
                }
            }
            if (foundTagsResults.containsKey(tag)) continue

            // Priority 3: Subtask Linked Notes (content of the linked note file)
            for (noteNameRaw in collectedSubtaskLinkedNotes) {
                val linkedNoteFile = resolveObsidianNotePath(noteNameRaw)
                if (linkedNoteFile != null && linkedNoteFile.exists()) {
                    val noteContent = linkedNoteFile.readText()
                    val cleaned = searchForTag(noteContent, tag)
                    if (cleaned != null) {
                        foundTagsResults[tag] = cleaned
                        break
                    }
                }
            }
        }

        // Construct the final RoutineInfo object
        // The routineDescription already has the checkbox removed from the find_active_routine logic
        val finalRoutineName = routineDescription
        val finalCategoryAction = foundTagsResults["#CurrentCategoryOrAction"] ?: "No Category or Action"
        val finalTask = foundTagsResults["#CurrentTask"] ?: "No Task"
        val finalSubTask = foundTagsResults["#CurrentSubTask"] ?: "No Sub Task"
        val finalMiniTask = foundTagsResults["#CurrentMiniTask"] ?: "No Mini task"

        return RoutineInfo(
            routineName = finalRoutineName,
            categoryAction = finalCategoryAction,
            task = finalTask,
            subTask = finalSubTask,
            miniTask = finalMiniTask
        )
    }

    // Helper function to get leading spaces (Kotlin version)
    private fun getLeadingSpaces(line: String): Int {
        // Replace tabs with 4 spaces for consistency with Markdown
        val lineWithSpacesOnly = line.replace("\t", "    ")
        val matcher = "^( *)".toRegex().find(lineWithSpacesOnly)
        return matcher?.groupValues?.get(1)?.length ?: 0
    }
}