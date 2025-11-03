# CAPA Vault Snapshot Workflow Specification

**Document ID:** CAPA-VAULT-SNAPSHOT-WORKFLOW-001
**Status:** SPECIFICATION (Ready for Implementation in StarForth-Governance)
**Audience:** Governance Pipeline Implementers
**Purpose:** Define the GitHub Actions workflow that captures immutable CAPA audit trails

---

## Overview

This workflow runs in the **StarForth-Governance repository** and is triggered by state changes in the StarForth repository. It captures complete immutable snapshots of CAPA issues at every Kanban state transition.

```
StarForth repo (mailslot)
  CAPA moves through states
       ↓ (webhook)
StarForth-Governance repo (mailroom)
  Workflow: capa-vault-snapshot.yml
       ↓
in_basket/CAPAs/CAPA-#XX/
  ├── CAPA-#XX-created.adoc
  ├── CAPA-#XX-implementing.adoc
  ├── ... (one snapshot per state)
  └── MANIFEST.json
```

---

## Workflow Triggers

The workflow must be triggered by:

### 1. Manual Trigger (Testing)
```yaml
on:
  workflow_dispatch:
    inputs:
      issue_number:
        description: "CAPA issue number to snapshot"
        required: true
        type: number
```

### 2. Webhook from StarForth (Kanban State Change)

**Endpoint:** `https://github.com/rajames440/StarForth-Governance/actions/workflows/capa-vault-snapshot.yml/dispatches`

**Triggered by:**
- PR opened with "Closes #XYZ" → IMPLEMENT state
- PR closed/merged → RELEASE/CLOSED state
- Comment with "✅ QA Approved" → APPROVE state
- Comment with "✅ PM Release" → RELEASE state
- Kanban Status field change (via secondary workflow)

### 3. Pull Request Events

```yaml
on:
  pull_request:
    types: [opened, closed]
```

Triggered when StarForth PRs are opened/closed, detect CAPA issue linkage.

### 4. Issue Comment Events

```yaml
on:
  issue_comment:
    types: [created]
```

Triggered when comments contain approval keywords.

---

## Workflow Steps

### Step 1: Checkout Governance Repo
```yaml
- uses: actions/checkout@v3
  with:
    repository: rajames440/StarForth-Governance
    path: governance
    token: ${{ secrets.GOVERNANCE_REPO_TOKEN }}
```

### Step 2: Fetch CAPA Issue from StarForth

**Source:** StarForth repository (cross-repo access)

```bash
# Using GitHub CLI with PAT token
gh issue view <ISSUE_NUM> \
  --repo rajames440/StarForth \
  --json title,body,state,createdAt,closedAt,author,assignees,labels
```

**Data to Capture:**
- Issue number
- Title
- Body (original description)
- GitHub state (OPEN/CLOSED)
- Created timestamp
- Closed timestamp
- Author
- Assignees
- Labels

### Step 3: Fetch All Comments (Complete History)

```bash
gh issue view <ISSUE_NUM> \
  --repo rajames440/StarForth \
  --json comments \
  --jq '.comments[] | "\(.createdAt) | @\(.author.login) | \(.body)"'
```

**Must preserve:**
- Comment text
- Author of each comment
- Timestamp of each comment
- Order (chronological)

### Step 4: Query Kanban Status

**Source:** GitHub Project V2 (rajames440/projects/5)

```graphql
query($owner: String!, $number: Int!, $issueNum: Int!) {
  user(login: $owner) {
    projectV2(number: $number) {
      items(first: 100) {
        nodes {
          id
          content {
            ... on Issue { number }
          }
          fieldValues(first: 50) {
            nodes {
              ... on ProjectV2ItemFieldSingleSelectValue {
                field { name }
                name  # The actual state: CREATE, IMPLEMENT, etc.
              }
            }
          }
        }
      }
    }
  }
}
```

**Extract:** Current Status field value (CREATE, IMPLEMENT, VALIDATE, APPROVE, RELEASE, CLOSED)

### Step 5: Generate AsciiDoc Snapshot

**File location:** `in_basket/CAPAs/CAPA-#<number>/<slug>.adoc`

**Naming convention:**
```
CAPA-#75-created.adoc       (when in CREATE state)
CAPA-#75-implementing.adoc   (when in IMPLEMENT state)
CAPA-#75-validated.adoc      (when in VALIDATE state)
CAPA-#75-approved.adoc       (when in APPROVE state)
CAPA-#75-released.adoc       (when in RELEASE state)
CAPA-#75-closed.adoc         (when in CLOSED state)
```

**Content structure:**

```asciidoc
= CAPA #75: [TITLE]
:docid: CAPA-75
:github-issue: 75
:snapshot-id: CAPA-75-[STATE_SLUG]
:snapshot-date: [ISO8601 timestamp]
:snapshot-version: [sequence number]
:state: [CREATE|IMPLEMENT|VALIDATE|APPROVE|RELEASE|CLOSED]
:author: [original author]

== Snapshot Metadata
* **GitHub Issue:** #75
* **Title:** [title]
* **State at Snapshot:** [current state]
* **Snapshot Created:** [timestamp]
* **Author:** @[author]
* **Assignees:** [comma-separated]
* **Labels:** [comma-separated]

== Original Issue Description
____
[Complete original issue body]
____

== All Comments (Complete History)
=== Comment by @user1 at 2025-11-01T10:05:00Z
____
[Comment text]
____

=== Comment by @user2 at 2025-11-01T14:30:00Z
____
[Comment text]
____

[... repeat for all comments ...]

== End of Snapshot
This snapshot represents CAPA #75 at state [STATE].
Generated: [timestamp]
Vault: in_basket/CAPAs/CAPA-75/CAPA-75-[state_slug].adoc
```

### Step 6: Create MANIFEST.json

**Location:** `in_basket/CAPAs/CAPA-#<number>/MANIFEST.json`

```json
{
  "capa_id": 75,
  "title": "Fix emoji parsing in REPL",
  "author": "alice",
  "created_at": "2025-11-01T10:00:00Z",
  "closed_at": "2025-11-02T21:45:00Z",
  "github_state": "CLOSED",
  "kanban_state": "CLOSED",
  "assignees": ["bob", "carol"],
  "labels": ["CAPA", "bug", "high-priority"],
  "comments_count": 8,
  "snapshots": [
    {
      "state": "CREATE",
      "file": "CAPA-75-created.adoc",
      "timestamp": "2025-11-01T10:00:00Z"
    },
    {
      "state": "IMPLEMENT",
      "file": "CAPA-75-implementing.adoc",
      "timestamp": "2025-11-01T14:30:00Z"
    },
    {
      "state": "VALIDATE",
      "file": "CAPA-75-validated.adoc",
      "timestamp": "2025-11-01T18:00:00Z"
    },
    {
      "state": "APPROVE",
      "file": "CAPA-75-approved.adoc",
      "timestamp": "2025-11-02T10:00:00Z"
    },
    {
      "state": "RELEASE",
      "file": "CAPA-75-released.adoc",
      "timestamp": "2025-11-02T21:30:00Z"
    },
    {
      "state": "CLOSED",
      "file": "CAPA-75-closed.adoc",
      "timestamp": "2025-11-02T21:45:00Z"
    }
  ],
  "related_documents": {
    "ecr": null,
    "eco": null,
    "fmea": null,
    "build_manifest": "BUILD_MANIFEST_v2.0.1.json",
    "release_notes": "v2.0.1_Release_Notes.md"
  },
  "approvals": [
    {
      "role": "Submitter",
      "actor": "alice",
      "timestamp": "2025-11-01T10:00:00Z"
    },
    {
      "role": "QA/QUAL_MGR",
      "actor": "carol",
      "timestamp": "2025-11-02T10:00:00Z",
      "comment": "✅ QA Approved"
    },
    {
      "role": "PM",
      "actor": "pm",
      "timestamp": "2025-11-02T21:30:00Z",
      "comment": "✅ PM Release v2.0.1"
    }
  ],
  "vault_location": "in_basket/CAPAs/CAPA-75/",
  "last_updated": "2025-11-02T21:45:00Z"
}
```

### Step 7: Commit and Push

```bash
git config user.name "Governance Vault System"
git config user.email "governance-vault@starforth"

git add in_basket/CAPAs/CAPA-#<number>/
git commit -m "CAPA #<number>: Snapshot at <STATE> state (<timestamp>)"
git push origin master
```

### Step 8: Post Workflow Summary

Log summary to workflow run:
```
✓ CAPA #75 snapshot captured
  - State: RELEASED
  - Comments: 8
  - Snapshot file: CAPA-75-released.adoc
  - Vault location: in_basket/CAPAs/CAPA-75/
  - Timestamp: 2025-11-02T21:45:00Z
```

---

## Environment Setup

**Required GitHub Secrets:**
```
GOVERNANCE_REPO_TOKEN    # PAT with repo access to both StarForth repos
ENG_MGR_EMAIL            # Engineering Manager email for notifications
QUAL_MGR_EMAIL           # Quality Manager email
PM_EMAIL                 # Product Manager email
```

**Required Tokens:**
- `GITHUB_TOKEN` (automatic, for StarForth-Governance repo)
- `GOVERNANCE_REPO_TOKEN` (PAT for cross-repo access to StarForth)

---

## Execution Timing

| Trigger | Latency | Frequency |
|---------|---------|-----------|
| Manual dispatch | Immediate | On-demand |
| PR opened in StarForth | <1 minute | Per PR |
| PR merged in StarForth | <1 minute | Per merge |
| Comment on issue | <1 minute | Per comment |
| Kanban field change | 1-5 minutes | Per state change |

---

## Error Handling

**If issue not found in StarForth:**
- Log error to workflow
- Notify PM: "Could not find CAPA #XX"
- Mark as FAILED in workflow UI

**If project state not found:**
- Default to "CREATE"
- Log warning
- Proceed with snapshot
- Notify PM for manual review

**If comments exceed limit:**
- Fetch first 100 comments
- Note in MANIFEST.json
- Log warning
- Include note in snapshot

---

## Success Criteria

✅ **Snapshot captured when:**
- File created in `in_basket/CAPAs/CAPA-#XX/`
- AsciiDoc is valid and parseable
- MANIFEST.json is valid JSON
- Commit message includes CAPA number and state
- Workflow logs show completion timestamp

✅ **Data integrity when:**
- Issue body included completely
- All comments preserved in order
- Timestamps are ISO8601 format
- Author information preserved
- No truncation of content

---

## Testing Procedures

### Manual Test with CAPA #75

```bash
# Trigger workflow via GitHub CLI
gh workflow run capa-vault-snapshot.yml \
  --repo rajames440/StarForth-Governance \
  -f issue_number=75

# Wait for completion
gh run list --repo rajames440/StarForth-Governance \
  --workflow capa-vault-snapshot.yml \
  --limit 1

# Verify snapshot created
ls -la in_basket/CAPAs/CAPA-75/
cat in_basket/CAPAs/CAPA-75/MANIFEST.json
```

### Automated Test Matrix

Test with CAPAs in different states:
- CAPA in CREATE state
- CAPA in IMPLEMENT state
- CAPA in CLOSED state (with comments)

Verify:
- Correct state name in snapshot
- All comments included
- MANIFEST.json valid
- File names match state

---

## Related Workflows

This workflow feeds into:

1. **in_basket Processor Pipeline** (Jenkins)
   - Runs daily/on-webhook
   - Processes CAPAs in in_basket
   - Archives CLOSED CAPAs to Reference/Quality/CAPAs/

2. **Governance Notification System**
   - Receives snapshot completion
   - Notifies stakeholders
   - Alerts PM of exceptions

3. **Immutability Verification**
   - Checksums all archived CAPAs
   - Verifies no modifications
   - Generates compliance certificates

---

## Implementation Notes

### Where This Workflow Lives

**Repository:** StarForth-Governance (Governance repo)
**Location:** `.github/workflows/capa-vault-snapshot.yml`

**Trigger Configuration:**
- Can be triggered manually from this repo
- Can be triggered via webhook from StarForth repo
- Can be triggered by scheduled jobs

### Repository Access Required

This workflow needs:
- Write access to StarForth-Governance (to commit snapshots)
- Read access to StarForth (to fetch issues/comments)
- Read access to StarForth Project V2 (to get Kanban states)

---

## Next Steps

1. **Create workflow file:**
   - `.github/workflows/capa-vault-snapshot.yml` in StarForth-Governance
   - Use YAML template from CAPA_VAULT_SNAPSHOT_WORKFLOW.yml

2. **Configure GitHub secrets:**
   - `GOVERNANCE_REPO_TOKEN` (PAT for cross-repo access)
   - Email addresses for stakeholders

3. **Test with manual trigger:**
   - Run on existing CAPA #75
   - Verify snapshot created correctly
   - Review MANIFEST.json

4. **Enable webhook triggers:**
   - Create secondary workflow to detect Kanban state changes
   - Trigger capa-vault-snapshot.yml on state transitions

5. **Connect to Jenkins processor:**
   - Jenkins pipeline monitors in_basket/CAPAs/
   - Processes and archives CLOSED CAPAs
   - Generates compliance certificates

---

## Document History

| Version | Date | Status | Notes |
|---------|------|--------|-------|
| 1.0 | 2025-11-02 | SPECIFICATION | Initial specification for implementation |

---

**Status: READY FOR IMPLEMENTATION**

This specification is ready to be implemented as `.github/workflows/capa-vault-snapshot.yml` in the StarForth-Governance repository.