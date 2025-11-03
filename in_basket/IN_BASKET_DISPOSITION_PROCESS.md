# In_Basket Disposition Process - Step-by-Step

## Overview

Documents routed from StarForth arrive in in_basket with metadata.json (created by route-to-vault.yml workflow).
The disposition pipeline processes them in 4 steps:

```
Incoming Document (from route-to-vault.yml)
    ├─ Has metadata.json with document_type
    └─ GitHub labels already applied (type:capa, type:cer, etc.)
    ↓
Step 1: Document lands in in_basket (already committed by route-to-vault.yml)
    ↓
Step 2: Scan with Claude intelligence
    ├─ Read metadata.json to get document_type
    ├─ Convert document to AsciiDoc (if not already)
    ├─ Add signature block template (if controlled document)
    └─ Move to appropriate location (Reference or Controlled)
    ↓
Step 3: Route based on document type
    ├─ Reference types → Reference/[Category]/[Type]/
    ├─ Controlled types → in_basket/[Type]/ (or create location)
    └─ Commit all moves
    ↓
Step 4: Send notifications
    ├─ Email notification (from GitHub account)
    ├─ GitHub issue comment
    ├─ Include action item (e.g., "Needs your signature")
    └─ Log to SEC_LOG.adoc
    ↓
Step 5: Track signatures against Security/Signatures.adoc
    ├─ When you sign doc, add entry to Signatures.adoc
    ├─ Pipeline verifies signature in place
    └─ If verified, move to Reference vault (immutable archive)
```

---

## Step 1: Incoming File Lands in in_basket

**What happens (already done by route-to-vault.yml workflow):**
- Document file arrives from StarForth
- metadata.json created in in_basket/ with:
  - document_type (detected from GitHub labels)
  - github_issue (issue number)
  - github_title
  - created_at, routed_at (timestamps)
  - status: in-basket-pending-processing

**Already committed by route-to-vault.yml**

**Result:** Document is in git history, in_basket has all incoming documents

---

## Step 2: Scan with Claude Intelligence & Convert Format

**Action:** Process document through pipeline

**What happens:**
1. Read metadata.json to get document_type
2. Determine if Reference or Controlled document:
   - Reference types: DHR, DMR, ART, MIN, REL, RMP (auto-vault)
   - Controlled types: CAPA, CER, ECR, ECO, FMEA, DWG, ENG, SEC, IR, VAL, DTA
3. If not AsciiDoc, convert to AsciiDoc
4. If Controlled, add signature block template at end
5. Move to appropriate location

**Signature Block Template (for Controlled Documents):**
```asciidoc
== Signatures

|===
| Signatory | Role | Date | Signature Status

| rajames440 | Owner | | Pending
|===
```

**Jenkins action:**
```bash
# Read document type from metadata
DOCTYPE=$(jq -r '.document_type' in_basket/metadata.json)

# Convert to AsciiDoc if needed (Claude handles this)
if [[ ! "$FILE" == *.adoc ]]; then
    # Convert markdown/docx/pdf to AsciiDoc
    claude_convert_to_asciidoc "$FILE" > "${FILE%.ext}.adoc"
fi

# Add signature block if controlled
if [[ "$DOCTYPE" != @(DHR|DMR|ART|MIN|REL|RMP) ]]; then
    append_signature_block_template "$FILE"
fi
```

**Result:** Document in AsciiDoc format, signature block added if needed

---

## Step 3: Route Based on Document Type

**Action:** Move document to appropriate location based on its type

**Document Type → Location Mapping:**

| Type | Category | Location | Purpose |
|------|----------|----------|---------|
| DHR, DMR, ART, MIN, REL, RMP | Reference | Reference/Quality/[TYPE]/ | Auto-vault (read-only archive) |
| CAPA | Process | in_basket/CAPAs/ | Awaiting your signature |
| CER, CER-Protocol, CER-Results | Process | in_basket/CERs/ | Awaiting your signature |
| ECR, ECO | Process | in_basket/Changes/ | Awaiting your signature |
| FMEA | Quality | in_basket/FMEAs/ | Awaiting your signature |
| DWG, ENG | Design | in_basket/Design/ | Awaiting your signature |
| SEC, IR | Security | in_basket/Security/ | Awaiting your signature |
| VAL, DTA | Verification | in_basket/Verification/ | Awaiting your signature |

**Jenkins action:**
```bash
# Read document type and GitHub issue
DOCTYPE=$(jq -r '.document_type' metadata.json)
ISSUE=$(jq -r '.github_issue' metadata.json)

# Determine target location (create if needed)
case "$DOCTYPE" in
    DHR|DMR|ART|MIN|REL|RMP)
        TARGET="Reference/Quality/${DOCTYPE}s/"  # Auto-vault
        ;;
    CAPA)
        TARGET="in_basket/CAPAs/"
        ;;
    CER*)
        TARGET="in_basket/CERs/"
        ;;
    ECR|ECO)
        TARGET="in_basket/Changes/"
        ;;
    FMEA)
        TARGET="in_basket/FMEAs/"
        ;;
    DWG|ENG)
        TARGET="in_basket/Design/"
        ;;
    SEC|IR)
        TARGET="in_basket/Security/"
        ;;
    VAL|DTA)
        TARGET="in_basket/Verification/"
        ;;
    *)
        TARGET="in_basket/Uncategorized/"
        ;;
esac

# Create location if needed
mkdir -p "$TARGET"

# Move document
mv in_basket/${DOCTYPE}-${ISSUE}/ "$TARGET/"

# Commit the move
git add "$TARGET/"
git rm -r in_basket/${DOCTYPE}-${ISSUE}/ 2>/dev/null || true

git commit -m "disposition: Route ${DOCTYPE}-${ISSUE} to ${TARGET}

Document: ${DOCTYPE} #${ISSUE}
Type: $(if [[ "$TARGET" == Reference* ]]; then echo "Reference (auto-vault)"; else echo "Controlled (awaiting action)"; fi)
Status: Ready for processing"
```

**Result:** Document in proper location, tracked in git

---

## Step 4: Send Notifications to You

**Action:** For controlled documents, send email + GitHub comment with action items

**Process:**
1. Determine if Reference (auto-vault) or Controlled (needs signature)
2. If Reference: Log to SEC_LOG, done
3. If Controlled: Send notification with action item

**Email Notification (from GitHub account):**
```
Subject: Action Required: [DOCTYPE]-[ISSUE] - [TITLE]

A governance document is ready for your review and signature.

Document Details:
  Type: [DOCTYPE]
  GitHub Issue: #[ISSUE]
  Title: [TITLE]
  Location: StarForth-Governance/in_basket/[LOCATION]/

Action Required:
  1. Review document at: [GITHUB_ISSUE_LINK]
  2. Sign: PGP key fingerprint [YOUR_FINGERPRINT]
  3. Add entry to: Security/Signatures.adoc

Signature Format:
  | [DOCTYPE]-[ISSUE] | YYYY-MM-DD | [Signature] |

Questions? Check the GitHub issue for details.
```

**GitHub Comment (on original issue):**
```
✅ Document Routed for Processing

Your **[DOCTYPE]** document has been routed to the governance vault.

**Location:** StarForth-Governance/in_basket/[LOCATION]/

**Next Step:** Review and sign when ready. Update `Security/Signatures.adoc` with signature.

Status: Awaiting your signature for archival.
```

**Jenkins action:**
```bash
# Determine if Reference or Controlled
DOCTYPE=$(jq -r '.document_type' metadata.json)
ISSUE=$(jq -r '.github_issue' metadata.json)
TITLE=$(jq -r '.github_title' metadata.json)

if [[ "$DOCTYPE" == @(DHR|DMR|ART|MIN|REL|RMP) ]]; then
    # Reference type - auto-vault, just log
    echo "| $(date -u +%Y-%m-%dT%H:%M:%SZ) | Auto-Vault | disposition | ${DOCTYPE}-${ISSUE} | Reference doc archived | LOW |" >> SEC_LOG.adoc
else
    # Controlled type - send notification

    # Send email (from GitHub account)
    send_email \
        --subject "Action Required: ${DOCTYPE}-${ISSUE} - ${TITLE}" \
        --to "your.github.email@example.com" \
        --body "$(cat <<EOF
A governance document is ready for your review and signature.

Document: ${DOCTYPE}-${ISSUE}
Title: ${TITLE}
Location: StarForth-Governance/in_basket/[LOCATION]/

Action: Review and sign, then add to Security/Signatures.adoc
EOF
)"

    # Post GitHub comment on original issue
    gh issue comment ${ISSUE} --body "$(cat <<EOF
✅ Document Routed for Processing

Your **${DOCTYPE}** document has been routed to the governance vault.

**Location:** StarForth-Governance/in_basket/[LOCATION]/

**Next Step:** Review and sign when ready. Update \`Security/Signatures.adoc\` with signature.

Status: Awaiting your signature for archival.
EOF
)"

    # Log to SEC_LOG
    echo "| $(date -u +%Y-%m-%dT%H:%M:%SZ) | Signature Notification | disposition | ${DOCTYPE}-${ISSUE} | Awaiting signature from rajames440 | LOW |" >> SEC_LOG.adoc
fi
```

**Result:** You notified (email + GitHub comment), awaiting your action, logged in SEC_LOG

---

## Step 5: Track Signatures in Security/Signatures.adoc

**Action:** After you sign a document, update Security/Signatures.adoc

**What happens:**
1. You review controlled document in in_basket/[TYPE]/
2. You sign it (PGP signature)
3. You add entry to Security/Signatures.adoc
4. Jenkins verifies signature is in place
5. If verified, Jenkins moves document to Reference vault (immutable archive)

**Signatures.adoc format:**
```asciidoc
== Document Signatures

Immutable record of all signed governance documents.

|===
| Document | Signer | Date | Signature Status | Reference Location

| CAPA-0042 | rajames440 | 2025-11-05 | ✓ SIGNED | Reference/Quality/CAPAs/CAPA-0042/
| ECR-0015 | rajames440 | 2025-11-06 | ✓ SIGNED | Reference/Processes/Changes/ECR-0015/
| FMEA-0008 | rajames440 | 2025-11-07 | ✓ SIGNED | Reference/Quality/FMEAs/FMEA-0008/
|===
```

**Jenkins action (signature verification):**
```bash
# After you update Signatures.adoc, Jenkins runs:

# Check if document signature is listed
SIGNED=$(grep -c "${DOCTYPE}-${ISSUE}" Security/Signatures.adoc || echo 0)

if [[ $SIGNED -gt 0 ]]; then
    # Signature found - move to immutable archive
    mkdir -p "Reference/[Category]/${DOCTYPE}s/${DOCTYPE}-${ISSUE}/"
    mv "in_basket/${LOCATION}/${DOCTYPE}-${ISSUE}/"* "Reference/[Category]/${DOCTYPE}s/${DOCTYPE}-${ISSUE}/"

    # Add immutable marker
    echo "IMMUTABLE - signed and archived on $(date)" > "Reference/[Category]/${DOCTYPE}s/${DOCTYPE}-${ISSUE}/.immutable"

    # Commit
    git add Reference/
    git rm -r "in_basket/${LOCATION}/${DOCTYPE}-${ISSUE}/"

    git commit -m "vault: Archive signed ${DOCTYPE}-${ISSUE} to immutable Reference vault

Document: ${DOCTYPE}-${ISSUE}
Signed by: rajames440
Date: $(date)
Location: Reference/[Category]/${DOCTYPE}s/${DOCTYPE}-${ISSUE}/
Status: Immutable archive"

    # Post GitHub comment
    gh issue comment ${ISSUE} --body "✅ Signed and Archived

Your **${DOCTYPE}-${ISSUE}** has been signed and archived to the Reference vault.

**Location:** Reference/[Category]/${DOCTYPE}s/${DOCTYPE}-${ISSUE}/
**Status:** IMMUTABLE - read-only archive
**Timestamp:** $(date -u +%Y-%m-%dT%H:%M:%SZ)

This document is now part of the official governance record."

    # Log to SEC_LOG
    echo "| $(date -u +%Y-%m-%dT%H:%M:%SZ) | Signature Verified | disposition | ${DOCTYPE}-${ISSUE} | Moved to immutable vault | LOW |" >> SEC_LOG.adoc
else
    # Signature not found yet - document remains in in_basket
    echo "⧑ ${DOCTYPE}-${ISSUE} signature not yet found in Security/Signatures.adoc - awaiting your signature"
fi
```

**Result:** Signed documents moved to immutable Reference vault, logged in SEC_LOG, GitHub notified

---

## Summary: What Gets Committed

**Step 1:** `in-basket: Incoming document [TYPE]-[ID] from StarForth` (done by route-to-vault.yml)

**Step 2-3:** `disposition: Route [TYPE]-[ID] to [LOCATION]`
- Document moved from in_basket → proper location
- Git tracks the move

**Step 4:** (no commit, just notification sent and logged)

**Step 5:** `vault: Archive signed [TYPE]-[ID] to immutable Reference vault`
- Document moved from in_basket/[TYPE]/ → Reference/[Category]/[TYPE]s/
- Marked immutable
- Removed from in_basket

---

## Key Points

✅ **Documents automatically classified** by StarForth workflows (type:* labels)
✅ **Reference documents auto-vault** (no action needed)
✅ **Controlled documents** wait for your signature in in_basket/[TYPE]/
✅ **Your signature tracked** in Security/Signatures.adoc
✅ **All actions logged** to SEC_LOG.adoc
✅ **GitHub notifications** keep issue updated
✅ **in_basket preserved** with DO_NOT_REMOVE_ME file
✅ **Read-only repo** (only you can write)
