# Operator Runbook

**Version:** 1.0
**Last Updated:** 2025-11-03
**Audience:** System operators, DevOps engineers, IT admins
**Authority:** PM (rajames440)

This runbook provides procedures for setting up, operating, and maintaining the StarForth-Governance document signature and vault system.

---

## Table of Contents

1. [System Overview](#system-overview)
2. [Prerequisites & Architecture](#prerequisites--architecture)
3. [Initial Setup](#initial-setup)
4. [Day-to-Day Operations](#day-to-day-operations)
5. [Common Tasks](#common-tasks)
6. [Monitoring & Alerts](#monitoring--alerts)
7. [Troubleshooting](#troubleshooting)
8. [Emergency Procedures](#emergency-procedures)
9. [Maintenance Schedule](#maintenance-schedule)
10. [Rollback Procedures](#rollback-procedures)

---

## System Overview

### Architecture

The system has 4 main components:

```
┌─────────────────┐
│   GitHub Repo   │  StarForth-Governance
│  (in_basket,    │
│   Pending,      │
│   Vault, etc)   │
└────────┬────────┘
         │
         │ Git operations
         │ (clone, push, commit)
         ↓
┌─────────────────────────────────────────┐
│         Jenkins Server                  │
├─────────────────────────────────────────┤
│  Job 1: starforth-disposition           │
│  Job 2: starforth-signature-verify      │
│  Job 3: starforth-vault-router          │
│                                         │
│  Credentials: github-credentials (PAT)  │
│  Agents: Linux with git, jq, gpg        │
└─────────────────────────────────────────┘
         ↑
         │
    Monitor/Trigger
    (polls SCM, webhooks)
```

### Document Lifecycle

```
Step 1: Document Created
  → Placed in in_basket/

Step 2: Disposition (Job 1)
  → Classified by document type
  → Routed to Pending/[TYPE]/
  → Notification created (GitHub issue)
  → Signers notified

Step 3: Signature Collection (Job 2)
  → Signers create .asc signature files
  → Pipeline verifies each signature
  → Updates document's signature table
  → Creates PR #2 or #3

Step 4: Vault Routing (Job 3)
  → When all signatures collected (or PM override)
  → Document moved to Vault/[TYPE]/
  → Creates PR #4
  → Updates audit log (SEC_LOG.adoc)

Step 5: Complete
  → Document archived in vault
  → Immutable record created
```

### Key Files

| Path | Purpose |
|------|---------|
| `Security/Signatures.adoc` | List of authorized signers and their roles |
| `VAULT_ROUTING_MAP.md` | Where each document type goes (Vault or Pending) |
| `Security/SEC_LOG.adoc` | Audit log of all signature events |
| `Jenkinsfile.disposition` | Job 1 pipeline definition |
| `Jenkinsfile.signature-verify` | Job 2 pipeline definition |
| `Jenkinsfile.vault-router` | Job 3 pipeline definition |
| `bin/verify-signature.sh` | Script that verifies GPG signatures |

---

## Prerequisites & Architecture

### System Requirements

**Jenkins Server:**
- Jenkins 2.350 or higher
- 2 CPU cores minimum
- 4 GB RAM minimum
- 50 GB disk space
- Network access to GitHub

**Jenkins Plugins Required:**
- Pipeline (declarative and scripted)
- Git plugin v4.0+
- Credentials plugin
- GitHub plugin (optional, for webhooks)

**Jenkins Agent(s):**
- Linux (Ubuntu 20.04+, CentOS 8+, or equivalent)
- Git v2.20+
- Bash v4.0+
- Tools: `jq`, `gpg`, `curl`
- Network access to GitHub
- SSH or agent connectivity to Jenkins

**GitHub:**
- Repository: rajames440/StarForth-Governance
- Access token: Personal Access Token (PAT) with `repo` and `workflow` scopes
- Write access to repository (for Jenkins user)

**Network:**
- Jenkins → GitHub: Outbound HTTPS (port 443)
- GitHub webhooks → Jenkins: Inbound HTTPS (optional)

### Security Considerations

| Item | Requirement |
|------|-------------|
| GitHub PAT | Store in Jenkins secrets only, never commit to git |
| Private GPG Keys | Kept on signers' machines, never imported to Jenkins |
| Public GPG Keys | Imported on Jenkins agents, stored in `/var/lib/jenkins/.gnupg/` |
| Jenkins Access | Limit to authorized admins only |
| Audit Logs | Archive SEC_LOG.adoc regularly for compliance |

---

## Initial Setup

### Phase 1: Jenkins Server (30 minutes)

#### 1.1 Verify Jenkins Installation

```bash
# SSH to Jenkins server
ssh jenkins-admin@jenkins.example.com

# Check Jenkins version
curl -s http://localhost:8080 | grep -i version

# Verify required plugins are installed
# Go to Jenkins Dashboard → Manage Jenkins → Manage Plugins → Installed
# Look for: Pipeline, Git, Credentials, GitHub
```

#### 1.2 Install Missing Plugins

**If any plugins are missing:**

1. Jenkins Dashboard → Manage Jenkins → Manage Plugins
2. Click "Available" tab
3. Search for: `Pipeline`, `Git`, `Credentials`, `GitHub`
4. Check boxes next to each
5. Click "Download now and install after restart"
6. Restart Jenkins

#### 1.3 Configure Jenkins User

Jenkins needs a user to perform git operations:

```bash
# On Jenkins server, add jenkins user to docker group (if using Docker)
# This allows Jenkins to run docker commands if needed
sudo usermod -aG docker jenkins

# Create .ssh directory
sudo mkdir -p /var/lib/jenkins/.ssh
sudo chown jenkins:jenkins /var/lib/jenkins/.ssh
sudo chmod 700 /var/lib/jenkins/.ssh
```

### Phase 2: GitHub Credentials (30 minutes)

#### 2.1 Create GitHub Personal Access Token

**In GitHub (as rajames440):**

1. Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Click "Generate new token (classic)"
3. **Token name:** `starforth-jenkins`
4. **Expiration:** 90 days
5. **Scopes:**
   - ✅ `repo` (full control)
   - ✅ `workflow` (GitHub Actions integration)
   - ✅ `read:user` (read user profile)

6. Click "Generate token"
7. **Copy the token** (you'll only see it once)
8. **Store securely** (password manager)

#### 2.2 Configure Jenkins Credential

**In Jenkins Dashboard:**

1. Manage Jenkins → Manage Credentials
2. Click "global" store (System)
3. Click "Add Credentials"
4. **Kind:** Username with password
5. **ID:** `github-credentials` ← **EXACT MATCH REQUIRED**
6. **Username:** `github-bot` (or any username)
7. **Password:** `[Paste your PAT here]`
8. **Scope:** Global
9. Click "Create"

#### 2.3 Verify Credential

1. Go back to Credentials → System → global
2. You should see `github-credentials` listed
3. Click it, then "Update"
4. Verify the password field has your PAT (shown as ***)

### Phase 3: Create Jenkins Jobs (1-2 hours)

**Reference:** Use `JENKINS_JOB_SETUP.md` for detailed configuration

#### 3.1 Create Job 1: starforth-disposition

1. Jenkins Dashboard → New Item
2. **Name:** `starforth-disposition`
3. **Type:** Pipeline → OK
4. **Description:** Document Disposition Pipeline - Route in_basket to Pending

**Pipeline Configuration:**
- **Definition:** Pipeline script from SCM
- **SCM:** Git
- **Repository URL:** `https://github.com/rajames440/StarForth-Governance.git`
- **Credentials:** Select `github-credentials`
- **Branch Specifier:** `*/master`
- **Script Path:** `Jenkinsfile.disposition`

**Build Triggers:**
- ✅ Build periodically
- **Schedule:** `H/15 * * * *` (every 15 minutes)

**Build Parameters:**
- `DRY_RUN` (Boolean, default: false)
- `PROCESS_DOCUMENT` (String, default: empty)

**Save** → Job created ✓

#### 3.2 Create Job 2: starforth-signature-verify

1. Jenkins Dashboard → New Item
2. **Name:** `starforth-signature-verify`
3. **Type:** Pipeline → OK
4. **Description:** Signature Verification Pipeline

**Pipeline Configuration:** (same as above)
- **Script Path:** `Jenkinsfile.signature-verify`

**Build Triggers:**
- ❌ None (manual trigger with parameters)

**Build Parameters:**
- `DOCUMENT_PATH` (String, required)
- `SIGNATURE_FILE` (String, required)
- `SIGNER_USERNAME` (String, required)
- `DRY_RUN` (Boolean, default: false)

**Save** → Job created ✓

#### 3.3 Create Job 3: starforth-vault-router

1. Jenkins Dashboard → New Item
2. **Name:** `starforth-vault-router`
3. **Type:** Pipeline → OK
4. **Description:** Vault Router Pipeline

**Pipeline Configuration:** (same as above)
- **Script Path:** `Jenkinsfile.vault-router`

**Build Triggers:**
- ❌ None (manual trigger with parameters)

**Build Parameters:**
- `DOCUMENT_PATH` (String, required)
- `DOCUMENT_TYPE` (String, required)
- `DRY_RUN` (Boolean, default: false)
- `FORCE_PM_OVERRIDE` (Boolean, default: false)

**Save** → Job created ✓

### Phase 4: Jenkins Agent Setup (30 minutes)

#### 4.1 Install Required Tools on Agent(s)

**SSH to Jenkins agent:**

```bash
ssh jenkins-agent@agent.example.com

# Install dependencies
sudo apt-get update
sudo apt-get install -y \
    git \
    jq \
    gnupg \
    curl

# Verify installations
git --version
jq --version
gpg --version
```

#### 4.2 Configure Git on Agent

```bash
# As the Jenkins user (or whoever runs jobs)
git config --global user.name "Jenkins Pipeline"
git config --global user.email "jenkins@starforth.governance"

# For push operations, also configure:
git config --global push.default current
```

#### 4.3 Test Agent Connectivity

**In Jenkins Dashboard:**
1. Manage Jenkins → Manage Nodes and Clouds
2. Your agent should be listed
3. Click the agent name
4. Click "Run Test" to verify connectivity

### Phase 5: GPG Key Setup (1-2 hours)

**Reference:** Use `GITHUB_AND_GPG_SETUP.md` for detailed instructions

#### 5.1 Import Signer Public Keys on Jenkins Agent(s)

For each authorized signer in `Security/Signatures.adoc`:

```bash
# SSH to Jenkins agent
ssh jenkins-agent@agent.example.com

# Become Jenkins user
sudo su - jenkins

# Create gnupg directory
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# Import each signer's public key (get .asc files from PM)
gpg --import ~/keys/rajames440-public.asc
gpg --import ~/keys/eng-manager-public.asc
gpg --import ~/keys/qa-lead-public.asc
# ... repeat for all signers

# Verify imports
gpg --list-keys

# Output should show all imported keys:
# pub   rsa4096 2025-11-03 [SC]
#      ABCDEF1234567890ABCDEF1234567890ABCDEF12
# uid           [ unknown] rajames440 <rajames440@starforth.dev>
```

#### 5.2 Set Up Trust Levels (Optional but Recommended)

```bash
# For each key, set ultimate trust
gpg --edit-key ABCDEF1234567890ABCDEF1234567890ABCDEF12

# At gpg> prompt:
trust
5    # Ultimate trust
quit
```

### Phase 6: Test Everything (30 minutes)

#### 6.1 Test Job 1

```bash
# In Jenkins Dashboard:
# 1. Go to starforth-disposition job
# 2. Click "Build Now"
# 3. Watch the build log
# 4. Should complete successfully (may process 0 documents if in_basket is empty)
```

#### 6.2 Test Job 2

```bash
# In Jenkins Dashboard:
# 1. Go to starforth-signature-verify job
# 2. Click "Build with Parameters"
# 3. Enter test parameters:
#    DOCUMENT_PATH: Pending/CAPA/TEST-CAPA-001.adoc
#    SIGNATURE_FILE: TEST-CAPA-001.rajames440.asc
#    SIGNER_USERNAME: rajames440
#    DRY_RUN: true
# 4. Click "Build"
# 5. Check logs for "Signature verified" message
```

#### 6.3 Test Job 3

```bash
# In Jenkins Dashboard:
# 1. Go to starforth-vault-router job
# 2. Click "Build with Parameters"
# 3. Enter test parameters:
#    DOCUMENT_PATH: Pending/CAPA/TEST-CAPA-001.adoc
#    DOCUMENT_TYPE: CAPA
#    DRY_RUN: true
# 4. Click "Build"
# 5. Check logs for "Document routed to vault" message
```

---

## Day-to-Day Operations

### Morning Checklist

**Start of day:**

```bash
# SSH to Jenkins server
ssh jenkins-admin@jenkins.example.com

# 1. Check Jenkins is running
curl -s http://localhost:8080/api/json | jq '.numExecutors'
# Should return a number > 0

# 2. Check agent connectivity
curl -s http://localhost:8080/api/json | jq '.numExecutors'

# 3. Check recent builds
curl -s http://localhost:8080/job/starforth-disposition/lastBuild/api/json | \
  jq '{number: .number, result: .result, duration: .duration}'

# 4. Check for failed builds
curl -s http://localhost:8080/queue/api/json | jq '.items'
# Empty array = no queued jobs
```

### Document Processing

When a PM adds a document to `in_basket/`:

1. **Job 1 automatically runs** every 15 minutes
   - Detects the document
   - Classifies it (based on filename)
   - Moves to `Pending/[TYPE]/`
   - Creates GitHub issue for signers

2. **Operator verifies:** Check GitHub notifications
   - Is the GitHub issue created?
   - Are signers assigned?

3. **Signers review and sign**
   - They create `.asc` signature files
   - Push to the repository

4. **Job 2 processes signatures** (manual or automatic)
   - Verifies each signature
   - Updates document's signature table
   - Creates PR #2 or #3

5. **Operator verifies:** Check PRs
   - Are all signatures verified?
   - Are any signatures invalid?

6. **PM approves and merges PR** or requests signature updates

7. **When ready: Operator runs Job 3**
   - Routes document to vault
   - Creates final PR #4
   - Updates audit log

### Weekly Tasks

**Every Monday:**

```bash
# Check Jenkins disk usage
ssh jenkins-admin@jenkins.example.com
du -sh /var/lib/jenkins/

# If > 80% full, clean old build logs:
# Jenkins Dashboard → Manage Jenkins → Script Console
# Run: Jenkins.instance.getItemByFullName('starforth-disposition').getBuilds().each {
#   if (it.number < it.getParent().lastBuild.number - 50) it.delete()
# }

# Check GitHub API rate limits
curl -H "Authorization: Bearer [PAT]" https://api.github.com/rate_limit | jq '.rate_limit'
```

**Every Friday:**

```bash
# Verify all signers' public keys are still imported
# SSH to each agent:
ssh jenkins-agent@agent.example.com
sudo su - jenkins
gpg --list-keys | wc -l  # Should match number of signers

# Backup audit log
git clone https://github.com/rajames440/StarForth-Governance.git
cp StarForth-Governance/Security/SEC_LOG.adoc \
   ~/backups/SEC_LOG.adoc.$(date +%Y-%m-%d)
```

---

## Common Tasks

### Add a New Signer

When a new team member needs to sign documents:

**Step 1: Get their public key**
```bash
# Request from PM or new signer
# They run: gpg --export --armor their@email.com > their-public.asc
# Share with you via email or GitHub

# Save to: ~/keys/[username]-public.asc
```

**Step 2: Import on all Jenkins agents**
```bash
# SSH to each agent
ssh jenkins-agent@agent.example.com
sudo su - jenkins

# Import new key
gpg --import ~/keys/[username]-public.asc

# Verify
gpg --list-keys [username]
```

**Step 3: Update Signatures.adoc**
```bash
# In StarForth-Governance repo
# Edit: Security/Signatures.adoc
# Add new signer to the Authorized Signers table
# Push to master
```

### Revoke a Signer

When a team member leaves or loses access:

**Step 1: Update Signatures.adoc**
```bash
# Edit: Security/Signatures.adoc
# Mark signer as "Inactive" in the table
# Push to master
```

**Step 2: Remove their public key from Jenkins agents** (optional, for security)
```bash
# SSH to each agent
ssh jenkins-agent@agent.example.com
sudo su - jenkins

# Find key ID
gpg --list-keys [username]
# Output shows: pub   rsa4096 2025-11-03 [SC]
#              ABCDEF1234567890

# Delete key
gpg --delete-keys ABCDEF1234567890

# Verify removed
gpg --list-keys [username]
# Should show: "gpg: error reading key: No public key"
```

### Rotate GitHub PAT

Every 90 days or when credentials expire:

**Step 1: Create new PAT**
```bash
# In GitHub: Settings → Developer settings → Personal access tokens
# Generate new token with same scopes as old one
# Copy the new token
```

**Step 2: Update Jenkins credential**
```bash
# Jenkins Dashboard → Manage Credentials
# Click on "github-credentials"
# Click "Update"
# Paste new PAT into password field
# Click "Save"
```

**Step 3: Test with a job**
```bash
# Run any job to verify
# Jenkins Dashboard → starforth-disposition → Build Now
# Check that git operations succeed
```

**Step 4: Revoke old PAT**
```bash
# In GitHub: Settings → Developer settings → Personal access tokens
# Find the old token (starforth-jenkins)
# Click "Delete"
```

### Force a Document Through (PM Override)

If a signer doesn't respond by Day 3, PM can override:

**Step 1: PM makes decision**
```bash
# PM contacts you to force override
# Document path: Pending/CAPA/CAPA-001.adoc
# Reason: "Signer on vacation"
```

**Step 2: Run vault-router with override**
```bash
# Jenkins Dashboard → starforth-vault-router → Build with Parameters
# DOCUMENT_PATH: Pending/CAPA/CAPA-001.adoc
# DOCUMENT_TYPE: CAPA
# FORCE_PM_OVERRIDE: true
# DRY_RUN: false

# Click "Build"
# Verify in logs: "PM override applied"
```

**Step 3: Verify audit log**
```bash
# Check Security/SEC_LOG.adoc
# Should show event: "[PM_OVERRIDE] CAPA-001 forced through"
```

### Test a Job (Dry Run)

To test without committing changes:

```bash
# Any job can be run in dry-run mode
# Jenkins Dashboard → [Job Name] → Build with Parameters

# Set: DRY_RUN = true
# Other parameters as normal

# Job will:
# - Process documents
# - Verify signatures
# - NOT commit to repository
# - NOT push to GitHub
# - NOT create PRs

# Check logs to verify behavior without side effects
```

---

## Monitoring & Alerts

### Build Failure Notifications

**Set up Jenkins email notifications:**

1. Jenkins Dashboard → Manage Jenkins → Configure System
2. Search for "Email Notification"
3. **SMTP Server:** mail.example.com
4. **Default user suffix:** @starforth.dev
5. **Save**

**For each job:**

1. Job → Configure
2. Scroll to "Post-build Actions"
3. Click "Add post-build action" → "Email Notification"
4. **Recipients:** rajames440@starforth.dev
5. **Send email for every unstable build:** ✅
6. **Send separate email to individuals who broke the build:** ✅
7. **Save**

### Monitoring Checklist

| Item | Check | Frequency | Action |
|------|-------|-----------|--------|
| Jenkins status | Is Jenkins running? | Daily | Restart if needed |
| Build queue | Any stuck jobs? | Daily | Cancel if hung > 30 min |
| Agent connectivity | Can agents reach Jenkins? | Daily | Restart agent if offline |
| Disk usage | Is Jenkins disk < 80%? | Weekly | Clean logs if needed |
| GitHub connectivity | Can Jenkins reach GitHub? | Weekly | Check firewall rules |
| GPG keys | Are all signer keys imported? | Monthly | Re-import if missing |
| PAT expiration | Does PAT expire soon? | Monthly | Rotate before expiry |

### Log Rotation

Jenkins builds create large logs. Configure rotation:

**On Jenkins server:**

```bash
# Edit Jenkins config
sudo nano /etc/default/jenkins

# Add or modify:
# JENKINS_JAVA_OPTIONS="-Dorg.jenkinsci.plugins.durabletask.BourneShellScript.HEARTBEAT_INTERVAL=300"

# Restart Jenkins
sudo systemctl restart jenkins
```

---

## Troubleshooting

### Job Fails: "Repository not found"

**Problem:** Jenkins can't clone the repository

**Check:**
```bash
# 1. Verify credential ID is correct
# Job config should reference: github-credentials

# 2. Test PAT manually
curl -H "Authorization: Bearer [PAT]" https://api.github.com/user
# Should show your GitHub user info

# 3. Test git clone
git clone https://github-bot:[PAT]@github.com/rajames440/StarForth-Governance.git
```

**Solutions:**
1. Verify PAT is not expired or revoked
2. Verify PAT has `repo` scope
3. Update credential in Jenkins with new PAT
4. Test job again

### Job Fails: "Permission denied" on push

**Problem:** Jenkins can push to GitHub but not to your repo

**Check:**
```bash
# 1. Verify PAT has write access
curl -H "Authorization: Bearer [PAT]" https://api.github.com/repos/rajames440/StarForth-Governance
# Should show: "permission": "admin"

# 2. Check branch protection rules
# GitHub → Settings → Branches → Branch protection rules
# Is master branch protected?
# If yes, does Jenkins user have bypass permission?
```

**Solutions:**
1. Ensure PAT has `repo` (full control) scope
2. If master is protected, Jenkins must be an admin or have bypass role
3. Add Jenkins app to repository collaborators with Admin role

### Signature Verification Fails

**Problem:** Job 2 returns "signature verification failed"

**Check:**
```bash
# 1. SSH to Jenkins agent
ssh jenkins-agent@agent.example.com
sudo su - jenkins

# 2. Verify signer's public key is imported
gpg --list-keys [signer-username]
# Should show the key with [SC] flags

# 3. Manually test verification
gpg --verify /path/to/signature.asc /path/to/document.adoc
# Should show "Good signature"

# 4. Check signature file format
file /path/to/signature.asc
# Should show "armor" or "ASCII armor"
```

**Solutions:**
1. Import missing signer's public key (see [Add a New Signer](#add-a-new-signer))
2. Ask signer to recreate signature (maybe file was corrupted)
3. Verify signer didn't modify the document after signing

### Jenkins Out of Disk Space

**Problem:** Jenkins builds slow or fail with "No space left"

**Check:**
```bash
ssh jenkins-admin@jenkins.example.com

# Check disk usage
df -h /var/lib/jenkins
# If > 80%, need cleanup

# Find largest directories
du -sh /var/lib/jenkins/* | sort -rh | head -10
```

**Solutions:**
```bash
# 1. Clean old build logs (keep last 50)
# Jenkins Dashboard → Manage Jenkins → Script Console
# Paste and run:
Jenkins.instance.getItemByFullName('starforth-disposition').getBuilds().each {
  if (it.number < it.getParent().lastBuild.number - 50) it.delete()
}

# 2. Expand disk
# Stop Jenkins, expand partition, restart

# 3. Configure log rotation
# Jenkins Dashboard → Manage Jenkins → Configure System
# Set "Artifact Manager" to clean old artifacts
```

### Escalation Not Triggering

**Problem:** Day 3 escalation doesn't happen automatically

**Check:**
```bash
# 1. Verify Job 1 is running on schedule
# Jenkins Dashboard → starforth-disposition → Build History
# Should see builds approximately every 15 minutes

# 2. Check if escalation logic exists
grep -n "escalation\|Day 3" /path/to/Jenkinsfile.disposition

# 3. Check document path in Pending/
# Is the document actually in Pending/[TYPE]/?
# Is it not signed yet?
```

**Solutions:**
1. If Job 1 doesn't run, check Build Triggers are set to `H/15 * * * *`
2. If Job 1 runs but escalation doesn't happen, check Jenkins logs
3. Manually trigger Job 1: Dashboard → starforth-disposition → Build Now

---

## Emergency Procedures

### Document Leaked/Compromised

If a document in Pending/ is accidentally exposed or leaked:

**Immediate Actions (within 1 hour):**

1. **Stop all processing:**
   ```bash
   # Jenkins Dashboard → Build Queue
   # Cancel any running jobs
   ```

2. **Notify PM immediately:**
   ```bash
   # Contact rajames440 with:
   # - Document name
   # - When it was compromised
   # - Who had access
   ```

3. **Document the incident:**
   - Take screenshots of GitHub history
   - Note all PRs that touched the document
   - Save logs for audit

**Resolution (within 24 hours):**

1. **PM decides on response:**
   - Delete the document and restart
   - Re-sign the document
   - Accept the risk

2. **Update SEC_LOG.adoc:**
   ```bash
   # Add entry:
   # [SECURITY_INCIDENT] DOCUMENT_NAME - compromised on [date]
   # Reason: [description]
   # Resolution: [action taken]
   ```

3. **Resume processing** once PM approves

### GitHub Credentials Compromised

If GitHub PAT is exposed or leaked:

**Immediate (within 30 minutes):**

1. **Revoke the PAT:**
   ```bash
   # In GitHub: Settings → Developer settings → Personal access tokens
   # Find "starforth-jenkins"
   # Click "Delete"
   ```

2. **Create new PAT:**
   - Same process as [Rotate GitHub PAT](#rotate-github-pat)
   - New token immediately active

3. **Update Jenkins:**
   - Jenkins Dashboard → Manage Credentials
   - Update github-credentials with new PAT

4. **Test:**
   - Run a job to verify
   - Jenkins Dashboard → starforth-disposition → Build Now

**Post-incident:**

1. **Check GitHub audit log** for any suspicious activity
2. **Review commits** made during compromise window
3. **Document the incident** in SEC_LOG.adoc

### Jenkins Server Down

If Jenkins is unavailable:

**Immediate (within 30 minutes):**

1. **Attempt restart:**
   ```bash
   sudo systemctl restart jenkins

   # Wait 2 minutes
   curl http://localhost:8080
   # Should return HTML
   ```

2. **If restart fails, check logs:**
   ```bash
   sudo tail -100 /var/log/jenkins/jenkins.log
   sudo systemctl status jenkins
   ```

3. **If still down, restart the server:**
   ```bash
   sudo reboot
   # Jenkins should auto-start
   ```

**During Downtime:**

- **Signers can still commit** signature files directly to GitHub
- **PM can review PRs** manually
- **PM can merge PRs** manually (temporarily bypassing job automation)

**When Jenkins is back up:**

1. **Verify all jobs:**
   ```bash
   Jenkins Dashboard → status
   # Should show all jobs
   ```

2. **Re-run Job 2 & 3 for any documents**:
   ```bash
   # If signatures were committed while Jenkins was down
   # Run signature-verify and vault-router jobs manually
   ```

3. **Update SEC_LOG.adoc:**
   ```bash
   # Add entry: [SYSTEM_DOWNTIME] Jenkins unavailable [start] to [end]
   ```

---

## Maintenance Schedule

### Daily
- Check Jenkins status
- Monitor build logs for failures
- Verify no stuck jobs

### Weekly
- Check disk usage
- Verify agent connectivity
- Audit recent commits
- Clean old build logs if needed

### Monthly
- Check GitHub PAT expiration (rotate if < 30 days left)
- Verify all signer keys are imported
- Review SEC_LOG.adoc for anomalies
- Backup audit log

### Quarterly (Every 90 days)
- Full system health check
- Update Jenkins (if patches available)
- Review and update this runbook
- Test disaster recovery procedures

### Annually
- Review and update Security/Signatures.adoc
- Audit all vault documents
- Security assessment
- Capacity planning

---

## Rollback Procedures

### Rollback a Merged PR

If a PR introduces a problem after merging:

**Step 1: Revert the commit**

```bash
# Clone the repo
git clone https://github.com/rajames440/StarForth-Governance.git
cd StarForth-Governance

# Find the commit to revert
git log --oneline | grep -i "[document or change name]"

# Revert it (creates new commit)
git revert [commit-hash]

# Push
git push origin master
```

**Step 2: Verify in GitHub**

```bash
# Check GitHub repo
# Should see new "Revert" commit on master
```

**Step 3: Document the rollback**

```bash
# Edit: Security/SEC_LOG.adoc
# Add: [ROLLBACK] PR #N reverted due to [reason]
```

### Rollback Jenkins Configuration

If a job is misconfigured and causing failures:

**Step 1: Restore from backup** (if you have one)

```bash
# Jenkins stores job config in:
# /var/lib/jenkins/jobs/[job-name]/config.xml

# If you have a backup:
sudo cp /backup/config.xml /var/lib/jenkins/jobs/[job-name]/config.xml
sudo systemctl restart jenkins
```

**Step 2: Reconfigure manually**

```bash
# If no backup, reconfigure using JENKINS_JOB_SETUP.md
# 1. Delete the job
# 2. Create it again with correct settings
# 3. Test before running on real documents
```

### Rollback a Signature

If a signature is incorrect or needs to be re-signed:

**Step 1: Delete the signature file**

```bash
git clone https://github.com/rajames440/StarForth-Governance.git
cd StarForth-Governance

# Find the signature file
ls Pending/[TYPE]/[DOCUMENT]*.asc

# Delete it
git rm Pending/[TYPE]/[DOCUMENT].[signer].asc
git commit -m "docs(signature): Remove invalid signature from [signer]"
git push origin master
```

**Step 2: Ask signer to re-sign**

```bash
# Contact the signer
# They create a new signature and commit it
```

**Step 3: Run Job 2 again**

```bash
# Jenkins Dashboard → starforth-signature-verify → Build with Parameters
# DOCUMENT_PATH: Pending/[TYPE]/[DOCUMENT].adoc
# SIGNATURE_FILE: [DOCUMENT].[signer].asc
# SIGNER_USERNAME: [signer]
# DRY_RUN: false

# Job will verify and update the signature table
```

---

## Support & Escalation

### Getting Help

| Issue | Contact | Urgency |
|-------|---------|---------|
| Job failing | Check this runbook first, then PM | Medium |
| Jenkins down | Restart, then contact IT | High |
| GitHub credentials issue | Update PAT, test, then notify PM | High |
| Signature verification error | Check GPG setup, contact signer | Medium |
| Document compromise | Contact PM immediately | Critical |

### Key Contacts

| Role | Name | Email |
|------|------|-------|
| PM / Owner | Rajames | rajames440@starforth.dev |
| IT / DevOps | [Your DevOps] | [DevOps email] |
| Security Lead | [Security] | [Security email] |

---

## Document History

| Date | Change | Author |
|------|--------|--------|
| 2025-11-03 | Initial runbook created | Rajames |

---

**Last Updated:** 2025-11-03
**Version:** 1.0
**Status:** Ready for production

== Signatures

|===
| Signer | Status | Date | Signature

| rajames440 | Pending |  |
|===
