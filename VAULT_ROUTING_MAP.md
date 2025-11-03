# Vault Routing Map

**Version:** 1.0
**Last Updated:** 2025-11-03
**Authority:** PM (rajames440)

This document defines the authoritative mapping of document types to vault directories. It determines where each document is routed after signature collection is complete.

## Routing Architecture

Documents follow this journey:

```
in_basket/ (intake)
    ↓
Pending/[TYPE]/ (signature collection)
    ↓
[VAULT_DIRECTORY]/ (permanent vault storage)
```

## Complete Routing Map

| Doc Type | Description | Vault Directory | Controlled | Signatures | Notes |
|----------|-------------|-----------------|-----------|-----------|-------|
| **CAPA** | Corrective Action | Defects/ | Yes | rajames440, qa-lead | Quality response to identified issues |
| **ECR** | Engineering Change Request | Design/ | Yes | rajames440, eng-manager | Change request documentation |
| **ECO** | Engineering Change Order | Design/ | Yes | rajames440, eng-manager | Approved change implementation |
| **FMEA** | Failure Mode & Effects Analysis | Performance/ | Yes | rajames440, qa-lead, security-officer | Risk and reliability analysis |
| **DHR** | Design History Record | Design/ | Yes | rajames440, eng-manager | Design documentation history |
| **DMR** | Device Master Record | Compliance/ | Yes | rajames440, compliance-lead | Regulatory master record |
| **CER** | Complaint/Event Report | Incidents/ | Yes | rajames440, incident-response | Customer/field incidents |
| **DWG** | Drawing/Schematic | Design/ | Yes | rajames440, eng-manager | Technical drawings |
| **ENG** | Engineering Document | Design/ | Yes | rajames440, eng-manager | General engineering specs |
| **SEC** | Security Document | Security/ | Yes | rajames440, security-officer | Security policies/procedures |
| **IR** | Incident Report | Incidents/ | Yes | rajames440, incident-response | Internal incident analysis |
| **VAL** | Validation Document | Validation/ | Yes | rajames440, qa-lead | Test/validation results |
| **DTA** | Data/Test Results | Tests/ | Yes | rajames440, qa-lead | Raw test data and results |
| **ART** | Article/Reference | _(not routed)_ | No | _(none)_ | Stays in Pending/ (reference only) |
| **MIN** | Minutes | _(not routed)_ | No | _(none)_ | Stays in Pending/ (reference only) |
| **REL** | Release Notes | _(not routed)_ | No | _(none)_ | Stays in Pending/ (reference only) |
| **RMP** | Risk Management Plan | Performance/ | Yes | rajames440, incident-response | Risk tracking |
| **UNKNOWN** | Unclassified | Audits/ | No | _(TBD)_ | Requires manual review |

## Vault Directory Details

### Design/
**Purpose:** Technical design and engineering specifications
**Contents:** DWG, ECR, ECO, DHR, ENG documents
**Retention:** Permanent (controlled documents)
**Immutable:** Yes

### Defects/
**Purpose:** Quality and defect tracking
**Contents:** CAPA documents
**Retention:** Permanent (controlled documents)
**Immutable:** Yes

### Compliance/
**Purpose:** Regulatory and compliance documentation
**Contents:** DMR documents
**Retention:** Permanent (controlled documents)
**Immutable:** Yes

### Incidents/
**Purpose:** Incident and complaint tracking
**Contents:** CER, IR documents
**Retention:** Permanent (controlled documents)
**Immutable:** Yes

### Performance/
**Purpose:** Reliability, safety, and risk analysis
**Contents:** FMEA, RMP documents
**Retention:** Permanent (controlled documents)
**Immutable:** Yes

### Security/
**Purpose:** Security policies, procedures, and logs
**Contents:** SEC documents, Signatures.adoc, SEC_LOG.adoc, escalation tracking
**Retention:** Permanent (controlled documents)
**Immutable:** Yes (except log entries)

### Tests/
**Purpose:** Test results and validation data
**Contents:** DTA documents
**Retention:** Permanent (controlled documents)
**Immutable:** Yes

### Validation/
**Purpose:** Validation and verification documentation
**Contents:** VAL documents
**Retention:** Permanent (controlled documents)
**Immutable:** Yes

### Audits/
**Purpose:** Audit trails and unclassified documents
**Contents:** UNKNOWN type documents, audit records
**Retention:** Permanent
**Immutable:** Yes

### Pending/
**Purpose:** Temporary in-progress document storage
**Contents:** All documents awaiting signature completion
**Retention:** Until all signatures collected OR PM override decision
**Immutable:** No (documents modified as signatures collected)

### Reference/
**Purpose:** Static reference material (not governed by this pipeline)
**Contents:** Books, standards, infrastructure docs
**Retention:** Permanent
**Immutable:** Yes

## Document Status in Vault

### Controlled Documents (ART, MIN, REL, RMP routed)

Structure:
```
[VAULT]/[TYPE]-[ID]/
├── [TYPE]-[ID].adoc        ← Main document (immutable)
├── [TYPE]-[ID].immutable   ← Marker file (document is immutable)
├── [TYPE]-[ID].[signer].asc ← Signature file (per signer)
└── .metadata               ← Document metadata (routed_at, vault_at)
```

Immutability:
- Once in vault, document content cannot be changed
- Signature files are permanent
- `.immutable` marker prevents accidental edits

### Uncontrolled Documents (ART, MIN, REL, RMP NOT routed)

These documents do NOT move to vault. They stay in:
```
Pending/[TYPE]/[DOCUMENT]
```

They serve as permanent reference material:
- No vault routing
- No signature requirement
- Remain visible for context/reference

## Vault Routing Process

### PR #4: Move to Vault (PR #4)

Triggered when:
1. All required signatures collected and verified
2. No signature errors or rejections
3. Document ready for immutable storage

Actions:
1. Create directory: `[VAULT]/[TYPE]-[ID]/`
2. Copy document: `[DOCUMENT]` → `[VAULT]/[TYPE]-[ID]/[DOCUMENT]`
3. Copy signatures: `*.asc` files → `[VAULT]/[TYPE]-[ID]/`
4. Create marker: `.immutable` file
5. Create metadata: `.metadata` with timestamps
6. Remove from Pending/
7. Commit to master (PR #4)
8. Push to GitHub

### Document Versioning

If a document in vault is updated:
1. Old version moved to: `SupportingMaterials/[TYPE]/[OLD_VERSION]/`
2. New version moves through disposition again (new signatures required)
3. Creates new branch/PRs for updated document

## Security Implications

1. **No Overwriting:** Once in vault, documents cannot be overwritten
2. **Audit Trail:** git commit history shows all movements
3. **Signature Immutability:** Signatures locked in vault location
4. **Version History:** Old versions preserved in SupportingMaterials/

## Exceptions & Manual Overrides

**PM Override (rajames440):**
- Can move document to vault without all signatures (with PM justification)
- Can move document with signature errors (PM reviews risk)
- Action logged in SEC_LOG.adoc

**Escalation to PM:**
- Signature timeout (Day 3)
- Invalid signature (cryptographic failure)
- Unauthorized signer attempt
- Document classification ambiguity

## Testing & Validation

Test documents use this routing:

| Test Doc | Type | Routes To |
|----------|------|-----------|
| TEST-CAPA-001.adoc | CAPA | Defects/ |
| TEST-ECR-001.md (→ .adoc) | ECR | Design/ |

## Change History

| Date | Change | Authorized By |
|------|--------|----------------|
| 2025-11-03 | Initial vault routing map created | rajames440 |

---

**Document Classification:** ENG (Engineering/Control)
**Owner:** Rajames (rajames440)
**Review Frequency:** As needed (when new document types added)
**Last Updated:** 2025-11-03
