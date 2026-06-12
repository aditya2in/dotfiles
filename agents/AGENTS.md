# Gemini CLI Agent Mandates

## Filesystem Rule: Obsidian .md Extension
All files created in the Obsidian vault MUST use the `.md` extension. Never `.markdown`, `.txt`, or any other extension. Obsidian only recognizes `.md` files for internal linking and rendering.
**AGENTS.md filename casing:** On Linux, filenames are case-sensitive. OpenCode looks for `AGENTS.md` (lowercase `.md`). Always use `AGENTS.md` — never `AGENTS.MD`, `AGENTS.Md`, or any other variant. The file MUST be `AGENTS.md` with all lowercase `.md` extension.

## Permission Before Action
Before making any file changes, configuration edits, deletions, or other actions that modify the workspace, first ask for explicit permission and wait for the user's confirmation.
Required confirmation wording: "Shall I proceed?"
If the user has not clearly approved the action, stop and ask before proceeding.

## Workspace Context
Omarchy (Arch Linux + Hyprland) user home directory, not a traditional code repo. Primary work: system configs, Hyprland rules, theme customization.

## Hardware & System
- CPU: Intel Xeon W-2133
- GPU: NVIDIA GeForce RTX 3060
- RAM: 32 GB
- Monitor: LG 34WN750-B (Ultrawide)
- Filesystem: Btrfs with Snapper snapshots

## Key Config Paths
- Hyprland user configs: `~/.config/hypr/` (some symlinked to `~/DOTfiles/hyprland All/.config/hypr/`)
- Omarchy defaults: `~/.local/share/omarchy/default/hypr/` (do not edit directly)
- Terminal configs: `~/.config/alacritty/`, `~/.config/ghostty/`, `~/.config/kitty/`
- Theme configs: `~/.config/omarchy/current/theme/`
- Monitor settings: `~/.config/hypr/monitors.conf`

## Critical Commands
- Reload Hyprland: `hyprctl reload`
- Check Hyprland settings: `hyprctl getoption <option>` (e.g., `decoration:active_opacity`)
- Omarchy commands: All start with `omarchy-` (e.g., `omarchy-refresh-config`)

## Config Precedence
1. User `~/.config/hypr/*.conf` overrides Omarchy defaults
2. Theme configs override default theme settings
3. Window rules (`windows.conf`, `apps/*.conf`) override `looknfeel.conf` opacity

## Prior Changes
Opacity rules set to `1.0 1.0` to disable transparency. To enable transparency/blur, edit `~/.config/hypr/looknfeel.conf`.

## Core Rule: Documentation for System Tweaks & Scripting
Any file creation, script generation (shell, python, etc.), or system-wide modification/tweak performed by the AI MUST be documented.

1.  **Immediate Documentation:** All system modifications or script creations must be documented as soon as the change is verified.
2.  **User Approval:** The AI must ask to document the change. Once the user approves, the documentation must be saved in the Obsidian directory.
3.  **Indexing:** The AI must update the `AI_documentation_index.md` file in the Obsidian directory with an entry for the new document, including the file path and a brief description.
4.  **Scope:** This applies specifically to system tweaks, scripting, and configurations (not necessarily to academic or course-related content generation).
5.  **Mandatory Path:** All documentation MUST be saved in the HomeLab folder:
    `/home/adityaws/Obsidian/Project_K8s_-_KUBESTRONAUT/Tasks_or_Projects_(around_KUBESTRONAUT)/HomeLab/`
6.  **Append-Only Index:** The `AI_documentation_index.md` in the HomeLab folder must **NEVER** be deleted or fully overwritten. New entries must be **APPENDED** to the table in the exact format shown below.
7.  **Index Format Example:**
    `| YYYY-MM-DD | FileName.md | Brief description of the change |`

### Git Version Control Mandate (Consolidated Workflow)
- For every file modified by the AI, the AI must prepare a consolidated command including navigation, staging, and committing.
- The AI must ask for explicit permission once: "Shall I proceed with the git add and commit?"
- Once approved, the AI must execute the combined command.
- **Example:** `cd /home/adityaws/DOTfiles && git add <files> && git commit -m "<message>"`
- The AI must NOT push to remote repositories unless explicitly instructed.

## Global Localization & Cost Tracking (ALWAYS)
- **Time:** ALL timestamps — without exception — MUST be in **IST (Indian Standard Time, UTC+5:30)**. Never display UTC, EST, or any other timezone. Always convert.
- **Currency:** ALL prices/costs MUST be displayed in **INR (₹)**. Fetch the live exchange rate from exchangerate-api.com on every use. Every mention of USD MUST have the INR equivalent in brackets immediately after (e.g., "$330 (~₹31,716)").
- **Balance Tracking (Automatic):** Every time the user asks for DeepSeek balance, the AI MUST automatically log it — no separate instruction needed.
  1. Source `~/.config/deepseek/env`, then run the `deepseek-balance` alias
  2. Show: remaining USD, INR equivalent, and session cost estimate in both USD and INR
  3. **APPEND** an entry to the balance log with date (IST), USD balance, INR balance, change in USD, change in INR, and notes
  4. **ANALYZE** after every balance check: AI computes total spend, avg per day, weekday vs weekend breakdown, heaviest day, and predicted depletion date using full log history. Append an analysis row with `—` for monetary columns showing: usage days, total spent, avg/day, heaviest day, and predicted remaining days (e.g., `~25d left at current rate (est. Jun 26 — projection, not guaranteed)`).
  5. **Plan Mode handling:** If in read-only/plan mode, present the data and plan the log entry + analysis. Execute the append immediately when switched to build mode, including the present check and any pending ones.

**Method:** AI-driven analysis (Python used only for arithmetic). No separate script needed.
- **Scope:** Applies to EVERY response — chat, study, labs, Q&A. Not just generated files.

### Balance Log Path
`/home/adityaws/Obsidian/Project_K8s_-_KUBESTRONAUT/Tasks_or_Projects_(around_KUBESTRONAUT)/3.Project_AI_Mastery/deepseek_balance_log.md`

## Sudo/Privilege Escalation (Polkit Method)
When you need to run a command that requires `sudo` but the terminal cannot prompt for a password (no TTY, no askpass), use `pkexec` instead. This triggers a graphical polkit authentication pop-up on the user's Hyprland desktop. The user sees the pop-up, types their password, and the authentication is cached for subsequent commands.

```bash
# Instead of: sudo cp file /etc/path/
pkexec cp /path/to/source /etc/path/target

# Instead of: sudo systemctl daemon-reload
pkexec systemctl daemon-reload
```

If `pkexec` fails with a D-Bus error, try again once — it often works after the initial error resolves. The user has already authenticated once via a pop-up, so subsequent `pkexec` calls should work without prompting.

## Gemini Added Memories
- The user is running Arch Linux with Btrfs and Snapper for system snapshots.
- Always greet the user as "Aditya" at the start of a session.
- The user's machine has an Intel Xeon W-2133 CPU, NVIDIA GeForce RTX 3060 GPU, and 32GB of RAM.
- The user's monitor is an LG 34WN750-B (Ultrawide). They are running Arch Linux with Hyprland. The Hyprland configuration is modular, with monitor settings stored specifically in `~/.config/hypr/monitors.conf`, separate from the main config.
- The Gemini CLI is ALWAYS displayed on a vertical monitor. All formatted outputs (TUI briefs, tables, diagrams) MUST be optimized for a narrow, vertical display to ensure readability and prevent horizontal wrapping.
