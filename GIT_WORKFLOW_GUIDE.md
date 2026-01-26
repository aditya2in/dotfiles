# Git & GitHub CLI Workflow Guide

This guide documents the process for managing this dotfiles repository, specifically addressing the workflow with **GitHub CLI (`gh`)** and using **Git alongside Syncthing**.

## 1. GitHub CLI Setup

To interact with GitHub (push/pull) securely without manually managing SSH keys every time, we use the GitHub CLI.

### Authentication
If you haven't authenticated yet or need to re-authenticate:

```bash
gh auth login
```

**Steps:**
1.  Select **GitHub.com**.
2.  Select **HTTPS** as the protocol.
3.  Choose **Yes** to authenticate with your credentials.
4.  Select **Login with a web browser**.
5.  Copy the one-time code provided in the terminal.
6.  Paste it into the browser window that opens.

### Verify Status
To check if you are logged in correctly:
```bash
gh auth status
```

---

## 2. Git vs. Syncthing Strategy

Since this folder is synced via **Syncthing** (live sync across devices) and managed by **Git** (version control/history), you must follow a specific workflow to avoid conflicts.

*   **Syncthing** propagates changes immediately.
*   **Git** records snapshots of those changes.

**The Problem:** If you edit a file on Device A and Device B *before* committing on Device A, Git on Device B might refuse to pull because of "local changes" or "divergent branches."

### Best Practices
1.  **Ignore Syncthing Files:** Ensure `.stfolder/` and `*.sync-conflict*` files are in your `.gitignore`.
2.  **Commit Often:** Treat Git as your save point.

---

## 3. Syncing Workflow (How to Push/Pull Safely)

If you try to push and get an error like `updates were rejected because the remote contains work that you do not have locally`, follow this "Safe Sync" procedure:

### Step 1: Stash Local Changes
If you have uncommitted changes (work in progress) that are preventing a pull, move them to a temporary storage area ("stash"):

```bash
git stash
```

### Step 2: Pull Remote Changes
Fetch the latest commits from GitHub. Using `--rebase` helps keep a cleaner history by putting your changes *after* the remote ones.

```bash
git pull origin new --rebase
```

### Step 3: Restore Local Changes
Bring your work-in-progress changes back:

```bash
git stash pop
```

*Note: If there are conflicts (e.g., you and the remote modified the exact same line), Git will ask you to resolve them manually at this stage.*

### Step 4: Commit and Push
Now that your local repository is up-to-date with the remote, you can commit your current changes and push.

```bash
git add .
git commit -m "Your commit message here"
git push origin new
```

---

## Summary Command
You can often run this one-liner to sync up before working:

```bash
git stash && git pull origin new --rebase && git stash pop
```
