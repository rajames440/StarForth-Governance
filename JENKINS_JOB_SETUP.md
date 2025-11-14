# Jenkins Job Configuration Guide

**Date:** 2025-11-03
**Status:** Configuration Instructions (Ready to execute)

This guide configures the 3 Jenkins pipeline jobs required for the StarForth-Governance disposition workflow.

## Prerequisites

- Jenkins 2.350+ installed
- Jenkins Pipeline plugin installed
- Git plugin configured
- GitHub credentials available (PAT or SSH key)

## Job 1: starforth-disposition

**Purpose:** Main document disposition pipeline - routes documents from in_basket to Pending/

### Configuration

#### 1. Create New Pipeline Job

In Jenkins, click **+ New Item** → **Pipeline** → **OK**

#### 2. Basic Configuration

```
Name:        starforth-disposition
Description: Document Disposition Pipeline - Route in_basket to Pending
```

#### 3. Pipeline Section

**Definition:** Pipeline script from SCM

**SCM:** Git
- **Repository URL:** https://github.com/rajames440/StarForth-Governance.git
- **Credentials:** `github-credentials` (configured separately)
- **Branch Specifier:** `*/master`
- **Script Path:** `jenkinsfiles/disposition/Jenkinsfile`

#### 4. Build Triggers

**Check:** Build periodically
- **Schedule:** `H/15 * * * *`
- **Description:** Poll in_basket every 15 minutes for new documents

**Optional:** GitHub hook trigger for GITscm polling
- Enables real-time triggering when documents added

#### 5. Build Parameters

Add these build parameters:

| Name | Type | Default | Description |
|------|------|---------|-------------|
| DRY_RUN | Boolean | false | Test mode - no commits/pushes |
| PROCESS_DOCUMENT | String | (empty) | Process specific document (filename) |

#### 6. Save

Click **Save** to create the job.

### Jenkins UI Path

1. Jenkins Dashboard
2. Manage Jenkins → Configure System (if first time)
3. Dashboard → starforth-disposition → Configure
4. Fill in as above
5. Save

---

## Job 2: starforth-signature-verify

**Purpose:** Signature collection pipeline - processes .asc files from signers

### Configuration

#### 1. Create New Pipeline Job

**Name:** starforth-signature-verify

#### 2. Basic Configuration

```
Description: Signature Verification Pipeline - Create PR #2/#3
```

#### 3. Pipeline Section

**Definition:** Pipeline script from SCM

**SCM:** Git
- **Repository URL:** https://github.com/rajames440/StarForth-Governance.git
- **Credentials:** `github-credentials`
- **Branch Specifier:** `*/master`
- **Script Path:** `jenkinsfiles/signature-verify/Jenkinsfile`

#### 4. Build Triggers

**Check:** None (manual trigger with parameters)

**Optional:** GitHub webhook for .asc file changes
- Triggers automatically when signature files added

#### 5. Build Parameters

Add these build parameters (REQUIRED):

| Name | Type | Default | Description |
|------|------|---------|-------------|
| DOCUMENT_PATH | String | (required) | Path to document in Pending/ |
| SIGNATURE_FILE | String | (required) | Path to .asc signature file |
| SIGNER_USERNAME | String | (required) | Username of signer |
| DRY_RUN | Boolean | false | Test mode |

#### 6. Save

Click **Save** to create the job.

### Usage

Trigger manually with parameters:
```
DOCUMENT_PATH: Pending/CAPA/CAPA-001.adoc
SIGNATURE_FILE: CAPA-001.rajames440.asc
SIGNER_USERNAME: rajames440
DRY_RUN: false
```

---

## Job 3: starforth-vault-router

**Purpose:** Vault routing pipeline - moves signed documents to vault

### Configuration

#### 1. Create New Pipeline Job

**Name:** starforth-vault-router

#### 2. Basic Configuration

```
Description: Vault Router Pipeline - Create PR #4 (move to vault)
```

#### 3. Pipeline Section

**Definition:** Pipeline script from SCM

**SCM:** Git
- **Repository URL:** https://github.com/rajames440/StarForth-Governance.git
- **Credentials:** `github-credentials`
- **Branch Specifier:** `*/master`
- **Script Path:** `jenkinsfiles/vault-router/Jenkinsfile`

#### 4. Build Triggers

**Check:** None (manual trigger with parameters)

**Optional:** Trigger after starforth-signature-verify success
- Configure in signature-verify job post-success action

#### 5. Build Parameters

Add these build parameters (REQUIRED):

| Name | Type | Default | Description |
|------|------|---------|-------------|
| DOCUMENT_PATH | String | (required) | Path to document in Pending/ |
| DOCUMENT_TYPE | String | (required) | Doc type (CAPA, ECR, etc.) |
| DRY_RUN | Boolean | false | Test mode |
| FORCE_PM_OVERRIDE | Boolean | false | PM override for incomplete signatures |

#### 6. Save

Click **Save** to create the job.

### Usage

Trigger manually with parameters:
```
DOCUMENT_PATH: Pending/CAPA/CAPA-001.adoc
DOCUMENT_TYPE: CAPA
DRY_RUN: false
FORCE_PM_OVERRIDE: false
```

---

## Jenkins Agent Requirements

All three jobs require a Jenkins agent with:

- **OS:** Linux (or macOS/Windows with Git bash)
- **Git:** v2.20+
- **Bash:** v4.0+
- **Tools installed:**
  - `jq` (JSON query tool)
  - `gpg` (GPG signature verification)
  - `sed`, `awk`, `grep` (standard utilities)

### Agent Installation

If using Docker agents, include in Dockerfile:
```dockerfile
RUN apt-get update && apt-get install -y \
    git \
    jq \
    gnupg \
    curl \
    && rm -rf /var/lib/apt/lists/*
```

If using EC2/bare metal agents:
```bash
sudo apt-get update
sudo apt-get install -y git jq gnupg curl
```

---

## Jenkins Credentials Setup

All three jobs reference credential ID: `github-credentials`

### Configure Credential

**Via Jenkins UI:**
1. Jenkins Dashboard → Manage Jenkins → Manage Credentials
2. Click "global" store
3. Add Credentials → Username with password
4. **ID:** `github-credentials` (MUST match)
5. **Username:** `(anything)` e.g., "github-bot"
6. **Password:** GitHub Personal Access Token
7. **Scope:** Global
8. Click **Create**

### Required GitHub PAT Permissions

When creating the GitHub Personal Access Token:
- ✅ repo (full control)
- ✅ workflow (optional, for deployment workflows)
- ✅ read:user (read user info)
- ❌ write:admin (not needed)

**DO NOT add PAT to codebase.** Store in Jenkins secrets only.

---

## Webhook Configuration (Optional)

To trigger pipelines automatically on git events:

### For starforth-disposition

GitHub WebHook → Jenkins Pipeline

**In GitHub:**
1. StarForth-Governance repo → Settings → Webhooks
2. Add webhook
3. **Payload URL:** `https://[jenkins-url]/github-webhook/`
4. **Content type:** application/json
5. **Events:** Push events
6. ✅ Active

**In Jenkins:**
1. starforth-disposition job → Configure
2. Build Triggers → GitHub hook trigger for GITscm polling
3. ✅ Check
4. Save

**Trigger:** Every push to master (checks for in_basket changes)

### For starforth-signature-verify

**GitHub WebHook:**
- Same as above (push events on master)

**In Jenkins:**
1. starforth-signature-verify job → Configure
2. Build Triggers: None (requires manual parameter input)
3. Or: Configure custom webhook to detect .asc files

**Alternative:** Use polling
- Build Triggers → Poll SCM: `H/5 * * * *`
- Checks for new .asc files every 5 minutes

---

## Testing the Jobs

### Test Job 1: starforth-disposition

```bash
# Manually trigger
curl -X POST https://[jenkins-url]/job/starforth-disposition/build \
  -H "Authorization: Bearer [jenkins-token]"

# Or in Jenkins UI:
# Dashboard → starforth-disposition → Build Now
```

Expected behavior:
- Scans in_basket/
- Classifies TEST-CAPA-001.adoc and TEST-ECR-001.md
- Routes to Pending/CAPA/ and Pending/ECR/
- Creates PR #1 commit

### Test Job 2: starforth-signature-verify

```bash
# Manual trigger with parameters
curl -X POST https://[jenkins-url]/job/starforth-signature-verify/buildWithParameters \
  -d "DOCUMENT_PATH=Pending/CAPA/CAPA-001.adoc" \
  -d "SIGNATURE_FILE=CAPA-001.rajames440.asc" \
  -d "SIGNER_USERNAME=rajames440" \
  -d "DRY_RUN=false"

# Or in Jenkins UI:
# Dashboard → starforth-signature-verify → Build with Parameters
```

Expected behavior:
- Verifies signature
- Updates signature table
- Creates PR #2/#3 commit

### Test Job 3: starforth-vault-router

```bash
# Manual trigger with parameters
curl -X POST https://[jenkins-url]/job/starforth-vault-router/buildWithParameters \
  -d "DOCUMENT_PATH=Pending/CAPA/CAPA-001.adoc" \
  -d "DOCUMENT_TYPE=CAPA" \
  -d "DRY_RUN=false" \
  -d "FORCE_PM_OVERRIDE=false"

# Or in Jenkins UI:
# Dashboard → starforth-vault-router → Build with Parameters
```

Expected behavior:
- Moves document to Defects/
- Creates PR #4 commit
- Updates SEC_LOG.adoc

---

## Job Orchestration

### Manual Workflow

```
starforth-disposition (manual trigger)
  ↓
  → Scans in_basket
  → Routes to Pending/
  → Notifies signers (GitHub notification)

[Signers add .asc files]

starforth-signature-verify (manual trigger per signature)
  ↓
  → Verifies signature
  → Updates signature table
  → Creates PR #2/#3

[All signatures collected]

starforth-vault-router (manual trigger)
  ↓
  → Moves to vault
  → Creates PR #4
  → Updates SEC_LOG.adoc
```

### Automated Workflow (with webhooks)

```
[Document added to in_basket]
  ↓ (GitHub webhook triggers)
starforth-disposition
  ↓
  → Routes to Pending/
  → Notifies signers (GitHub notification)

[Signer adds .asc file]
  ↓ (GitHub webhook triggers)
starforth-signature-verify
  ↓
  → Verifies and updates

[All signatures ready]
  ↓ (Manual trigger)
starforth-vault-router
  ↓
  → Moves to vault
```

---

## Troubleshooting

### Job fails with "Repository not found"

**Problem:** Jenkins can't clone the repo
**Solution:**
1. Verify GitHub credentials exist with ID: `github-credentials`
2. Verify PAT has `repo` permission
3. Test: `git clone https://[PAT]@github.com/rajames440/StarForth-Governance.git`

### Job fails with "Permission denied" on git push

**Problem:** Jenkins user can't push to repo
**Solution:**
1. Verify PAT has `repo` permission (not read-only)
2. Verify `github-credentials` are correct
3. Test: Manual push from Jenkins agent

### Job fails to find Jenkinsfile

**Problem:** Script path is wrong
**Solution:**
1. Verify file exists: `ls -la jenkinsfiles/disposition/Jenkinsfile`
2. Verify path in job config: `jenkinsfiles/disposition/Jenkinsfile` (no leading /)
3. Verify branch: `*/master`

### Pipeline hangs on "Verify Git Status"

**Problem:** Git commands timing out
**Solution:**
1. Check network connectivity from Jenkins agent
2. Verify GitHub PAT is valid
3. Check Jenkins logs for timeout details

---

## Job Configuration Checklist

### starforth-disposition
- [ ] Job name: `starforth-disposition`
- [ ] Type: Pipeline
- [ ] SCM: Git
- [ ] Repository: https://github.com/rajames440/StarForth-Governance.git
- [ ] Script path: `jenkinsfiles/disposition/Jenkinsfile`
- [ ] Build triggers: Poll SCM `H/15 * * * *`
- [ ] Credentials: `github-credentials` configured
- [ ] Parameters: DRY_RUN, PROCESS_DOCUMENT configured
- [ ] Test: Build now works without errors

### starforth-signature-verify
- [ ] Job name: `starforth-signature-verify`
- [ ] Type: Pipeline
- [ ] SCM: Git
- [ ] Repository: https://github.com/rajames440/StarForth-Governance.git
- [ ] Script path: `jenkinsfiles/signature-verify/Jenkinsfile`
- [ ] Build triggers: None (manual)
- [ ] Credentials: `github-credentials` configured
- [ ] Parameters: DOCUMENT_PATH, SIGNATURE_FILE, SIGNER_USERNAME, DRY_RUN configured
- [ ] Test: Build with parameters works

### starforth-vault-router
- [ ] Job name: `starforth-vault-router`
- [ ] Type: Pipeline
- [ ] SCM: Git
- [ ] Repository: https://github.com/rajames440/StarForth-Governance.git
- [ ] Script path: `jenkinsfiles/vault-router/Jenkinsfile`
- [ ] Build triggers: None (manual)
- [ ] Credentials: `github-credentials` configured
- [ ] Parameters: DOCUMENT_PATH, DOCUMENT_TYPE, DRY_RUN, FORCE_PM_OVERRIDE configured
- [ ] Test: Build with parameters works

---

## Next Steps

1. ✅ **Create the 3 Jenkins jobs** using instructions above
2. ⏳ **Configure GitHub credentials** (separate process)
3. ⏳ **Test with DRY_RUN=true** first (no commits)
4. ⏳ **Test with DRY_RUN=false** (real commits to test branch)
5. ⏳ **Implement GitHub notifications** (Gate 1)
6. ⏳ **Set up PGP/GPG keys** (Gate 4)

---

**Status:** Ready to configure
**Effort:** ~30 minutes to create all 3 jobs
**Dependencies:** GitHub credentials must be configured first
