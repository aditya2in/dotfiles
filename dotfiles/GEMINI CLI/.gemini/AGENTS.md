--- Context from: .gemini/GEMINI.md ---
### **Recommended `GEMINI.md` Instructions for the CLI**

- check instructions.md and follow it as well along with GEMINI.md files
- if there is any process done differently from GEMINI.md and instructions.md file then ask me if you need update the files or not.
- for any new instrction to process ask me if you need to update this instrction or chnage in process to GEMINI.md file (if there is a GEMINI.md file in same folder then prefer to update that folder specific GEMINI.md unless i say to update the original file)
- chat with me for all request atlest 2 or 3 questions based on necessifty and take clear inputs from me then start taking actions.

#### **1. Code and File Modification Rules (Most Effective)**

These are the most impactful rules for the CLI, as they involve direct actions with files and code.

- **Always Backup Before Editing:** Before modifying any file, create a timestamped backup.
  - **Your Rule:** "if there is a modification to the file definitely you take a backup of the file in timestamped format (`$(date +%Y%m%d_%H%M%S)` postfix for the backup file before modifying it."
  - **CLI Action:** I will run a backup command like `cp <file> <file>.bak`. I will use a static backup name because the shell environment does not permit dynamic command substitution for security reasons.
- **Comment Out Old Code:** When replacing code, comment out the old lines instead of deleting them for user reference.
- **Provide Full Context and Testing Steps:** After a modification, explain how to test the changes and provide the full, modified code if requested.
  - **Example Rule:** "After modifying a file, provide a section named '🧪 **HOW TO TEST THE CHANGES**' with step-by-step instructions for verification."
- **Analyze Impact:** When changing code, explain what other parts of the system might be affected.
- **DELETE ALERT:** Before executing a command that deletes any lines from a file, I must begin my reply with a `DELETE ALERT:` heading. Under this heading, I will explain which lines are being deleted and why.

#### **2. Content and Explanation Style**

These rules help ensure the text-based output is clear and useful.

- **QUICK ANSWER & QUICK SUGGESTION Section:** Every response must start with a `QUICK ANSWER:` heading, with a summary of the information or action in the response (minimum one line). Next to it, a `QUICK SUGGESTION:` heading will show suggestions from Gemini.
- **Provide Comprehensive Explanations:** Explain topics and commands in detail, including full paths and the purpose of commands.
- **Use Visuals (Text-Based):** When explaining hierarchies or ecosystems (e.g., comparing `cmake` vs. `make`), use text-based tree diagrams.
  - **Example Rule:** "Use text-based diagrams to show relationships, like this:
    ```
    Build Tools
    ├── Make
    │   └── Makefile
    └── CMake
        └── CMakeLists.txt
    ```
- **Structure with Headings and Icons:** Use bold, capitalized headings with a relevant emoji to structure your responses.
- **Vertical-Friendly Tables:** For tabular data, use a definition list or other vertical format that is easy to read on a narrow screen. Avoid wide Markdown tables.
#### **3. Troubleshooting and Interaction**

- **Request More Information Clearly:** If you need more context (like logs or config files), create a specific section asking for it and wait for the user to provide it.
  - **Example Rule:** "If you need more information, create a heading '⚠️ **MORE INFORMATION REQUIRED**' and list exactly what you need."
- **Provide Log Collection Scripts:** If you need logs, provide a complete, copy-pasteable shell script that saves the output to a file and prints the file's location.

#### **4. Learning and Workflow Enhancement**

- **Alternative Approaches:** When you ask how to do something, also provide a section named "**💡 ALTERNATIVE APPROACHES**" that describes other methods to achieve the same goal, including their pros and cons.
- **Potential Pitfalls:** For any complex command or code change, add a section called "**🤔 WHAT COULD GO WRONG? (POTENTIAL PITFALLS)**" to help anticipate and avoid common errors.
- **Logical Next Step:** After successfully completing a task, proactively suggest a logical next action under the heading "**🚀 LOGICAL NEXT STEP**" to help guide the workflow.

---
- All backups should be placed in a backups/ directory within the same directory as the file being backed up.
- User prefers timestamped backup file names in the format YYYYMMDD_HHMMSS_filename.bak

## Rules from POMODORO-CLI-application

# Rules

1. For all changes to shell file thich is main file here.
   1. you make update the documentation.md file and see if this file is in sync with the app always.
   2. make a backup file for the file with date time sec based exteniosn in backups folder uisng cp command in to backups folder.
   3. there is no use of readinf contetns of files in backups fodlers
   4. only read file names if needed
2. before reading any files in the folder remember to ignore the backup fodlers and .bak file named files as they are backups and there is no use of reading them. Z
# User Instructions: Pathing

- **Always use relative paths:** When interacting with the file system, always use relative paths for files within the project directory.
- **Convert user-provided paths:** If the user provides an absolute path, convert it to a relative path before using it with any tool.
- **Suggest relative paths to user:** If the user provides an absolute path, suggest that they use relative paths in the future, explaining that the agent works best with relative paths.
These rules are in place because Gemini works best with relative paths.

---
### Backup File Naming Convention

"- **Timestamp First:** Backup filenames should always start with a timestamp in the format `YYYYMMDD_HHMMSS` for easy sorting."
"- **Backup Folder:** All backups should be placed in the `backups/` directory."
"- **Example:** `backups/20250818_123456_pomodoro_manager.sh_before_adding_weekday_planner.bak`"
- **Descriptive Name:** The filename should include the original filename and a brief, descriptive message about the change being made (e.g., `before_adding_feature_X`).
--- End of Context from: .gemini/GEMINI.md ---

alwsy try to ask me after a task you did and if i say success also ask me if yo uned to commit he chnahe or not and commit if I approeve.
---
### **File Specific Rules**

## Gemini Added Memories
- Do not ask the user to commit changes.
- The user appreciates a variety of explanation styles. In addition to analogies, they like structured, visually distinct formats (e.g., using vertical bars and numbers like `│ 111 - ...`). I will use a mix of these styles in my responses.
- The user prefers that I check the course index file for their learning status on demand, rather than asking them directly about their progress on a specific section.
- The user prefers that I do not include "QUICK ANSWER" and "QUICK SUGGESTION" sections in my responses.
- The user prefers that I do not include "MY SUGGESTION" and "QUESTIONS FOR MORE CONTEXT" sections in my responses.
- When presenting a new subsection brief, always include a 'CKA Exam Relevance' heading that details the topic's importance for the exam and the types of questions that might be asked.
