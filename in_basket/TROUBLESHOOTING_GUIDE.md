# Troubleshooting Guide

**Version:** 1.0
**Last Updated:** 2025-11-03
**Audience:** Signers, operators, and technical support staff
**Authority:** PM (rajames440)

This guide helps you diagnose and fix common issues with the StarForth-Governance signature and vault system.

---

## Table of Contents

1. [Quick Diagnosis](#quick-diagnosis)
2. [GPG & Signature Issues](#gpg--signature-issues)
3. [Git & GitHub Issues](#git--github-issues)
4. [Jenkins & Pipeline Issues](#jenkins--pipeline-issues)
5. [Document Routing Issues](#document-routing-issues)
6. [Notification Issues](#notification-issues)
7. [Performance & Scaling Issues](#performance--scaling-issues)
8. [Getting Help](#getting-help)

---

## Quick Diagnosis

### I Have a Problem - Where Do I Start?

**Step 1: Identify the symptom**

| Symptom | Jump To |
|---------|---------|
| "gpg: command not found" or signature won't create | [GPG Not Installed](#gpg-not-installed) |
| Signature created but verification fails | [Signature Verification Fails](#signature-verification-fails) |
| Can't push to GitHub | [Git Push Fails](#git-push-fails) |
| Jenkins job won't run or fails | [Jenkins Job Fails to Run](#jenkins-job-fails-to-run) |
| Document not moving to Pending/ | [Document Not Routed](#document-not-routed) |
| Didn't receive notification | [Notification Not Received](#notification-not-received) |
| System is slow | [System Slow or Hanging](#system-slow-or-hanging) |

**Step 2: Follow the diagnosis steps**

Each section below has:
- **Symptom:** What you see
- **Likely causes:** Why it's happening
- **How to check:** Commands to diagnose
- **How to fix:** Solutions

**Step 3: Get help if stuck**

See [Getting Help](#getting-help) for escalation procedures.

---

## GPG & Signature Issues

### GPG Not Installed

**Symptom:**
```
-bash: gpg: command not found
```

**Likely Causes:**
- GPG not installed on your machine
- Wrong PATH (rare)

**How to Check:**
```bash
# Try to find GPG
which gpg
# If nothing returned, it's not installed

# Check if it's available via package manager
apt search gpg  # Ubuntu/Debian
brew search gpg  # macOS
yum search gpg   # CentOS/RHEL
```

**How to Fix:**

**macOS:**
```bash
brew install gpg
# Or download from: https://gnupg.org/download/
```

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install -y gnupg
```

**CentOS/RHEL:**
```bash
sudo yum install -y gnupg
```

**Windows:**
- Download from: https://gnupg.org/download/
- Run installer
- Restart your terminal

**Verify Installation:**
```bash
gpg --version
# Should show version number like: gpg (GnuPG) 2.2.x
```

---

### No GPG Key Generated

**Symptom:**
```bash
$ gpg --list-keys
# Output is empty (shows nothing)
```

**Likely Causes:**
- You haven't generated a key yet
- Your key is on a different machine

**How to Check:**
```bash
# Try again to list keys
gpg --list-keys

# If still empty, you need to generate one
# If you see keys but not yours, you might be on the wrong machine
```

**How to Fix:**

**Option 1: Generate a new key (First time)**
```bash
gpg --gen-key

# Follow prompts:
# Key type: RSA and RSA (default)
# Key size: 4096
# Expiration: 3y (3 years)
# Real name: Your Name
# Email: your@email.com
# Passphrase: Strong passphrase (12+ chars, mixed case + symbols)

# Process takes 1-2 minutes...
```

**Option 2: Import key from another machine**
```bash
# On the machine where your key exists:
gpg --export --armor your@email.com > my-key.asc

# Transfer the file to your current machine (email, USB, etc.)

# On your current machine:
gpg --import my-key.asc

# Verify it worked:
gpg --list-keys
```

**Verify:**
```bash
gpg --list-keys
# Should show your key with [SC] flags:
# pub   rsa4096 2025-11-03 [SC]
#      ABCDEF1234567890ABCDEF1234567890ABCDEF12
```

---

### Can't Remember GPG Passphrase

**Symptom:**
```
gpg: problem with the agent: Inappropriate ioctl for device
# Or many failed attempts to enter passphrase
```

**Likely Causes:**
- You typed the wrong passphrase
- You forgot the passphrase

**How to Check:**
```bash
# Try to sign something
echo "test" | gpg --clearsign
# Enter your passphrase carefully
# Watch for CAPS LOCK
```

**How to Fix:**

**If you forgot your passphrase:**

Unfortunately, there's no recovery. You'll need to:

1. **Generate a new key:**
   ```bash
   gpg --gen-key
   # Follow the prompts again
   # Create a strong new passphrase you won't forget
   ```

2. **Export new public key:**
   ```bash
   gpg --export --armor your@email.com > your-new-public.asc
   ```

3. **Share with PM:**
   - Send the `.asc` file to rajames440
   - PM imports it on Jenkins agents

4. **Delete old key (optional, for security):**
   ```bash
   gpg --delete-secret-key [old-key-id]
   gpg --delete-key [old-key-id]
   ```

**If you just mistyped it:**

1. Try again carefully
2. Check that CAPS LOCK is off
3. Try signing a test document first:
   ```bash
   echo "test" > test.txt
   gpg --detach-sign --armor test.txt
   # If this works, your key is fine
   ```

---

### Signature Verification Fails

**Symptom:**
```
gpg: Signature made Sun Nov 3 10:00:00 2025 UTC
gpg: BAD signature from "Your Name <your@email.com>"
```

Or:
```
gpg: Can't check signature: public key not found
```

**Likely Causes:**
- Document was modified after signing
- Your public key not imported on the verification system
- Signature file is corrupted
- Wrong document or signature file being checked

**How to Check:**

**Check 1: Verify file paths are correct**
```bash
# Make sure you're checking the right files
ls -la DOCUMENT.adoc
ls -la DOCUMENT.SIGNER.asc

# Check file sizes (not zero)
file DOCUMENT.adoc
file DOCUMENT.SIGNER.asc
```

**Check 2: Verify the signature command is correct**
```bash
# Correct format:
gpg --verify DOCUMENT.SIGNER.asc DOCUMENT.adoc

# NOT:
gpg --verify DOCUMENT.adoc  # This is wrong
```

**Check 3: Check if document was modified**
```bash
# If you have git, check git status
cd StarForth-Governance
git status
git diff DOCUMENT.adoc
# Any changes shown = document was modified after signing
```

**Check 4: Verify public key is imported**
```bash
# On Jenkins agent (where verification happens):
gpg --list-keys SIGNER_USERNAME
# Should show the key

# If not found, key is not imported
```

**How to Fix:**

**If document was modified:**
```bash
# Don't modify the document - sign it as-is
# If changes are needed, PM will route it back for revision
# Then you sign the NEW version

# Redo the signature:
gpg --detach-sign --armor DOCUMENT.adoc
# This creates a fresh DOCUMENT.adoc.asc file
# Rename/commit it as: DOCUMENT.SIGNER.asc
```

**If public key not imported on Jenkins:**
```bash
# Ask the operator to import your public key:
# 1. Export your public key:
gpg --export --armor your@email.com > your-public.asc

# 2. Send to PM or operator
# 3. They run on Jenkins agent:
gpg --import your-public.asc

# 4. Try verification again
```

**If signature file is corrupted:**
```bash
# Delete and recreate the signature
rm DOCUMENT.SIGNER.asc

# Create fresh signature
gpg --detach-sign --armor DOCUMENT.adoc

# Rename as needed
# Re-commit and push
```

---

### Signature File Format Wrong

**Symptom:**
```
gpg: no valid OpenPGP data found.
# Or: gpg: packet(3) too large
```

**Likely Causes:**
- Signature file is not armor (text) format
- File was corrupted during transfer
- Wrong file extension
- Binary format instead of ASCII

**How to Check:**
```bash
# Check file format
file DOCUMENT.SIGNER.asc
# Should show: "ASCII armor"

# Check file contents
head DOCUMENT.SIGNER.asc
# Should start with: -----BEGIN PGP SIGNATURE-----

# Check if it's binary
od -c DOCUMENT.SIGNER.asc | head -5
# Should show readable ASCII characters, not binary
```

**How to Fix:**

**If file is binary instead of ASCII:**
```bash
# Delete the file
rm DOCUMENT.SIGNER.asc

# Create armor format signature (text, not binary):
gpg --detach-sign --armor DOCUMENT.adoc
# Note: --armor flag is REQUIRED

# Verify the format:
file DOCUMENT.adoc.asc
# Should show: "ASCII armor"

# Rename and commit
mv DOCUMENT.adoc.asc DOCUMENT.SIGNER.asc
git add DOCUMENT.SIGNER.asc
git commit -m "docs(signature): Add signature from SIGNER"
git push origin master
```

**If file was corrupted during transfer:**
```bash
# If you uploaded via GitHub web interface, try command line instead:
git add DOCUMENT.SIGNER.asc
git commit -m "docs(signature): Fix corrupted signature"
git push origin master
```

---

## Git & GitHub Issues

### Git Clone Fails

**Symptom:**
```
fatal: repository not found
# Or: Permission denied (publickey)
# Or: fatal: Authentication failed for 'https://github.com/...'
```

**Likely Causes:**
- GitHub credentials are wrong
- Repository URL is incorrect
- GitHub PAT expired or revoked
- Network issue

**How to Check:**

**Check 1: Verify repository URL**
```bash
# Correct URL:
https://github.com/rajames440/StarForth-Governance.git

# Try it:
git clone https://github.com/rajames440/StarForth-Governance.git
```

**Check 2: Verify GitHub connectivity**
```bash
# Test HTTPS connection
curl -I https://github.com
# Should show: HTTP/1.1 200 OK

# Test with authentication
curl -H "Authorization: Bearer [YOUR_PAT]" https://api.github.com/user
# Should show your user info (JSON)
```

**Check 3: Verify PAT is valid**
```bash
# In GitHub: Settings → Developer settings → Personal access tokens
# Check that your token is NOT marked as "Expired"
# Check that it has "repo" scope
```

**How to Fix:**

**If using HTTPS with PAT:**
```bash
# Clone with embedded PAT (temporary, for testing only)
git clone https://[PAT]@github.com/rajames440/StarForth-Governance.git

# If this works, your PAT is valid
# But don't use this in scripts - use git credentials instead

# Configure git to use credentials:
git config --global credential.helper store
# Then next time you push, enter PAT once, it's saved

# Or use SSH keys (more secure)
```

**If using SSH key:**
```bash
# Generate SSH key (if you don't have one)
ssh-keygen -t rsa -b 4096

# Add public key to GitHub
# GitHub → Settings → SSH and GPG keys → New SSH key
# Paste contents of ~/.ssh/id_rsa.pub

# Clone with SSH
git clone git@github.com:rajames440/StarForth-Governance.git
```

**If GitHub PAT expired:**
```bash
# Generate new PAT
# GitHub → Settings → Developer settings → Personal access tokens
# Click "Generate new token (classic)"
# Same scopes as before: repo, workflow

# Update git credentials:
git config --global credential.fill store
# Or reconfigure: git config --global credential.helper store
```

---

### Git Push Fails

**Symptom:**
```
fatal: 'origin' does not appear to be a 'git' repository
# Or: Permission denied (publickey)
# Or: refusing to allow an OAuth token to be used for git
```

**Likely Causes:**
- Remote repository not configured
- Branch protection rules blocking push
- Insufficient permissions
- GitHub PAT doesn't have write access

**How to Check:**

**Check 1: Verify remote is configured**
```bash
git remote -v
# Should show:
# origin  https://github.com/rajames440/StarForth-Governance.git (fetch)
# origin  https://github.com/rajames440/StarForth-Governance.git (push)

# If not, configure it:
git remote add origin https://github.com/rajames440/StarForth-Governance.git
```

**Check 2: Check branch protection**
```bash
# Try to push to a different branch first:
git push origin HEAD:test-branch

# If this succeeds, master branch is protected
# You may need to create a PR instead
```

**Check 3: Verify you're on master**
```bash
git branch
# Should show: * master (asterisk = current branch)
```

**How to Fix:**

**If remote not configured:**
```bash
git remote add origin https://github.com/rajames440/StarForth-Governance.git
git push origin master
```

**If branch is protected (can't push directly):**
```bash
# Create a feature branch instead
git checkout -b feature/my-changes
git add [files]
git commit -m "..."
git push origin feature/my-changes

# Then create pull request in GitHub
# GitHub → Pull requests → New pull request
# Base: master, Compare: feature/my-changes
```

**If PAT doesn't have write access:**
```bash
# Check GitHub PAT scopes:
# GitHub → Settings → Developer settings → Personal access tokens
# Should have: repo (full control)

# If not, create new PAT with correct scopes:
# Generate new token
# Add scopes: repo, workflow
# Update your git credentials with the new PAT
```

---

### File Changes Not Showing in Git

**Symptom:**
```bash
git status
# Shows: On branch master, nothing to commit, working tree clean

# But you know you made changes
```

**Likely Causes:**
- Changes are in a different directory
- File is .gitignored
- File is untracked (new file not added)

**How to Check:**

**Check 1: Verify current directory**
```bash
pwd
# Should be in StarForth-Governance directory
# Not in a subdirectory

# Files changed in Pending/CAPA/ should show as:
# Pending/CAPA/FILENAME.asc
```

**Check 2: Check if file is ignored**
```bash
# Check .gitignore
cat .gitignore

# If your file is ignored:
# - Remove it from .gitignore if it should be tracked
# - Or use: git add -f FILENAME (force add)
```

**Check 3: Check if file needs to be added**
```bash
# New files must be added first
git add FILENAME
git status
# Now it should show in "Changes to be committed"
```

**How to Fix:**

**If file is in wrong location:**
```bash
# Move file to correct location
mv FILENAME Pending/CAPA/FILENAME
git add Pending/CAPA/FILENAME
git commit -m "docs(signature): Add signature"
git push origin master
```

**If file is new and needs to be added:**
```bash
git add FILENAME
git status
# Should now show "Changes to be committed"

git commit -m "docs: Add new file"
git push origin master
```

**If file is in .gitignore but should be tracked:**
```bash
# Option 1: Remove from gitignore
nano .gitignore
# Remove line with your filename
git add -A
git commit -m "gitignore: Stop ignoring FILENAME"

# Option 2: Force add despite gitignore
git add -f FILENAME
git commit -m "docs: Add ignored file"
git push origin master
```

---

## Jenkins & Pipeline Issues

### Jenkins Job Fails to Run

**Symptom:**
```
Build #123 FAILED
# Or: Job won't appear in dashboard
# Or: "Build Now" button does nothing
```

**Likely Causes:**
- Jenkins is not running
- Agent is offline
- Network connectivity issue
- Job not configured properly

**How to Check:**

**Check 1: Is Jenkins running?**
```bash
# Try to access Jenkins web interface
curl -s http://localhost:8080 | head -20
# Should show HTML

# Or open in browser:
# http://[jenkins-url]:8080
# Should load Jenkins dashboard
```

**Check 2: Is agent connected?**
```bash
# Jenkins Dashboard → Manage Jenkins → Manage Nodes and Clouds
# Your agent should show as "connected"
# If "offline", there's a connectivity issue
```

**Check 3: Check job configuration**
```bash
# Jenkins Dashboard → [Job Name] → Configure
# Verify:
# - SCM: Git is selected
# - Repository URL is correct
# - Credentials are set to "github-credentials"
# - Script Path is correct (e.g., "Jenkinsfile.disposition")
# - Build Triggers are set
```

**How to Fix:**

**If Jenkins is down:**
```bash
# Restart Jenkins
sudo systemctl restart jenkins

# Wait 2 minutes for it to fully start
# Test: curl http://localhost:8080
```

**If agent is offline:**
```bash
# SSH to agent and check status
ssh jenkins-agent@agent-url

# Check if Jenkins agent is running
ps aux | grep -i jenkins

# Restart agent if needed
sudo systemctl restart jenkins-agent
```

**If job won't run, check logs:**
```bash
# Jenkins Dashboard → [Job Name] → Build Now
# Click the build
# Click "Console Output"
# Look for error messages

# Common errors:
# - "Repository not found" → credential issue
# - "Script not found" → wrong script path
# - "No space left" → disk full
```

---

### Jenkins Signature Verification Fails

**Symptom:**
```
Stage 'Verify Signature' FAILED
# Or: "gpg: Can't check signature: public key not found"
# Or: "BAD signature from ..."
```

**Likely Causes:**
- Signer's public key not imported on Jenkins agent
- Signature file is corrupted
- Document was modified after signing
- Wrong GPG configuration

**How to Check:**

**Check 1: Is signer's key imported?**
```bash
# SSH to Jenkins agent
ssh jenkins-agent@agent-url
sudo su - jenkins

# List imported keys
gpg --list-keys
# Should see the signer's key

# If not found:
gpg --list-keys [signer-username]
# Shows: "public key not found"
```

**Check 2: Verify signature manually**
```bash
# On Jenkins agent, manually verify:
cd StarForth-Governance
gpg --verify Pending/CAPA/CAPA-001.rajames440.asc Pending/CAPA/CAPA-001.adoc

# Should show: "Good signature from ..."
```

**Check 3: Check signature file exists and is readable**
```bash
ls -la Pending/CAPA/*.asc
file Pending/CAPA/CAPA-001.rajames440.asc
# Should show "ASCII armor"
```

**How to Fix:**

**If public key not imported:**
```bash
# As operator, import the signer's public key:
ssh jenkins-agent@agent-url
sudo su - jenkins

# Copy the .asc file (get from signer or PM)
gpg --import ~/keys/rajames440-public.asc

# Verify
gpg --list-keys rajames440
# Should show the key

# Re-run Jenkins job
```

**If signature file is corrupted:**
```bash
# Ask signer to recreate the signature:
# 1. Delete old: git rm Pending/CAPA/CAPA-001.rajames440.asc
# 2. Create new: gpg --detach-sign --armor CAPA-001.adoc
# 3. Commit and push

# Then re-run Job 2 on Jenkins
```

**If document was modified:**
```bash
# Check what changed:
git diff Pending/CAPA/CAPA-001.adoc

# Either:
# 1. Revert changes: git checkout -- Pending/CAPA/CAPA-001.adoc
# 2. Have signer sign the new version
```

---

### Jenkins Out of Disk Space

**Symptom:**
```
No space left on device
# Or: Job hangs/fails during checkout
# Or: Jenkins is very slow
```

**Likely Causes:**
- Build logs accumulated
- Workspace not cleaned
- Artifacts not deleted
- Jenkins partition full

**How to Check:**

**Check 1: Check disk usage**
```bash
df -h /var/lib/jenkins
# If > 90%, disk is full

df -h /var/lib/jenkins/workspace
# Check workspace size
```

**Check 2: Find large directories**
```bash
du -sh /var/lib/jenkins/* | sort -rh | head -10
# Shows largest directories
```

**How to Fix:**

**Quick fix: Delete old builds**
```bash
# SSH to Jenkins server
ssh jenkins-admin@jenkins-url

# Delete old logs for a job
# Jenkins Dashboard → Manage Jenkins → Script Console
# Run:
def job = Jenkins.instance.getItemByFullName('starforth-disposition')
job.getBuilds().findAll { it.number < job.lastBuild.number - 30 }.each { it.delete() }
```

**Clean workspace:**
```bash
# Jenkins Dashboard → [Job Name] → Build Now
# (with no changes, this will clean the workspace)

# Or manually:
rm -rf /var/lib/jenkins/workspace/starforth-*
```

**Expand disk:**
```bash
# If disk is genuinely full, need to expand partition
# This requires downtime - coordinate with PM

# Stop Jenkins
sudo systemctl stop jenkins

# Expand partition (vary by VM/cloud provider)
# Then restart:
sudo systemctl start jenkins
```

---

## Document Routing Issues

### Document Not Routed to Pending/

**Symptom:**
```
Document is in in_basket/ but not moved to Pending/
Job 1 runs but document stays in in_basket/
```

**Likely Causes:**
- Document filename doesn't match known type
- Job 1 hasn't run yet (scheduled every 15 min)
- Document has parsing error
- Jenkins job failed

**How to Check:**

**Check 1: When did Job 1 last run?**
```bash
# Jenkins Dashboard → starforth-disposition → Build History
# Check timestamp of last build
# If it was 20+ minutes ago, it should have run
# If it just ran, check the log

# Check manually:
# Jenkins Dashboard → starforth-disposition → Last Build
# Click "Console Output"
# Look for: "Processing [document-name]"
```

**Check 2: Is document filename valid?**
```bash
# Document name must be: TYPE-NUMBER.extension
# Valid examples:
# CAPA-001.adoc (correct format)
# TEST-CAPA-001.adoc (correct, with TEST prefix)
# my-document.adoc (INVALID - no TYPE-NUMBER)

# Check what's in in_basket/
ls -la in_basket/ | grep -v "^d"
# Are your files here?
```

**Check 3: Check Jenkins logs**
```bash
# Jenkins Dashboard → starforth-disposition → Last Build → Console Output
# Look for error messages:
# - "No classifier found" = filename doesn't match pattern
# - "Document type not in routing map" = type not recognized
# - "Failed to route" = something else went wrong
```

**How to Fix:**

**If filename is wrong:**
```bash
# Rename document to match pattern
# In_basket or via git:
git mv in_basket/my-document.adoc in_basket/CAPA-001.adoc

# Commit and push
git commit -m "docs: Rename document to correct format"
git push origin master

# Wait 15 minutes for Job 1 to run
# Or manually trigger: Jenkins Dashboard → starforth-disposition → Build Now
```

**If document type is not in routing map:**
```bash
# Check VAULT_ROUTING_MAP.md for recognized types
# Valid types: CAPA, ECR, ECO, FMEA, DHR, DMR, CER, DWG, ENG, SEC, IR, VAL, DTA, ART, MIN, REL, RMP

# If your type is not there, ask PM to add it
```

**If Job 1 hasn't run:**
```bash
# Trigger it manually:
# Jenkins Dashboard → starforth-disposition → Build Now

# Wait for it to complete (usually < 1 minute)

# Check Console Output for your document
```

---

### Wrong Document Routed to Wrong Location

**Symptom:**
```
Document CAPA-001 ended up in Pending/ECR/ instead of Pending/CAPA/
# Or document went to Vault instead of Pending
```

**Likely Causes:**
- Filename contains wrong type code
- VAULT_ROUTING_MAP.md has wrong configuration
- Document type not recognized
- Bug in disposition script

**How to Check:**

**Check 1: Verify filename**
```bash
# Document filename must start with the type it represents
# CAPA-001.adoc → should be routed to Pending/CAPA/
# ECR-002.adoc → should be routed to Pending/ECR/

# If filename is wrong, that's the issue

# Check what was actually routed:
git log --oneline -- Pending/ | head -20
# See recent commits to Pending directories
```

**Check 2: Check routing map**
```bash
# Check VAULT_ROUTING_MAP.md
# Make sure your document type is configured correctly
# Example:
# CAPA: Pending/ (signature required)
# ART: Pending/ (no vault)
```

**How to Fix:**

**If filename is wrong:**
```bash
# Revert the commit that moved it
git revert [commit-hash]

# Rename the document correctly
git mv Pending/ECR/CAPA-001.adoc Pending/CAPA/CAPA-001.adoc

# Re-commit
git commit -m "docs: Move document to correct directory"
git push origin master

# Run Job 1 again to re-process
```

**If routing map is wrong:**
```bash
# Edit VAULT_ROUTING_MAP.md
# Correct the destination for your document type
# Commit and push

# Move the document to correct location manually
git mv Pending/ECR/CAPA-001.adoc Pending/CAPA/CAPA-001.adoc
git commit -m "docs: Move to correct directory after routing fix"
git push origin master
```

---

## Notification Issues

### Notification Not Received

**Symptom:**
```
Document is waiting for my signature but I didn't get notified
# Or: GitHub issue was not created
# Or: Didn't see @mention in notification
```

**Likely Causes:**
- GitHub notifications disabled
- Not watching the repository
- Notification created but GitHub issue failed
- You're not in the authorized signers list

**How to Check:**

**Check 1: Are you an authorized signer?**
```bash
# Check Security/Signatures.adoc
# Look for your username in the "Authorized Signers" table
# If not there, you're not authorized for any documents
```

**Check 2: GitHub notifications disabled?**
```bash
# GitHub → Settings → Notifications
# Check: "Participating and @mentions" should be selected
# Check: "Email notifications" should have your email
```

**Check 3: Not watching the repository?**
```bash
# StarForth-Governance repo → Click "Watch" button
# Select "Participating and @mentions"
```

**Check 4: Did Jenkins create the GitHub issue?**
```bash
# GitHub → Issues
# Search for recent issues with label "signature-needed"
# If you see issues there, Jenkins created them

# If you don't see issues, Jenkins failed to create them
# Check Jenkins logs:
# Jenkins Dashboard → starforth-disposition → Last Build → Console Output
```

**How to Fix:**

**If GitHub notifications are off:**
```bash
# GitHub Settings → Notifications
# Enable notifications
# Check your email for recent issues
```

**If not watching the repository:**
```bash
# StarForth-Governance repo page
# Click "Watch" (top-right)
# Select "Participating and @mentions"
# Now you'll get @mention notifications
```

**If GitHub issue wasn't created:**
```bash
# Check that:
# 1. gh CLI is installed on Jenkins agent: sudo apt-get install gh
# 2. gh is authenticated: gh auth login
# 3. Job 1 log shows "Creating GitHub issue" (not "gh CLI not available")

# If gh is missing, operator needs to install it on Jenkins agent
```

**If you're not authorized:**
```bash
# Ask PM to add you to Security/Signatures.adoc
# Specify:
# - Your username
# - Your role (ENGINEERING, QA_LEAD, etc.)
# - Document types you'll sign

# PM updates Signatures.adoc and pushes
# Job 1 will notify you for future documents
```

---

## Performance & Scaling Issues

### System Very Slow / Hanging

**Symptom:**
```
Jenkins is slow to respond
# Or: Git operations hang
# Or: Job takes 10+ minutes (usually takes 2-3 minutes)
# Or: Nothing happens when I push to GitHub
```

**Likely Causes:**
- Jenkins agent is overloaded
- Network connectivity issue
- Disk is full (see [Jenkins Out of Disk Space](#jenkins-out-of-disk-space))
- GitHub API rate limit hit

**How to Check:**

**Check 1: Jenkins server health**
```bash
# SSH to Jenkins server
ssh jenkins-admin@jenkins-url

# Check CPU usage
top -bn1 | head -20
# Any process using > 80% CPU?

# Check memory
free -h
# Is available memory < 500MB?

# Check disk
df -h /var/lib/jenkins
# Is > 80% full?

# Check load average
uptime
# Should be < (number of CPU cores)
```

**Check 2: Agent connectivity**
```bash
# From Jenkins server, test agent connection
ssh jenkins-agent@agent-url

# If connection is slow, network issue

# Check agent disk:
df -h
# Is agent disk > 80% full?

# Check agent CPU:
top -bn1 | head -20
```

**Check 3: GitHub API rate limit**
```bash
# Check if GitHub API is being rate-limited
curl -H "Authorization: Bearer [PAT]" https://api.github.com/rate_limit | jq '.rate_limit'

# If remaining is low, wait before running more jobs
```

**How to Fix:**

**If Jenkins is overloaded:**
```bash
# Cancel unnecessary builds
# Jenkins Dashboard → Build Queue
# Click "x" to cancel queued jobs

# Restart Jenkins if really slow:
sudo systemctl restart jenkins
```

**If agent disk is full:**
```bash
# See [Jenkins Out of Disk Space](#jenkins-out-of-disk-space) section
```

**If network is slow:**
```bash
# Check connectivity to GitHub
ssh jenkins-agent@agent-url
curl -I https://github.com
# Should respond quickly

# If slow, check:
# - Firewall rules
# - Network connectivity
# - GitHub status: https://www.githubstatus.com
```

**If rate-limited by GitHub:**
```bash
# GitHub API has 5000 requests/hour per token
# Wait an hour, or request higher limit
# For now, avoid triggering jobs unnecessarily
```

---

### Job Timeout

**Symptom:**
```
Job exceeded maximum build time
# Or: "Build step 'Execute shell' marked build as failure"
# Or: Job hangs and never completes
```

**Likely Causes:**
- Network timeout reaching GitHub
- Signature verification hanging (bad key)
- Disk full causing slowness
- Infinite loop or stuck process

**How to Check:**

**Check 1: How long did the job run?**
```bash
# Jenkins Dashboard → [Job] → [Build Number]
# Check: "Build took X minutes"
# Is it unusually long?

# Check Console Output for where it hung
```

**Check 2: Network connectivity**
```bash
# From Jenkins agent, test GitHub
ssh jenkins-agent@agent-url
curl -I https://github.com
# Should respond in < 5 seconds

# Test git fetch
cd /tmp
git clone --depth 1 https://github.com/rajames440/StarForth-Governance.git
# Should complete in < 30 seconds
```

**How to Fix:**

**Increase Jenkins timeout** (if normally slow):
```bash
# Jenkins Dashboard → Manage Jenkins → Configure System
# Search: "Build Timeout"
# Set timeout to higher value (e.g., 30 minutes)
```

**Kill hung jobs:**
```bash
# Jenkins Dashboard → Build Queue
# Click "x" to cancel stuck jobs

# Or on Jenkins server:
ps aux | grep java | grep -i jenkins
# Note the PID
kill -9 [PID]
```

**Check network performance:**
```bash
# Run a network test:
ssh jenkins-agent@agent-url
ping -c 5 github.com
# Should have < 50ms latency

# If high latency, might be network issue
```

---

## Getting Help

### When to Get Help

| Issue | Try This | Then Contact |
|-------|----------|--------------|
| Can't create GPG key | [GPG Not Installed](#gpg-not-installed) | PM |
| Signature won't verify | [Signature Verification Fails](#signature-verification-fails) | Operator |
| Can't push to GitHub | [Git Push Fails](#git-push-fails) | Operator |
| Jenkins job failed | Check Jenkins logs, then section above | Operator |
| Document not routed | [Document Not Routed](#document-not-routed) | Operator |
| Didn't get notification | [Notification Not Received](#notification-not-received) | PM |
| System very slow | [System Very Slow](#system-very-slow--hanging) | Operator |

### How to Report Issues

**Gather Information:**

Before contacting support, collect:

```bash
# 1. Your error message (exact text)
# 2. What you were trying to do
# 3. When it happened
# 4. What you've already tried

# Helpful outputs to include:
gpg --version
git --version
java -version  # if Jenkins-related
uname -a       # operating system
```

**Create a GitHub Issue:**

1. StarForth-Governance repo → Issues → New Issue
2. **Title:** Brief description (e.g., "Signature verification fails for CAPA-001")
3. **Description:**
   ```
   Describe the problem:
   - What I was trying to do
   - What happened
   - Error message (exact)
   - Steps to reproduce

   My environment:
   - OS: [Ubuntu/macOS/Windows]
   - GPG version: [output of gpg --version]
   - Git version: [output of git --version]
   ```
4. Click "Submit"

**Contact PM or Operator:**

- **PM (rajames440):** For authorization, document types, signature questions
- **Operator:** For Jenkins, GPG keys on agents, networking
- **Both:** For critical issues or when unsure

### Escalation Path

```
Issue discovered
  ↓
Check this guide (self-service)
  ↓
Try the suggested fix
  ↓
Success? Done!
  ↓
Still failing?
  ↓
Create GitHub issue with full details
  ↓
Ping PM or Operator (@mention)
  ↓
If critical: Direct message to PM
```

### Emergency Contact

If the system is completely down:

- **PM (rajames440):** rajames440@starforth.dev
- **On-call operator:** [Check Slack #governance-ops]

---

## Common Scenarios

### Scenario 1: "I signed the document but it's still showing as Pending"

**Steps:**
1. Check that your signature file was pushed to GitHub
   ```bash
   git log -- Pending/CAPA/CAPA-001*.asc
   # Should show your recent commit
   ```

2. Check that signature file has the right name
   ```bash
   # Should be: CAPA-001.[USERNAME].asc
   # Not: CAPA-001.adoc.asc
   ```

3. Manually verify the signature
   ```bash
   gpg --verify Pending/CAPA/CAPA-001.[USERNAME].asc Pending/CAPA/CAPA-001.adoc
   # Should say "Good signature"
   ```

4. Trigger Job 2 manually
   ```bash
   # Jenkins Dashboard → starforth-signature-verify → Build with Parameters
   # Fill in parameters and run
   ```

### Scenario 2: "PM asked me to sign but I'm not in the authorized signers list"

**Steps:**
1. Check Security/Signatures.adoc
   ```bash
   grep your-username Security/Signatures.adoc
   # If nothing found, you're not authorized
   ```

2. Contact PM
   ```
   "Hi PM, I was asked to sign CAPA-001 but I don't see myself in the
    Authorized Signers list. Can you add me?"
   ```

3. Wait for PM to update Signatures.adoc and push

4. You'll be notified for the next document

### Scenario 3: "Jenkins says 'Repository not found'"

**Steps:**
1. Verify GitHub PAT is valid and not expired
   ```bash
   curl -H "Authorization: Bearer [PAT]" https://api.github.com/user
   # Should show your user info
   ```

2. Check Jenkins credential is configured
   ```bash
   # Jenkins Dashboard → Manage Credentials
   # Should show: github-credentials (System)
   ```

3. Test git clone with PAT
   ```bash
   git clone https://[PAT]@github.com/rajames440/StarForth-Governance.git
   # If this works, PAT is valid
   ```

4. If Jenkins credential is missing or wrong:
   ```bash
   # Operator should reconfigure in Jenkins Credentials
   ```

---

## Additional Resources

- **Signer Onboarding Guide** - Getting started as a signer
- **Operator Runbook** - Managing Jenkins and the system
- **GitHub Repository** - StarForth-Governance on GitHub
- **Jenkins Dashboard** - http://[jenkins-url]:8080
- **GitHub GPG Documentation** - https://docs.github.com/en/authentication/managing-commit-signature-verification
- **GitHub CLI Documentation** - https://cli.github.com/manual/

---

## Document History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-03 | Initial troubleshooting guide | Rajames |

---

**Last Updated:** 2025-11-03
**Version:** 1.0
**Status:** Ready for use
