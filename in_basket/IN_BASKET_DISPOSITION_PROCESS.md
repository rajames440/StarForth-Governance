# In_Basket Disposition Process - Step-by-Step

## Overview

Documents routed from StarForth arrive in in_basket and flow through this process:

```
Incoming Document
    ↓
Step 1: Add & Commit (keep in in_basket)
    ↓
Step 2: Identify type (Reference vs Controlled)
    ├─ Reference? → Step 2A (sort to Reference, remove from in_basket)
    └─ Controlled? → Step 3 (sort to proper location, create dir if needed)
    ↓
Step 3: Route Controlled Docs (create location if needed)
    ↓
Step 4: Send E-Sign Notifications (if controlled doc)
    ↓
Complete (committed to git, stakeholders notified)
```

---

## Step 1: Incoming File Lands in in_basket

**Action:** Add document and metadata to in_basket, commit

**What happens:**
- Document file arrives from StarForth (route-to-vault.yml)
- metadata.json created with:
  - document_type
  - github_issue
  - github_title
  - created_at, routed_at timestamps
  - status: in-basket-pending-processing

**Jenkins action:**
```bash
git add in_basket/[DOCUMENT]/
git commit -m "in-basket: Incoming document [TYPE]-[ID] from StarForth

Document type: [TYPE]
GitHub issue: #[ISSUE]
Title: [TITLE]
Status: Landed in in_basket, pending disposition"
```

**Result:** Document is preserved in git history, in_basket keeps all incoming documents

---

## Step 2: Sort Obvious Reference Documents

**Action:** Identify and move clearly-reference-only documents

**What qualifies as "Reference":**
- Architecture/design specs (ARCHITECTURE.adoc, ABI.adoc, etc.)
- Training materials (FOUNDATION-OVERVIEW.md, etc.)
- Verification reports (VERIFICATION_REPORT.adoc)
- Implementation guides (if not governance-specific)
- Formal proofs and mathematical specifications
- Technical guides (BLOCK_STORAGE_GUIDE.adoc, WORD_DEVELOPMENT.adoc)

**What stays in in_basket (NOT Reference):**
- Security event logs (SEC_LOG.adoc)
- Intake procedures
- Session handoff notes
- Gap analysis
- Break/test reports
- Governance declarations and manifests
- Audit manifests (controlled document)

**Jenkins action:**
```bash
# For each obvious Reference document:
mv in_basket/DOCUMENT.adoc Reference/Foundation/
git add Reference/Foundation/DOCUMENT.adoc
git rm in_basket/DOCUMENT.adoc  # or git add -u

git commit -m "vault: Move Reference document to permanent vault

Document: DOCUMENT.adoc
Category: Reference/Foundation
Status: Sorted from in_basket to vault
Reason: Obvious reference material, not controlled"
```

**Result:** Document removed from in_basket, in Reference/Foundation, git shows move operation

---

## Step 3: Route Controlled Documents to Proper Location

**Action:** Move governance-controlled documents to their domain

**What qualifies as "Controlled":**
- CAPA (Corrective Action) → in_basket/CAPAs/ OR Reference/Quality/CAPAs/
- ECR/ECO (Engineering Change) → in_basket/Changes/ OR Reference/Processes/Changes/
- DHR (Design History Report) → Reference/Quality/DHR/
- FMEA (Failure Mode) → Reference/Quality/FMEA/
- Security Events/IR → in_basket/SecurityEvents/ OR Reference/Security/
- Audit Reports → in_basket/AuditReports/ OR Reference/Processes/Audit/

**If location doesn't exist, create it with intelligent naming:**
- Use document_type from metadata
- Follow convention: `in_basket/[PLURAL_TYPE]/` or `Reference/[Category]/[PLURAL_TYPE]/`
- Examples:
  - CAPA → `in_basket/CAPAs/` or `Reference/Quality/CAPAs/`
  - ECR → `in_basket/Changes/` or `Reference/Processes/Changes/`
  - SecurityEvent → `in_basket/SecurityEvents/` or `Reference/Security/SecurityEvents/`

**Jenkins action:**
```bash
# Determine document type and proper location
DOCTYPE=$(jq .document_type metadata.json)
LOCATION=$(map_document_type_to_location $DOCTYPE)

# Create location if needed
mkdir -p $LOCATION

# If location in in_basket, keep document there for processing
if [[ $LOCATION == in_basket/* ]]; then
    mkdir -p "$LOCATION"
    mv in_basket/[DOCUMENT] "$LOCATION/"
    git add "$LOCATION/"
    git rm -r in_basket/[DOCUMENT]/

    git commit -m "in-basket: Route controlled document to domain location

Document: [TYPE]-[ID]
Location: $LOCATION
Status: Awaiting review/signature
Reason: Controlled governance artifact"

# If location in Reference, move there and mark as archived
else
    # Create compliance certificate
    # Create immutability manifest
    git add Reference/
    git rm -r in_basket/[DOCUMENT]/

    git commit -m "vault: Archive controlled document to Reference vault

Document: [TYPE]-[ID]
Location: $LOCATION
Status: Immutable archive
Reason: Controlled document, moved to permanent vault"
fi
```

**Result:** Document in proper location (in_basket for processing, Reference for archive), tracked in git

---

## Step 4: Send E-Sign Notifications

**Action:** For controlled documents, notify signatories

**What needs signing:**
- All controlled documents (CAPA, ECR, ECO, FMEA, DHR, etc.)
- Use metadata from document or configuration

**Process:**
1. Read document_type from metadata.json
2. Look up signatories from config (SIGNATORIES.json)
3. For each signatory:
   - Get PGP public key
   - Get PGP fingerprint
   - Compose notification email
   - Send with:
     - Document link (GitHub or vault location)
     - PGP public key (for signing software)
     - Fingerprint (for verification)
     - Signing deadline
     - Instructions

**Email template:**
```
Subject: E-Signature Required: [DOCUMENT_TYPE]-[ID] - [TITLE]

Please review and e-sign the attached document.

Document Details:
  Type: [DOCUMENT_TYPE]
  ID: [ID]
  Title: [TITLE]
  Location: [GITHUB_ISSUE or VAULT_PATH]
  Deadline: [DATE]

PGP Signing Information:
  Your Public Key: [KEY_ID/FINGERPRINT]
  Fingerprint: [FULL_FINGERPRINT]

To Sign:
  1. Download the document
  2. Create signature using: gpg --detach-sign --armor [FILE]
  3. Submit signature via [PROCESS]

Questions? Contact [PM_EMAIL]
```

**Jenkins action:**
```bash
# Read document type
DOCTYPE=$(jq .document_type metadata.json)

# Look up signatories
SIGNATORIES=$(jq ".documents[\"$DOCTYPE\"].signatories" SIGNATORIES.json)

# For each signatory
for signatory in $(echo $SIGNATORIES | jq -r '.[]'); do
    PGP_KEY=$(jq ".signatories[\"$signatory\"].pgp_key" SIGNATORIES.json)
    PGP_FINGERPRINT=$(jq ".signatories[\"$signatory\"].pgp_fingerprint" SIGNATORIES.json)
    EMAIL=$(jq ".signatories[\"$signatory\"].email" SIGNATORIES.json)

    # Send notification email with PGP key & fingerprint
    send_notification_email \
        --to "$EMAIL" \
        --document-id "[TYPE]-[ID]" \
        --document-title "[TITLE]" \
        --pgp-key "$PGP_KEY" \
        --pgp-fingerprint "$PGP_FINGERPRINT" \
        --location "$LOCATION"

    # Log to SEC_LOG
    echo "| $(date -u +%Y-%m-%dT%H:%M:%SZ) | E-Sign Notification | in-basket-watcher | [TYPE]-[ID] | Sent to $signatory | LOW |" >> SEC_LOG.adoc
fi
```

**Result:** Signatories notified with document details and PGP information, logged in SEC_LOG

---

## Summary: What Gets Committed

### Step 1 Commit
```
in-basket: Incoming document [TYPE]-[ID] from StarForth
```
- Adds document to in_basket
- Preserves in git

### Step 2 Commit
```
vault: Move Reference document to permanent vault
```
- Shows document moving from in_basket → Reference
- Git tracks it as a move/rename

### Step 3 Commit
```
in-basket: Route controlled document to domain location
OR
vault: Archive controlled document to Reference vault
```
- Shows document moving from in_basket → proper location
- Git tracks the move

### Step 4 (No commit)
- Notification sent, logged in SEC_LOG
- Signatories have PGP information to complete signing process

---

## Configuration Files Needed

### SIGNATORIES.json
Maps document types to required signers and their PGP info:

```json
{
  "documents": {
    "CAPA": {
      "signatories": ["PM", "QA_Lead", "Engineering_Manager"],
      "deadline_days": 5
    },
    "ECR": {
      "signatories": ["PM", "Engineering_Manager"],
      "deadline_days": 3
    },
    "FMEA": {
      "signatories": ["PM", "QA_Lead"],
      "deadline_days": 7
    }
  },
  "signatories": {
    "PM": {
      "email": "pm@starforth.local",
      "pgp_key": "0x12345678",
      "pgp_fingerprint": "1234 5678 9ABC DEF0 1234 5678 9ABC DEF0 1234 5678"
    },
    "QA_Lead": {
      "email": "qa-lead@starforth.local",
      "pgp_key": "0x87654321",
      "pgp_fingerprint": "8765 4321 CDEF 89AB 8765 4321 CDEF 89AB 8765 4321"
    },
    "Engineering_Manager": {
      "email": "eng-manager@starforth.local",
      "pgp_key": "0xABCDEF00",
      "pgp_fingerprint": "ABCD EF00 1234 5678 ABCD EF00 1234 5678 ABCD EF00"
    }
  }
}
```

### VAULT_LOCATIONS.json
Maps document types to vault locations:

```json
{
  "document_types": {
    "CAPA": {
      "location": "in_basket/CAPAs/",
      "archive_location": "Reference/Quality/CAPAs/",
      "requires_signature": true,
      "category": "Quality"
    },
    "ECR": {
      "location": "in_basket/Changes/",
      "archive_location": "Reference/Processes/Changes/",
      "requires_signature": true,
      "category": "Process"
    },
    "ARCHITECTURE": {
      "location": "Reference/Foundation/",
      "archive_location": null,
      "requires_signature": false,
      "category": "Reference"
    }
  }
}
```

---

## Status

These are the **defined steps**. Ready to:
1. Create SIGNATORIES.json with actual stakeholders?
2. Create VAULT_LOCATIONS.json with proper mappings?
3. Build Jenkins pipeline that implements these steps?
4. Test with sample documents?
