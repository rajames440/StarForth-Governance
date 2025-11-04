# CAPA Vault Integration - Implementation Guide

**Status:** Ready for Implementation in StarForth-Governance

**Files in This Directory:**
1. `CAPA_VAULT_SNAPSHOT_WORKFLOW_SPEC.md` - Detailed specification
2. `capa-vault-snapshot.yml` - GitHub Actions workflow (YAML)
3. `Jenkinsfile.capa-vault-processor` - Jenkins pipeline processor
4. `IMPLEMENTATION_GUIDE.md` - This file

---

## What This System Does

Creates an **immutable audit trail** for all CAPAs:

```
CAPA #75 in StarForth
  ├─ State: CREATE
  └─ Snapshot → in_basket/CAPAs/CAPA-75/CAPA-75-created.adoc

CAPA #75 moves to IMPLEMENT
  └─ Snapshot → in_basket/CAPAs/CAPA-75/CAPA-75-implementing.adoc

CAPA #75 moves to VALIDATE
  └─ Snapshot → in_basket/CAPAs/CAPA-75/CAPA-75-validated.adoc

[... continues for each state ...]

CAPA #75 moves to CLOSED
  └─ Snapshot → in_basket/CAPAs/CAPA-75/CAPA-75-closed.adoc
       ↓ (Jenkins processes daily)
  Archive → Reference/Quality/CAPAs/CAPA-75/
  + Compliance Certificate
  + Immutability Verification
```

---

## Implementation Steps

### Step 1: Copy Workflow to StarForth-Governance

In the **StarForth-Governance** repository:

```bash
# Create workflow directory
mkdir -p .github/workflows

# Copy the snapshot workflow
cp in_basket/capa-vault-snapshot.yml .github/workflows/capa-vault-snapshot.yml

# Commit
git add .github/workflows/capa-vault-snapshot.yml
git commit -m "Add: CAPA vault snapshot workflow"
git push origin master
```

### Step 2: Set GitHub Secrets

In StarForth-Governance repository settings, add:

**Secrets:**
```
GOVERNANCE_REPO_TOKEN       # PAT with repo access
  - Required for: Cross-repo access to StarForth
  - Value: GitHub Personal Access Token with:
    - repo:status
    - public_repo
    - read:user
    - user:email

PM_EMAIL                    # Product Manager email
  - For notifications
  - Example: pm@starforth.local

ENG_MGR_EMAIL               # Engineering Manager email
  - For notifications
  - Example: eng-mgr@starforth.local
```

**Create PAT:**
1. GitHub Settings → Developer settings → Personal access tokens
2. New token → select `repo` scope
3. Copy token to `GOVERNANCE_REPO_TOKEN` secret

### Step 3: Create Jenkins Job

In **StarForth-Governance Jenkins**:

**Create new Pipeline job:**
```
Job Name: CAPA-Vault-Processor
Type: Pipeline
```

**Pipeline Configuration:**
```
Definition: Pipeline script from SCM
SCM: Git
  Repository: https://github.com/rajames440/StarForth-Governance.git
  Credentials: Jenkins GitHub credentials
  Script Path: in_basket/Jenkinsfile.capa-vault-processor
```

**Triggers:**
- Build periodically: `H 3 * * *` (3 AM UTC daily)
- Allow manual trigger

**Parameters:**
- Boolean: `DRY_RUN` (default: false)

### Step 4: Configure Jenkins Credentials

```
Jenkins → Manage Jenkins → Manage Credentials

Add GitHub credentials:
  ID: github-credentials
  Username: (GitHub username)
  Password: (GitHub PAT with repo access)
```

### Step 5: Test the Workflow

**Manual test from GitHub:**

```bash
# Trigger snapshot workflow for CAPA #75
gh workflow run capa-vault-snapshot.yml \
  --repo rajames440/StarForth-Governance \
  -f issue_number=75

# Monitor
gh run list --repo rajames440/StarForth-Governance \
  --workflow capa-vault-snapshot.yml \
  --limit 5

# View details
gh run view <RUN_ID> --log
```

**Expected output:**
```
✓ Checkout complete
✓ Fetching CAPA #75 from StarForth
✓ Fetching all comments
✓ Querying Kanban status
✓ Building AsciiDoc snapshot
✓ Creating MANIFEST.json
✓ Pushing to vault
✅ CAPA #75 snapshot captured
```

**Verify snapshot created:**

```bash
cd StarForth-Governance/in_basket
ls -la CAPAs/CAPA-75/
cat CAPAs/CAPA-75/MANIFEST.json
head -50 CAPAs/CAPA-75/CAPA-75-*.adoc
```

### Step 6: Enable Automatic Triggers

Create a secondary workflow in **StarForth** repository to trigger snapshots:

**File:** `.github/workflows/capa-snapshot-trigger.yml`

```yaml
name: Trigger CAPA Snapshot

on:
  pull_request:
    types: [opened, closed]
  issue_comment:
    types: [created]

jobs:
  trigger:
    runs-on: ubuntu-latest
    steps:
      - name: Detect CAPA state change
        run: |
          # If PR has "Closes #75" → trigger snapshot for #75
          # If comment has "✅ QA Approved" → trigger snapshot
          # etc.

      - name: Trigger governance snapshot
        if: env.ISSUE_NUM != ''
        uses: actions/github-script@v7
        with:
          github-token: ${{ secrets.GOVERNANCE_REPO_TOKEN }}
          script: |
            await github.rest.actions.createWorkflowDispatch({
              owner: 'rajames440',
              repo: 'StarForth-Governance',
              workflow_id: 'capa-vault-snapshot.yml',
              ref: 'master',
              inputs: {
                issue_number: process.env.ISSUE_NUM
              }
            })
```

---

## File Descriptions

### CAPA_VAULT_SNAPSHOT_WORKFLOW_SPEC.md

**Type:** Specification Document
**Purpose:** Details what the workflow does, how it works, what data it captures
**Audience:** Developers implementing the workflow
**Use:** Reference while implementing, include in documentation

### capa-vault-snapshot.yml

**Type:** GitHub Actions Workflow
**Purpose:** Captures immutable snapshots of CAPA issues
**Where:** Copy to `.github/workflows/capa-vault-snapshot.yml` in StarForth-Governance
**Triggers:**
- Manual dispatch (testing)
- Pull request events
- Issue comment events
- Repository dispatch (from StarForth triggers)

**What it does:**
1. Fetches CAPA issue details from StarForth
2. Gets all comments (complete history)
3. Queries current Kanban status
4. Generates AsciiDoc snapshot
5. Creates/updates MANIFEST.json
6. Commits to in_basket/CAPAs/

### Jenkinsfile.capa-vault-processor

**Type:** Jenkins Pipeline
**Purpose:** Processes completed CAPA snapshots, archives them, generates compliance certs
**Where:** Copy to root of StarForth-Governance repo, reference in Jenkins job
**When:** Daily at 3 AM UTC (or manual trigger)

**What it does:**
1. Scans in_basket/CAPAs/ for MANIFEST.json files
2. For CLOSED CAPAs: archives to Reference/Quality/CAPAs/
3. Generates COMPLIANCE_CERT.adoc for each archive
4. Creates immutability manifest with SHA256 checksums
5. Verifies checksums
6. Commits and pushes to repository
7. Notifies PM of exceptions

---

## Testing Checklist

### Phase 1: Workflow Setup

- [ ] Copied `capa-vault-snapshot.yml` to `.github/workflows/`
- [ ] Created `GOVERNANCE_REPO_TOKEN` secret
- [ ] Can manually trigger workflow via GitHub UI
- [ ] Workflow completes without errors

### Phase 2: Snapshot Capture

- [ ] Manual trigger captures CAPA #75 snapshot
- [ ] File created: `in_basket/CAPAs/CAPA-75/CAPA-75-create.adoc`
- [ ] MANIFEST.json created with correct data
- [ ] AsciiDoc is valid and parseable
- [ ] All comments included in snapshot

### Phase 3: Jenkins Integration

- [ ] Created Jenkins job `CAPA-Vault-Processor`
- [ ] Job can be manually triggered
- [ ] Job scans in_basket/ successfully
- [ ] CLOSED CAPAs archived to Reference/Quality/
- [ ] Compliance certificates generated
- [ ] Immutability manifest created

### Phase 4: Automatic Triggers

- [ ] Snapshot workflow triggered on PR opened
- [ ] Snapshot workflow triggered on comment with approval keyword
- [ ] Snapshot captures state changes correctly
- [ ] Jenkins daily cron job runs at 3 AM UTC

---

## Troubleshooting

### Issue: Workflow fails with "No issue found"

**Cause:** Missing cross-repo access token

**Solution:**
```
1. Check GOVERNANCE_REPO_TOKEN secret is set
2. Verify token has "repo" scope
3. Test token: gh auth status
```

### Issue: Snapshot file not created

**Cause:** AsciiDoc generation failed

**Solution:**
```
1. Check workflow logs for errors
2. Verify comment history is valid
3. Test asciidoctor locally: asciidoctor test.adoc
```

### Issue: Jenkins job can't commit

**Cause:** Git credentials not configured

**Solution:**
```
Jenkins → Manage Jenkins → Manage Credentials
Add GitHub credentials with repo access
```

### Issue: Comments not included in snapshot

**Cause:** Comment fetch limit exceeded

**Solution:**
```
The workflow fetches first 100 comments.
For issues with >100 comments, all are still included
but may need pagination enhancement.
```

---

## Success Indicators

✅ **When implementation is complete:**

1. **Snapshot Capture:**
   - Manual trigger works
   - `in_basket/CAPAs/CAPA-#XX/` directory created
   - AsciiDoc snapshot generated
   - MANIFEST.json present

2. **Jenkins Processing:**
   - Daily cron job runs
   - CLOSED CAPAs moved to `Reference/Quality/CAPAs/`
   - Compliance certificates generated
   - Immutability verified

3. **Automation:**
   - Snapshots auto-triggered on state changes
   - All stakeholders notified
   - PM only alerted for exceptions

---

## Production Readiness Checklist

Before going live:

- [ ] All tests passing
- [ ] Jenkins daily job runs successfully
- [ ] GitHub secrets configured
- [ ] Notification system tested
- [ ] Backup of in_basket exists
- [ ] Documentation complete
- [ ] Team trained on system
- [ ] PM approval obtained

---

## Maintenance

### Monthly Tasks

1. Verify immutability manifest:
   ```bash
   cd Reference/Quality/CAPAs
   sha256sum -c .immutability_manifest
   ```

2. Review archived CAPAs:
   ```bash
   ls -la Reference/Quality/CAPAs/
   ```

3. Check Jenkins job logs:
   - No errors
   - All CAPAs processed
   - No exceptions

### Quarterly Tasks

1. Archive old in_basket CAPAs (>6 months)
2. Verify compliance certificates present
3. Test recovery/restoration procedures

---

## Support & Questions

- **Workflow spec:** See `CAPA_VAULT_SNAPSHOT_WORKFLOW_SPEC.md`
- **Jenkins pipeline:** See `Jenkinsfile.capa-vault-processor` comments
- **Issues:** Check GitHub Actions logs and Jenkins console output
- **Contact:** StarForth governance team

---

## Summary

```
Step 1: Copy workflow to .github/workflows/
Step 2: Set GitHub secrets
Step 3: Create Jenkins job
Step 4: Configure Jenkins credentials
Step 5: Test manually
Step 6: Enable automatic triggers
Step 7: Monitor first few days
Step 8: Go live

Timeline: 2-4 hours for setup and testing
Effort: ~20-30 minutes per phase
Result: Complete immutable CAPA audit trail
```

**Status: Ready to Implement** ✅
== Signatures

|===
| Signer | Status | Date | Signature

| rajames440 | Pending |  |
|===
