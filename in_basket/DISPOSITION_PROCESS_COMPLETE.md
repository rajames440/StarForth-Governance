# Complete Document Disposition Process

## Architecture Overview

StarForth-Governance is the **gatekeeper for governance documents**. The [VAULT] (entire StarForth-Governance local repo) maintains a complete, auditable record with:
- **in_basket/** - incoming documents (pure audit trail)
- **SupportingMaterials/** - context, evidence, notes
- **Pending/** - documents in-progress (visible on master)
- **Reference/** - static reference materials (read-only)
- **[TYPE]/** - completed, signed, immutable documents (CAPAs/, ECRs/, etc.)

**Master branch principle:** All files on master = current and in-effect at that moment. Auditors see everything.

```
StarForth (route-to-vault.yml creates document)
    ↓
in_basket/ lands on master (FLAT, pure incoming capture)
    ↓
Jenkins Disposition Pipeline creates branch: doc/TYPE-ID
    │
    ├─ PR #1: Route to Pending/
    │  └─ in_basket/TYPE-ID/ → Pending/[TYPE]/TYPE-ID/
    │  └─ Merge to master
    │
    ├─ PR #2: Add signature from signer1
    │  └─ Create signer1-name.asc in Pending/[TYPE]/TYPE-ID/
    │  └─ Merge to master
    │
    ├─ PR #3: Add signature from signer2
    │  └─ Create signer2-name.asc in Pending/[TYPE]/TYPE-ID/
    │  └─ Merge to master
    │
    └─ PR #4: Move to vault (all signatures verified)
       └─ Pending/[TYPE]/TYPE-ID/ → [TYPE]/TYPE-ID/
       └─ Mark .immutable
       └─ Merge to master
    ↓
Master branch updated at each step (auditor sees progress)
    ↓
Push to GitHub (final sync)
```

---

## Complete Directory Structure

```
[VAULT] = entire StarForth-Governance local repository

master branch (always current & in-effect):

in_basket/                        (INCOMING - flat, audit trail)
├── DO_NOT_REMOVE_ME
├── CAPA-042-20251103.adoc
├── ECR-015-20251103.md
├── FMEA-008-20251103.pdf
└── ... (all incoming documents visible to auditors)

SupportingMaterials/              (CONTEXT - evidence, photos, notes)
├── Photos/
├── Videos/
├── Notes/
├── Spreadsheets/
└── RawData/

Pending/[TYPE]/                   (IN-PROGRESS - awaiting all signatures)
├── CAPAs/
│   ├── CAPA-042/
│   │   ├── CAPA-042.adoc
│   │   └── (signatures added here as they come in)
│   └── CAPA-043/
├── ECRs/
│   ├── ECR-015/
│   │   └── ECR-015.adoc
│   └── ECR-016/
├── FMEAs/
│   └── FMEA-008/
├── DHRs/
│   └── DHR-001/
├── DMRs/
│   └── DMR-001/
├── CERs/
│   └── CER-015/
├── DWGs/
│   └── DWG-001/
├── ENG/
│   └── ENG-001/
├── SEC/
│   └── SEC-001/
├── IR/
│   └── IR-001/
├── VAL/
│   └── VAL-001/
└── DTA/
    └── DTA-001/

Reference/                        (STATIC - no signatures, no workflow)
├── ARCHITECTURE.adoc
├── StartingForth.pdf
├── TechSpec.md
└── ... (reference books, specs, guides)

CAPAs/                            (COMPLETED & SIGNED - immutable)
├── CAPA-001/
│   ├── CAPA-001.adoc
│   ├── signer1-name.asc
│   ├── signer2-name.asc
│   └── .immutable
├── CAPA-042/
│   ├── CAPA-042.adoc
│   ├── rajames440.asc
│   └── .immutable
└── ...

ECRs/                             (COMPLETED & SIGNED - immutable)
├── ECR-001/
│   ├── ECR-001.adoc
│   ├── rajames440.asc
│   └── .immutable
└── ...

ECOs/                             (COMPLETED & SIGNED - immutable)
FMEAs/                            (COMPLETED & SIGNED - immutable)
DHRs/                             (COMPLETED & SIGNED - immutable)
DMRs/                             (COMPLETED & SIGNED - immutable)
CERs/                             (COMPLETED & SIGNED - immutable)
DWGs/                             (COMPLETED & SIGNED - immutable)
ENG/                              (COMPLETED & SIGNED - immutable)
SEC/                              (COMPLETED & SIGNED - immutable)
IR/                               (COMPLETED & SIGNED - immutable)
VAL/                              (COMPLETED & SIGNED - immutable)
DTA/                              (COMPLETED & SIGNED - immutable)

Security/
└── Signatures.adoc                (AUTHORIZED SIGNERS - static reference)
```

---

## Step 1: Document Lands in in_basket (FLAT, on master)

**What happens:**
- StarForth's route-to-vault.yml workflow routes document to in_basket/
- Document file lands in **flat in_basket/ directory** (no subdirectories)
- Document is already **committed to master branch** by route-to-vault.yml
- in_basket preserved as-is on master (audit trail for auditors)

**Audit visibility:** Auditor pulls master → sees in_basket with current incoming work + all completed documents

---

## Step 2: Pipeline Creates Branch & Scans Document

**Trigger:** Git push to in_basket/ on master

**Pipeline action:**

1. **Create feature branch** from master: `git checkout -b doc/TYPE-ID`

2. **Scan flat in_basket/** for new/unprocessed documents

3. **Read each document** to determine:
   - **Document type:** Scan document content, use Claude classification if needed
     - Examples: CAPA, ECR, ECO, FMEA, DHR, DMR, DWG, ENG, SEC, IR, VAL, DTA, CER
   - **Required signers:** Extract from document content
     - Document should specify: "Requires signature from: [signer1, signer2, ...]"
   - **Required signature count:** All required signers must sign (OR PM override)

4. **Convert format** if needed:
   - If not AsciiDoc, convert to AsciiDoc (markdown → .adoc, PDF → .adoc, etc.)
   - Use Claude intelligence for complex conversions

5. **Add signature block** if controlled document:
   ```asciidoc
   == Signatures

   |===
   | Signer | Status | Date | Signature

   | signer1-name | Pending |  |
   | signer2-name | Pending |  |
   |===
   ```

6. **Extract git commit timestamp** from when document was committed to in_basket
   - Use as `created_at` for escalation logic (Day 1 reminder, Day 3 PM escalation)

---

## Step 3: PR #1 - Route to Pending/

**Action:** Create internal PR #1 to route document from in_basket/ to Pending/

**Document Type Classification:**

**Reference Types (static reference, NO workflow):**
- ART (Architectural)
- MIN (Minutes)
- REL (Release Notes)
- RMP (Risk Management Plan)
- Other technical references (books, specs, guides)

**Controlled Types (require signatures, FULL workflow):**
- CAPA (Corrective/Preventive Action)
- CER (Certification Report) [CER-Protocol, CER-Results, CER-Report]
- ECR (Engineering Change Request)
- ECO (Engineering Change Order)
- FMEA (Failure Mode & Effects Analysis)
- DHR (Design History Report) - controlled, requires signature
- DMR (Design Master Record) - controlled, requires signature
- DWG (Drawing/Design)
- ENG (Engineering Document)
- SEC (Security Document)
- IR (Incident Report)
- VAL (Validation Report)
- DTA (Data/Test Artifact)

**Routing Logic:**

```
If document type in [ART, MIN, REL, RMP, other reference]:
    destination = Reference/[TYPE]/
    action = Move directly (no pending, no signatures needed)
    status = DONE
else:
    destination = Pending/[TYPE]/[DOCUMENT]/
    action = Create PR #1, move document, notify signers
    status = AWAITING SIGNATURES
```

**PR #1 Commit:**
```bash
git add Pending/[TYPE]/[DOCUMENT]/[document files]
git rm in_basket/[DOCUMENT]

git commit -m "disposition: Route [TYPE]-[ID] to Pending/

Document: [TYPE]-[ID]
Title: [TITLE]
Type: [TYPE]
Signers Required: [COUNT] ([list of signers])
Location: Pending/[TYPE]/[DOCUMENT]/
Status: In queue, awaiting signature notifications"
```

**Result on master after PR #1 merge:**
- Document moved from in_basket/ → Pending/[TYPE]/[DOCUMENT]/
- Visible on master as in-progress
- Auditor sees: "this document is being worked on, here's the location"

---

## Step 4: Notify Signers

**Action:** Send email + GitHub comments to all required signers

**Email notification:**
```
Subject: Signature Required: [TYPE]-[ID] - [TITLE]

Please review and sign the document.

Document Details:
  Type: [TYPE]
  ID: [ID]
  Title: [TITLE]
  Location: StarForth-Governance/Pending/[TYPE]/[DOCUMENT]/
  Required Signers: [signer1, signer2, signer3]

To Sign:
  1. Clone/pull StarForth-Governance repo
  2. Navigate to: Pending/[TYPE]/[DOCUMENT]/
  3. Review: document.adoc
  4. Sign locally: gpg --detach-sign --armor document.adoc
  5. Creates: signer-name.asc (detached signature file)
  6. Push signature file: git push

Deadline: [DATE - 3 days from routing, configurable]
```

**GitHub comment on original issue:**
```
✅ Document Routed for Signature

Your **[TYPE]-[ID]** document has been routed to the vault.

**Location:** StarForth-Governance/Pending/[TYPE]/[DOCUMENT]/
**Signers Required:** [list]

**Next Step:** Review and sign the document. See vault location for details.

**Status:** Awaiting [COUNT] signature(s)
```

**Log to SEC_LOG.adoc:**
```
| TIMESTAMP | Signature Notification | disposition | [TYPE]-[ID] | Routed to vault, awaiting [COUNT] signature(s) | LOW |
```

---

## Step 5: Signature Collection

**What signers do:**

1. Clone/pull StarForth-Governance repo
2. Navigate to document: `Pending/[TYPE]/[DOCUMENT]/`
3. Review document: `document.adoc`
4. Sign locally:
   ```bash
   cd Pending/[TYPE]/[DOCUMENT]/
   gpg --detach-sign --armor document.adoc
   # Creates: document.asc (detached signature)
   ```
5. Commit signature:
   ```bash
   git add document.asc
   git commit -m "sign: Add signature for [TYPE]-[ID]

   Document: [TYPE]-[ID]
   Signer: [YOUR NAME]
   Key: [0xYOURKEYID]
   Status: Signed"
   ```
6. Push:
   ```bash
   git push origin master
   ```

**Result on master:**
```
Pending/[TYPE]/[DOCUMENT]/
├── document.adoc
├── signer1-name.asc          ← added by signer1
├── signer2-name.asc          ← added by signer2
└── signer3-name.asc          ← added by signer3
```

---

## Step 6: Jenkins Verifies Signatures

**Trigger:** Each git push with signature file

**Jenkins verification:**

1. For each `.asc` file in Pending/[TYPE]/[DOCUMENT]/:
   ```bash
   gpg --verify signer1-name.asc document.adoc
   ```

2. Check signer against `Security/Signatures.adoc` (authorized signers list)
   - If signer in authorized list: ✓ VALID
   - If signer NOT in authorized list: ✗ INVALID - REJECT signature

3. Track signature collection:
   - Count verified signatures: X of Y required
   - List who signed, who hasn't

4. If all required signatures verified:
   - Create PR #4 (move to vault)
   - Mark document immutable

---

## Step 7: Escalation (Neglected/Orphan Documents)

**Timeline:**

**Day 0:** Document routed to Pending/, signers notified

**Day 1:** Reminder check
- Which required signers haven't signed?
- Send reminder email: "Reminder: Document [TYPE]-[ID] awaiting your signature"
- Log to SEC_LOG.adoc

**Day 3:** PM escalation
- Check: Still unsigned?
- Notify PM (you):
  ```
  Subject: Governance Alert: Document Awaiting Signatures

  Document [TYPE]-[ID] has been awaiting signatures for 3 days.

  Details:
    Type: [TYPE]
    Title: [TITLE]
    Location: Pending/[TYPE]/[DOCUMENT]/
    Required Signers: [list]
    Signed by: [who has signed]
    Still Needed: [who hasn't signed]

  Action Required:
    - Contact unsigned signers, push for completion
    - Extend deadline if needed
    - Hold document for next release
    - Reject document (requires your decision)

  Your call - no auto-action.
  ```
- Log decision to SEC_LOG.adoc

**No auto-rejection:** Documents can't be discarded, only PM can decide disposition.

---

## Step 8: PR #4 - Move to Vault (All Signatures Verified)

**Action:** When all required signatures verified, create PR #4 to move document to vault

**PR #4 Commit:**
```bash
git add [TYPE]/[DOCUMENT]/[all files]
git rm -r Pending/[TYPE]/[DOCUMENT]/

git commit -m "vault: Archive signed [TYPE]-[ID] to immutable vault

Document: [TYPE]-[ID]
Signatures: [COUNT] verified
Signers: [list]
Location: [TYPE]/[DOCUMENT]/
Status: IMMUTABLE - read-only governance record"
```

**Add immutable marker:**
```bash
echo "IMMUTABLE - Signed $(date)" > [TYPE]/[DOCUMENT]/.immutable
git add [TYPE]/[DOCUMENT]/.immutable
```

**Post GitHub comment:**
```
✅ Signed and Complete

Document [TYPE]-[ID] has all required signatures and is now immutable.

Location: StarForth-Governance/[TYPE]/[DOCUMENT]/
Status: IMMUTABLE - read-only governance record
Signatures: [COUNT] verified
Timestamp: [ISO8601]

This document is now part of the official governance record.
```

**Log completion:**
```
SEC_LOG.adoc entry:
| TIMESTAMP | Signature Complete | disposition | [TYPE]-[ID] | All signatures verified, document immutable | LOW |
```

**Result on master after PR #4 merge:**
- Document moved from Pending/ → [TYPE]/
- Marked immutable
- Now part of official record
- Cannot be changed (immutable marker prevents modifications)

---

## Step 9: Push to GitHub

**Final step:** Push all commits from local [VAULT] repo to GitHub

```bash
cd [VAULT]
git push origin master
```

This pushes:
- Documents routed to Pending/
- Signature files added
- Documents moved to [TYPE]/ (immutable)
- Immutable markers
- SEC_LOG.adoc updates
- All audit trail and PR history

---

## Key Principles

✅ **in_basket stays FLAT** - documents flow through, not stored in subdirectories
✅ **Documents read, not metadata** - pipeline scans actual content
✅ **Multi-signer support** - documents can require multiple signatures
✅ **All required or PM override** - unanimous required unless you override
✅ **Immutable once signed** - signature verification marks document complete
✅ **All actions logged** - SEC_LOG.adoc is complete audit trail
✅ **GitHub integration** - comments keep stakeholders informed
✅ **Branch + PR strategy** - internal PRs document every step
✅ **Master always current** - all files on master = in-effect at that moment
✅ **Read-only except owner** - only rajames440 can commit
✅ **Auditor transparency** - everything visible, nothing hidden
✅ **No auto-rejection** - you're the gatekeeper for disposition

---

## Security/Signatures.adoc Format

```asciidoc
== Authorized Signatories

Official record of who can sign governance documents.

|===
| Name | Email | PGP Key | Fingerprint | Active

| rajames440 | [email@domain] | 0xABCDEF00 | [FULL FINGERPRINT] | ✓
| qa-lead | [email@domain] | 0x12345678 | [FULL FINGERPRINT] | ✓
| eng-manager | [email@domain] | 0x87654321 | [FULL FINGERPRINT] | ✓
|===
```

Jenkins verifies signatures against this list.

---

## Status: ✅ Architecture Complete

All components defined and integrated. Ready for Jenkins implementation.
