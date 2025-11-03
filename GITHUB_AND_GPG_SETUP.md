# GitHub PAT & GPG Key Setup Guide

**Date:** 2025-11-03
**Status:** Configuration Instructions (Ready to execute)

Complete setup guide for GitHub Personal Access Token (Gate 3) and GPG/PGP key management (Gate 4).

---

## GATE 3: GitHub PAT Credentials Configuration

### Overview

Jenkins needs GitHub credentials to:
1. Clone the StarForth-Governance repository
2. Create commits (via git push)
3. Create GitHub issues (for signer notifications)
4. Manage pull requests

The credentials must be stored **outside the codebase** as a Jenkins secret.

### Step 1: Create GitHub Personal Access Token (PAT)

**In GitHub:**

1. Login to GitHub as rajames440
2. Navigate to Settings → Developer settings → Personal access tokens → Tokens (classic)
3. Click **Generate new token (classic)**
4. **Token name:** `starforth-jenkins`
5. **Expiration:** 90 days (or custom)
6. **Select scopes:**
   - ✅ **repo** (full control of private repositories)
   - ✅ **workflow** (update GitHub Actions and workflows)
   - ✅ **read:user** (read user profile data)
   - ❌ **admin:repo_hook** (not needed)
   - ❌ **write:packages** (not needed)

**Important:** The minimum required scope is just `repo`, but adding `workflow` allows GitHub Actions integration if needed in the future.

### Step 2: Copy and Secure the PAT

**GitHub:**
1. Copy the generated token (you'll only see it once)
2. Save temporarily in a secure location (e.g., password manager)

**DO NOT:**
- ❌ Commit to git
- ❌ Add to `.env` files
- ❌ Store in shared documents
- ❌ Use in pipeline code

### Step 3: Configure Jenkins Credential

**In Jenkins:**

1. **Navigate to Credentials:**
   - Jenkins Dashboard → Manage Jenkins → Manage Credentials

2. **Select Credential Store:**
   - Click on "global" (under System)

3. **Add New Credential:**
   - Click **Add Credentials** (or + New Credentials)
   - **Kind:** Username with password
   - **ID:** `github-credentials` ← MUST match this exact ID
   - **Username:** `(can be anything)` e.g., `github-bot`
   - **Password:** `(paste your PAT here)`
   - **Scope:** Global
   - Leave Description empty or add: "GitHub API access for StarForth-Governance"

4. **Save:**
   - Click **Create**

**Verification:**
- Jenkins Dashboard → Manage Jenkins → Manage Credentials
- Under "global" store → Should see `github-credentials` listed

### Step 4: Test Credential

**In Jenkins:**

Create a test pipeline to verify credential works:

```groovy
pipeline {
    agent any
    stages {
        stage('Test Git Clone') {
            steps {
                script {
                    checkout([
                        $class: 'GitSCM',
                        branches: [[name: '*/master']],
                        userRemoteConfigs: [[
                            url: 'https://github.com/rajames440/StarForth-Governance.git',
                            credentialsId: 'github-credentials'
                        ]]
                    ])
                    sh 'pwd && ls -la'
                }
            }
        }
        stage('Test Git Push') {
            steps {
                script {
                    sh '''
                        git config user.name "Jenkins Test"
                        git config user.email "jenkins@starforth.governance"

                        # Create test file
                        echo "Test" > test.txt
                        git add test.txt
                        git commit -m "Test commit from Jenkins" || echo "Nothing to commit"

                        # Test push (will fail if read-only)
                        git push origin master || {
                            echo "ℹ️ Push failed - credentials may be read-only or branch protected"
                        }
                    '''
                }
            }
        }
    }
}
```

### Step 5: PAT Rotation

**When to Rotate:**
- Every 90 days (recommended)
- If credential is compromised
- When team member leaves

**How to Rotate:**
1. Create new PAT in GitHub (Step 1-2)
2. Update Jenkins credential (Step 3)
3. Delete old PAT in GitHub settings
4. Test with new PAT (Step 4)

---

## GATE 4: PGP/GPG Key Management

### Overview

Document signatures are created using PGP/GPG cryptographic keys. Jenkins needs:
1. Public keys from all authorized signers
2. GPG installed on Jenkins agents
3. Public keys imported into Jenkins user's keyring

### Part A: Signer Public Key Distribution

#### For Each Signer (rajames440, qa-lead, eng-manager, etc.)

**Step 1: Export Public Key**

On signer's machine:
```bash
# List keys
gpg --list-keys

# Export public key (choose one method)

# Method 1: Armor format (text, can paste)
gpg --export --armor rajames440@starforth.dev > rajames440-public.asc

# Method 2: Binary format (compact)
gpg --export rajames440@starforth.dev > rajames440-public.gpg
```

**Step 2: Share Public Key Securely**

Options:
- ✅ Commit to repo: `Security/keys/[username]-public.asc`
- ✅ Email to PM (rajames440)
- ✅ Share via keyserver: `gpg --keyserver hkps://keys.openpgp.org --send-key [KEY_ID]`
- ❌ Slack/Teams (not secure for keys)

**Step 3: Verify Key Format**

```bash
# Verify exported key
gpg --import --dry-run rajames440-public.asc

# Output should show key ID and owner
```

### Part B: Jenkins Agent Setup

#### Prerequisites

Jenkins agents need GPG installed:

```bash
# Debian/Ubuntu
sudo apt-get update
sudo apt-get install -y gnupg

# CentOS/RHEL
sudo yum install -y gnupg

# macOS
brew install gpg

# Verify
gpg --version
```

#### Import Public Keys into Jenkins

**On Jenkins agent (run as Jenkins user):**

```bash
# Become Jenkins user
sudo su - jenkins

# Create keys directory (if not exists)
mkdir -p ~/.gnupg
chmod 700 ~/.gnupg

# Copy public key files to agent
# (From repository: Security/keys/*.asc)

# Import each signer's public key
gpg --import /path/to/rajames440-public.asc
gpg --import /path/to/qa-lead-public.asc
gpg --import /path/to/eng-manager-public.asc
# ... repeat for each signer

# List imported keys
gpg --list-keys

# Output should show all imported keys:
# pub   rsa4096 2025-11-03 [SC]
#      ABCDEF1234567890ABCDEF1234567890ABCDEF12
# uid           [ unknown] rajames440 <rajames440@starforth.dev>
```

#### Trust Configuration (Optional)

By default, keys show as "unknown" trust. To mark as trusted:

```bash
# List keys
gpg --list-keys

# Edit key
gpg --edit-key [KEY_ID]

# At gpg> prompt:
trust

# Select trust level:
5  # Ultimate (assumes this key cannot be compromised)
   # Use for keys you fully control or trust completely

quit
```

**Note:** For verification purposes, trust level doesn't matter. The script checks `gpg --verify` output, not trust level.

### Part C: Signature File Location

Documents and signatures are stored in repository:

```
Pending/[TYPE]/[DOCUMENT_NAME].adoc              ← Document
Pending/[TYPE]/[DOCUMENT_NAME].[SIGNER].asc      ← Signature
```

Example:
```
Pending/CAPA/CAPA-001.adoc
Pending/CAPA/CAPA-001.rajames440.asc
Pending/CAPA/CAPA-001.qa-lead.asc
```

### Part D: Creating Signatures

**Signer creates signature:**

```bash
cd /path/to/StarForth-Governance/Pending/CAPA/

# Create detached signature
gpg --detach-sign --armor CAPA-001.adoc

# Output: CAPA-001.adoc.asc

# Rename to match expected format
mv CAPA-001.adoc.asc CAPA-001.rajames440.asc

# Commit and push
git add CAPA-001.rajames440.asc
git commit -m "docs(signature): Add signature from rajames440"
git push origin master
```

### Part E: Verification in Pipeline

**Pipeline verification script (bin/verify-signature.sh):**

```bash
# Verify signature
gpg --verify CAPA-001.rajames440.asc CAPA-001.adoc

# Output: Good signature from "rajames440 <rajames440@starforth.dev>"
# If key not in keyring: gpg: Can't check signature: public key not found

# Script handles both cases:
# - VALID: Key imported and signature verified
# - UNVERIFIED: Signature file present but key not imported
# - INVALID: Signature failed verification
```

### Part F: Setup Checklist

- [ ] All signers generated GPG keys (or have existing ones)
- [ ] Public keys exported in armor format (.asc files)
- [ ] Public keys committed to `Security/keys/` directory
- [ ] GPG installed on all Jenkins agents
- [ ] All signer public keys imported into Jenkins user's keyring
- [ ] Verified: `gpg --list-keys` shows all signers
- [ ] Test signature creation by one signer
- [ ] Test signature verification on Jenkins agent

---

## Combining PAT & GPG Setup

### Complete Workflow

1. **Jenkins Agent Preparation:**
   - Install Git and GPG
   - Import signer public keys
   - Configure Jenkins user keyring

2. **Jenkins Credentials:**
   - Configure `github-credentials` with PAT
   - Test with test pipeline

3. **Test End-to-End:**
   ```bash
   # Test document routing
   # Test signature creation
   # Test signature verification
   # Test git operations
   ```

---

## Troubleshooting

### Git Operations Fail

**Problem:** `fatal: Authentication failed` or `Permission denied`

**Solutions:**
1. Verify PAT has `repo` scope
2. Verify Jenkins credential ID is `github-credentials`
3. Test PAT manually: `git clone https://[PAT]@github.com/rajames440/StarForth-Governance.git`
4. Check Jenkins logs: Jenkins Dashboard → Manage Jenkins → System Log

### GitHub Issue Creation Fails

**Problem:** `gh issue create` command not found

**Solutions:**
1. Install GitHub CLI: `sudo apt-get install gh`
2. Authenticate: `gh auth login` (use PAT)
3. Verify: `gh issue list`

### GPG Verification Fails

**Problem:** `gpg: Can't check signature: public key not found`

**Solutions:**
1. Verify public key is imported: `gpg --list-keys [signer]`
2. Import missing key: `gpg --import [public-key-file]`
3. Verify signature file exists: `ls -la [document].*.asc`
4. Verify signature file format: `file [document].*.asc` should show "armor"

### Signature Verification Shows "Bad Signature"

**Problem:** `gpg: Good signature` does NOT appear

**Solutions:**
1. Verify document wasn't modified after signing
2. Verify signature file matches document: `gpg --verify [sig] [doc]`
3. Verify signer's key hasn't expired: `gpg --list-keys [signer]`
4. Re-sign document: Have signer create new signature

---

## Security Best Practices

### For GitHub PAT

- ✅ Store in Jenkins secrets only (not in code)
- ✅ Use appropriate scopes (minimum: `repo`)
- ✅ Rotate every 90 days
- ✅ Revoke old tokens after rotation
- ✅ Don't share PAT with others
- ❌ Don't commit PAT to git
- ❌ Don't hardcode in scripts

### For GPG Keys

- ✅ Keep private keys offline (on signer's machine)
- ✅ Back up private keys securely
- ✅ Use strong passphrases
- ✅ Only import public keys to Jenkins
- ✅ Verify key fingerprints before importing
- ❌ Don't share private keys
- ❌ Don't export private keys unnecessarily

---

## Configuration Checklist

### GATE 3: GitHub PAT
- [ ] GitHub PAT created with `repo` and `workflow` scopes
- [ ] PAT securely stored (password manager or Jenkins secrets)
- [ ] Jenkins credential created: ID = `github-credentials`
- [ ] Test pipeline clones repo successfully
- [ ] Test pipeline can create commits

### GATE 4: GPG/PGP
- [ ] All signers' public keys exported as `.asc` files
- [ ] Public keys committed to `Security/keys/` directory
- [ ] GPG installed on Jenkins agents
- [ ] All signer public keys imported into Jenkins keyring
- [ ] `gpg --list-keys` shows all signers
- [ ] Test signature verification works
- [ ] Test signature update in document works

---

## What's Next

Once Gates 3 & 4 configured:
1. Configure Jenkins jobs (from JENKINS_JOB_SETUP.md)
2. Test with TEST-CAPA-001.adoc
3. Implement webhook file watcher
4. Create operator documentation

---

**Status:** Ready to configure
**Effort:** ~1-2 hours per gate (total 2-4 hours)
**Dependencies:** None
