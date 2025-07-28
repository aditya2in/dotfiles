### **Recommended `GEMINI.md` Instructions for the CLI**

Here’s a summary of the points that would work well in your GEMINI.md file.

#### **1. Code and File Modification Rules (Most Effective)**

These are the most impactful rules for the CLI, as they involve direct actions with files and code.

*   **Always Backup Before Editing:** Before modifying any file, create a timestamped backup.
    *   **Your Rule:** "if there is a modification to the file definitely you take a backup of the file in timestamped format (`$(date +%Y%m%d_%H%M%S)` postfix for the backup file before modifying it."
    *   **CLI Action:** I will run a backup command like `cp <file> <file>.bak`. I will use a static backup name because the shell environment does not permit dynamic command substitution for security reasons.
*   **Comment Out Old Code:** When replacing code, comment out the old lines instead of deleting them for user reference.
*   **Provide Full Context and Testing Steps:** After a modification, explain how to test the changes and provide the full, modified code if requested.
    *   **Example Rule:** "After modifying a file, provide a section named '🧪 **HOW TO TEST THE CHANGES**' with step-by-step instructions for verification."
*   **Analyze Impact:** When changing code, explain what other parts of the system might be affected.

#### **2. Content and Explanation Style**

These rules help ensure the text-based output is clear and useful.


*   **Provide Comprehensive Explanations:** Explain topics and commands in detail, including full paths and the purpose of commands.
*   **Use Visuals (Text-Based):** When explaining hierarchies or ecosystems (e.g., comparing `cmake` vs. `make`), use text-based tree diagrams.
    *   **Example Rule:** "Use text-based diagrams to show relationships, like this:
        ```
        Build Tools
        ├── Make
        │   └── Makefile
        └── CMake
            └── CMakeLists.txt
        ```
*   **Structure with Headings and Icons:** Use bold, capitalized headings with a relevant emoji to structure your responses.
*   **Vertical-Friendly Tables:** For tabular data, use a definition list or other vertical format that is easy to read on a narrow screen. Avoid wide Markdown tables.
*   **Missing Knowledge Identifier:**
    *   **Your Rule:** "Based on AI result also me a Section called "Missing knowledge identifier" what shows what im missing in my knowledge... Save this all info in the "AI Teachings.md" file..."
    *   **CLI Action:** When providing explanations, I will include a section titled "**🎓 MISSING KNOWLEDGE IDENTIFIER**". I will detail the relevant concepts and save this information to a file named `AI Teachings.md` in the appropriate directory.

#### **3. Troubleshooting and Interaction**

*   **Request More Information Clearly:** If you need more context (like logs or config files), create a specific section asking for it and wait for the user to provide it.
    *   **Example Rule:** "If you need more information, create a heading '⚠️ **MORE INFORMATION REQUIRED**' and list exactly what you need."
*   **Provide Log Collection Scripts:** If you need logs, provide a complete, copy-pasteable shell script that saves the output to a file and prints the file's location.

#### **4. Learning and Workflow Enhancement**

*   **Alternative Approaches:** When you ask how to do something, also provide a section named "**💡 ALTERNATIVE APPROACHES**" that describes other methods to achieve the same goal, including their pros and cons.
*   **Potential Pitfalls:** For any complex command or code change, add a section called "**🤔 WHAT COULD GO WRONG? (POTENTIAL PITFALLS)**" to help anticipate and avoid common errors.
*   **Logical Next Step:** After successfully completing a task, proactively suggest a logical next action under the heading "**🚀 LOGICAL NEXT STEP**" to help guide the workflow.