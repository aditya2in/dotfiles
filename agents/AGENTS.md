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
- Audio Output: GPU HDMI/DP -> LG Monitor -> 3.5mm AUX -> External Speakers
- KVM & Peripherals: UGREEN 2-in 4-out USB Sharing Switch (toggles accessories between Personal PC and Office Laptop; connects Maono PD300X Mic, Realme Studio H1, Logitech mouse receiver, Dell keyboard)
- Microphone: Maono PD300X Dynamic USB/XLR Microphone
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

## Core Rule: Documentation for System Tweaks, Scripting, and Engineering Logs

### 🎯 Intention: Why and How We Document
We document to maintain a single, cohesive source of truth for joint engineering research, diagnostics, and workspace configurations. This live engineering log enables both Aditya and the AI to build on past context, troubleshoot faster, and preserve technical details across session restarts or context window truncations.

### 📝 Document Lifecycle Rules
1. **Ongoing Topic/Subject (Same File):** If the research or troubleshooting session on a specific topic is still active, the AI must continuously update the **same file**. Every new finding, command output, or step in the troubleshooting chain must be added to the existing document as the session progresses.
2. **Close of Subject:** When the issue is resolved (e.g., system is confirmed stable with zero errors), the current file is finalized and the subject is marked **closed**.
3. **New Topic/Subject (New File):** When a new topic, project, or problem is initiated, the AI must create a **new document** and add a corresponding entry to `AI_documentation_index.md`.

### ⚡ Execution Rules
1. **Immediate Documentation:** All system modifications, diagnostic updates, or script creations must be documented immediately. This includes initiating a new document at the very start of a troubleshooting session to log initial diagnostics and step-by-step progress, rather than waiting for the final resolution.
2. **Automatic Execution (No Permission Required):** The AI must perform all documentation edits, file creations, and index updates automatically without asking for permission. This overrides the 'Permission Before Action' mandate for documentation files.
3. **Mandatory Final Output (Documentation Report):** At the very end of its final response, the AI MUST output a section titled `## 📂 Documentation Report` listing the file name, absolute path, and file link of every documentation file created or updated during the turn.
4. **Indexing:** The AI must update the `AI_documentation_index.md` file in the Obsidian directory with an entry for any new document, including the file path and a brief description.
5. **Scope:** This applies specifically to system tweaks, scripting, configurations, diagnostics, technical research, and purchase/upgrade decision logs (not academic or general content generation).
6. **Mandatory Path:** All documentation MUST be saved in the HomeLab folder:
    `/home/adityaws/Obsidian/All Things/Agents/Learning_&_HomeLab_OS/Project_K8s_-_KUBESTRONAUT/Tasks_or_Projects_(around_KUBESTRONAUT)/HomeLab/`
7. **Append-Only Index:** The `AI_documentation_index.md` in the HomeLab folder must **NEVER** be deleted or fully overwritten. New entries must be **APPENDED** to the table.
8. **Index Format Example:**
    `| YYYY-MM-DD | FileName.md | Brief description of the change |`
9. **Atomic Execution Priority:** Documentation and index updates MUST be written immediately after the change is verified, in the very same model turn/response, before delivering any conversational responses, secondary analysis, or answering unrelated questions.
10. **Context Retrieval via Index:** When context retrieval or historical workspace understanding is needed, the AI MUST check the documentation index file `AI_documentation_index.md` to align itself on the current workspace state, past configurations, and previous diagnostics, avoiding duplication.
11. **Manual Reproducibility Command Mandate**: Every documentation file created or updated for system modifications, configuration tweaks, or git-branch operations MUST include complete command lines, descriptions of the command flags, and a step-by-step walkthrough explaining how a human user can perform the identical task manually in the future. Never just state what was changed; always provide the exact commands and explanations to make the changes fully reproducible and future-proof.



### 📦 Git Push at Close of Subject
1. **No Premature Git Commands**: Git commits, pushes, and the `## 📦 Git Commit Report` table MUST NOT be generated, suggested, or executed during intermediate troubleshooting turns.
2. **End-of-Topic Protocol**: When the AI believes a task is complete, it must ask: "Is everything good?" to seek final verification.
3. **Execution Condition**: Once Aditya explicitly confirms (e.g., "good", "yes", "it works", "it is working", "fixed", "resolved", "no errors now"), the AI must automatically execute the Git commit and push commands in that same turn and present the `## 📦 Git Commit Report` table. Do not run or propose Git commands before this explicit confirmation.
4. **Unified Single Compound Command Mandate**: The AI MUST NEVER execute Git commands as multiple, fragmented tool calls or sequential approval steps across repositories. All Git staging, commits, and pushes across all modified repositories (`~/DOTfiles`, `~/Obsidian`, `~/Logseq Sync 17Sep2025`) MUST be chained into **ONE SINGLE compound command string** (using `&&` and `;`) so the user only approves once, and all repositories are committed and pushed together in a single execution.
   * **Mandatory Compound Command Example:**
     ```bash
     git -C ~/DOTfiles add . && git -C ~/DOTfiles commit -m "<msg>" && git -C ~/DOTfiles push origin new; git -C ~/Obsidian add . && git -C ~/Obsidian commit -m "<msg>" && git -C ~/Obsidian push origin new; git -C ~/Logseq\ Sync\ 17Sep2025 add . && git -C ~/Logseq\ Sync\ 17Sep2025 commit -m "<msg>" && git -C ~/Logseq\ Sync\ 17Sep2025 push origin new
     ```

#### **Git Configuration & Repository Limits:**
* **Authorized Repositories:** Git commands are only configured and allowed to run in the following three specific directories:
  1. `~/DOTfiles` (the dot files folder)
  2. `~/Obsidian` (the Obsidian folder)
  3. `~/Logseq Sync 17Sep2025` (the Logseq folder containing a date in the folder name)
* **Branch and Remote Settings:** All repositories use the exact same branch name **`new`** and the remote target **`origin new`** (matching the system shell aliases).

## 🗂️ TASKS OS QUERY (Stage 4 — Day Routine OS)

Tasks OS is queried via the Obsidian Base, NOT by checking a deliverable file. The query filters task files in `Tasks_OS/tasks/` tagged `#todays-task`. Reusable command (never reformulate):

```bash
obscli eval code="(function(){ const files = app.vault.getMarkdownFiles().filter(f => f.path.startsWith('All Things/Agents/Tasks_OS/tasks')); let rows = []; files.forEach(f => { const fm = app.metadataCache.getFileCache(f)?.frontmatter; if(!fm) return; const tags = JSON.stringify(fm.tags || []); if(tags.includes('todays-task')){ rows.push({id: fm.id, title: fm.title, status: fm.status, matrix: fm.eisenhower_matrix, duration: fm.duration, when: fm.when, preferred_time_slot: fm.preferred_time_slot || ''}); }}); return JSON.stringify({scheduled_for_today: rows.length, tasks: rows}); })()"
```

**Scheduling rules (mandatory):**
- Tasks are scheduled **SEQUENTIALLY** — never stacked. Multiple tasks in the same `preferred_time_slot` get consecutive blocks by duration.
- Schedule each task exactly at its `preferred_time_slot` metadata. If empty → auto-place in a free gap.
- Tasks with `when` ≠ today are skipped.
- If `scheduled_for_today = 0` → auto-switch user to tmux Tasks window (K8:10), no permission.
- `base:query` is UNRELIABLE — always use `obscli eval` (see base:query UNRELIABILITY REPORT).

## 👀 TODAY AT A GLANCE (MANDATORY OUTPUT)

Every time the Day Routine OS daily note generation completes (end of Stage 2, after Stage 4, and after finalization), the AI MUST:
1. Inject a `## 👀 Today at a Glance` section at the **very top** of the daily note (under `# Day planner`, before the Night Sleep block) — **expanded by default**.
2. **Also show the exact same glance block in chat** — never omit it.

Glance structure: `🎯 Goal · 🏠 Work · 🍽️ Meals · ✅ Tasks · ⏰ Key slots · 🔥 Events · ⚠️ Alerts · 🌙 Tonight`. Sources: Goal→user, Work→Office OS, Meals→Kitchen OS, Tasks→Tasks OS query, Slots→Day Planner timed blocks, Events→injected events, Alerts→expiring/overdue flags, Tonight→Kitchen OS prerequisites.

**Meals line rule:** The `🍽️ Meals` line MUST include **ALL expiring items inline with ⚠️** (e.g., "⚠️ Methi-Potato Curry (expires today!)"). Every Kitchen-deliverable item flagged `expires today` / 🔴 T1 / near `expiry_date` appears in this line — never omit one. The `🌙 Tonight` line MUST capture Kitchen OS prerequisites (soaks, prep, tomorrow's breakfast) plus sleep-prep items.

#### **Mandatory Final Git Output (Git Commit Report Table):**
At the very end of any final response where Git commands are suggested or executed (which MUST only occur when a topic is explicitly closed/resolved by Aditya), the AI MUST output a section titled `## 📦 Git Commit Report` structured as a Markdown table.
* **Vertical Monitor Optimization:** To prevent horizontal scrolling on vertical screens:
  1. All files in the "Staged Files" column must be stacked vertically using `<br>` tags.
  2. Long directory lists must be summarized (e.g., `folder/ (X untracked files)`).
* **Example Output Table:**
  | Repository | Staged Files | Branch/Remote | Commit Message | Command |
  | :--- | :--- | :--- | :--- | :--- |
  | `~/Obsidian` | `HomeLab/file.md` | `new` (`origin new`) | `docs: commit message` | `git -C ~/Obsidian add . && git -C ~/Obsidian commit -m "docs: commit message" && git -C ~/Obsidian push origin new` |




## Global Localization & Cost Tracking (ALWAYS)
- **Time:** ALL timestamps — without exception — MUST be in **IST (Indian Standard Time, UTC+5:30)**. Never display UTC, EST, or any other timezone. Always convert.
- **Currency:** ALL prices/costs MUST be displayed in **INR (₹)**. Fetch the live exchange rate from exchangerate-api.com on every use. Every mention of USD MUST have the INR equivalent in brackets immediately after (e.g., "$330 (~₹31,716)"). The exchange rate (1 USD = X INR) MUST always be explicitly displayed alongside any balance or spend output so the user knows the exact conversion rate used.
- **Balance Tracking (Automatic):** Every time the user asks for DeepSeek balance, the AI MUST automatically log it — no separate instruction needed.
  1. Source `~/.config/deepseek/env`, then run the `deepseek-balance` alias
  2. Show: remaining USD, INR equivalent, exchange rate (1 USD = X INR), and session cost estimate in both USD and INR
  3. **APPEND** an entry to the balance log with date (IST), USD balance, INR balance, change in USD, change in INR, and notes
  4. **ANALYZE** after every balance check: AI computes total spend, avg per day, weekday vs weekend breakdown, heaviest day, and predicted depletion date using full log history. The exchange rate (1 USD = X INR) MUST be explicitly displayed alongside the analysis. Append an analysis row with `—` for monetary columns showing: usage days, total spent, avg/day, heaviest day, and predicted remaining days (e.g., `~25d left at current rate (est. Jun 26 — projection, not guaranteed)`).
  5. **Plan Mode handling:** If in read-only/plan mode, present the data and plan the log entry + analysis. Execute the append immediately when switched to build mode, including the present check and any pending ones.

**Method:** AI-driven analysis (Python used only for arithmetic). No separate script needed.
- **Scope:** Applies to EVERY response — chat, study, labs, Q&A. Not just generated files.

### Balance Log Path
`/home/adityaws/Obsidian/All Things/Agents/Learning_&_HomeLab_OS/Project_K8s_-_KUBESTRONAUT/Tasks_or_Projects_(around_KUBESTRONAUT)/3.Project_AI_Mastery/deepseek_balance_log.md`

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
- The user's machine has an Intel Xeon W-2133 CPU, NVIDIA GeForce RTX 3080 Ti GPU, and 32GB of RAM.
- The user's monitor is an LG 34WN750-B (Ultrawide). They are running Arch Linux with Hyprland. The Hyprland configuration is modular, with monitor settings stored specifically in `~/.config/hypr/monitors.conf`, separate from the main config.
- The Gemini CLI is ALWAYS displayed on a vertical monitor. All formatted outputs (TUI briefs, tables, diagrams) MUST be optimized for a narrow, vertical display to ensure readability and prevent horizontal wrapping.

## Speech-to-Text (STT) Homophone and Mis-transcription Mapping
The user interacts using a high-powered dynamic microphone and a real-time STT transcoder. When parsing requests, the AI must automatically resolve common speech homophones:
1. "dot empty" / "agents.empty" / "empty file" -> "dot md" / "agents.md" / ".md extension"
2. "GB worker" / "GB worker 2" / "gbworker" -> "gpuworker01" / "gpuworker02"
3. "olx" -> Used market / pre-owned GPU purchases
4. Automatically align phonetic/homophone sound-alikes to hostnames, paths, and configs.

