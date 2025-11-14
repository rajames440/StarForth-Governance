# Phase 2C: Signature Verification & PR Operations - Implementation Plan

**Status:** PLANNING
**Current Phase:** Phase 2B (disposition pipeline) COMPLETE
**Blocker:** Vault directory structure mapping (needs user clarification)

## Objective

Implement the signature verification workflow for documents in Pending/[TYPE]/ directories, including:
- Creation of PR #2 & #3 (signature collection PRs)
- PGP signature verification
- Movement of fully-signed documents to vault
- Security event logging

## Current State

### Phase 2B Deliverables (✅ Complete)
- jenkinsfiles/disposition/Jenkinsfile with 15 stages
- Document classification via Claude
- Format conversion (markdown → asciidoc)
- Routing to Pending/[TYPE]/ directories
- Escalation tracking system
- Security log integration

### Infrastructure Available
- **Vault Structure:** Directories exist at repository root
  - Audits/
  - Compliance/
  - Defects/
  - Design/
  - Eco/
  - Ecr/
  - Fmea/
  - Incidents/
  - Performance/
  - Tests/
  - Validation/
  - Verification/

- **Security Directory:** `/Security/` (empty, needs setup)
- **SEC_LOG.adoc:** Currently in in_basket (needs to move to Security/)
- **Signatures.adoc:** Does NOT exist yet (needs creation)

### Known Document Types (from Claude classification)
```
CAPA    - Corrective Action
ECR     - Engineering Change Request
ECO     - Engineering Change Order
FMEA    - Failure Mode & Effects Analysis
DHR     - Design History Record (CONTROLLED - mapping unknown)
DMR     - Device Master Record (CONTROLLED - mapping unknown)
CER     - Complaint/Event Report (mapping unknown)
DWG     - Drawing (mapping unknown)
ENG     - Engineering Document (mapping unknown)
SEC     - Security (mapping unknown)
IR      - Incident Report (mapping unknown)
VAL     - Validation (mapping unknown)
DTA     - Data (mapping unknown)
ART     - Article/Reference (mapping unknown)
MIN     - Minutes (mapping unknown)
REL     - Release Notes (mapping unknown)
RMP     - Risk Management Plan (mapping unknown)
UNKNOWN - Unclassified
```

## Phase 2C Scope

### Stage 1: Signature Infrastructure Setup

**Files to Create:**
- `Security/Signatures.adoc` - Authorized signers registry
  - List of valid signers (username, email, PGP fingerprint)
  - Role/authority level
  - Is this static or per-document?

**Questions for User:**
1. **Authorized Signers:** How is the list of authorized signers determined?
   - Static file maintained manually?
   - Per-document requirement specified in metadata?
   - Role-based authorization?

2. **Vault Routing Mapping:** What's the mapping of document types to vault directories?
   ```
   CAPA    → ? (Defects? Compliance?)
   DHR     → ? (Design?)
   DMR     → ? (Design?)
   CER     → ? (Incidents?)
   DWG     → ? (Design?)
   ENG     → ? (Design?)
   SEC     → ? (Security?)
   IR      → ? (Incidents?)
   VAL     → ? (Validation?)
   DTA     → ? (Tests?)
   ART     → ? (Not moved to vault?)
   MIN     → ? (Not moved to vault?)
   REL     → ? (Not moved to vault?)
   RMP     → ? (Not moved to vault?)
   UNKNOWN → ? (Quarantine/Manual review?)
   ```

### Stage 2: Signature Verification Workflow

**What PR #2 & #3 Do:**
- Collect signatures from required signers
- Store as `[signer-name].asc` (detached PGP signature files)
- Update signature table in document body
- Log verification status

**Implementation Steps:**
1. Detect when signature file added to Pending/[TYPE]/[DOC]/ directory
2. Trigger verification pipeline
3. Validate signature against authorized signers (Signatures.adoc)
4. Validate signature against document content
5. Create PR (PR #2 or #3) with signature file and document update
6. Merge to master if valid, hold if invalid

**Questions for User:**
1. **Signature Format:**
   - Are these detached `.asc` files?
   - Signed by whom - individual developers or CI/CD system?
   - How are signatures created and placed in the directory?

2. **Signature Validation:**
   - Should we verify GPG signatures programmatically?
   - Or just verify the file exists and contains expected format?
   - What happens if signature is invalid - reject or escalate to PM?

3. **Signature Collection Timeline:**
   - How long should we wait for all signatures?
   - Does one signature suffice before moving to next signer?
   - Parallel or sequential signature collection?

### Stage 3: Vault Routing

**PR #4 Flow:**
- All required signatures collected and verified
- Document moved from Pending/[TYPE]/ → [TYPE]/
- Mark as immutable (how? .immutable marker? git attribute?)
- Archive old versions (if document updated later)
- Update security log

**Questions for User:**
1. **Vault Structure:**
   - Is each document in its own directory: `[TYPE]/[DOC]/` or flat: `[TYPE]/[DOC.ext]`?
   - How are versioning/updates handled?
   - What does "immutable" mean - no further edits allowed?

2. **Document Lifecycle:**
   - Can documents be updated after vault placement?
   - If updated, do all signatures need re-collected?
   - Where do old versions go - SupportingMaterials/?

## Phase 2C Implementation Phases

### Phase 2C-1: Infrastructure Setup (Blocking on user clarification)
- [ ] Clarify vault directory structure and type mapping
- [ ] Clarify authorized signers management approach
- [ ] Create Security/Signatures.adoc with authorized signers list
- [ ] Move SEC_LOG.adoc from in_basket to Security/
- [ ] Create PGP key management documentation

### Phase 2C-2: Signature Verification Workflow
- [ ] Create signature verification script
- [ ] Implement GPG signature validation
- [ ] Create PR #2-3 helper script (one per signature)
- [ ] Add signature status tracking
- [ ] Integrate with escalation system

### Phase 2C-3: Vault Routing Implementation
- [ ] Create vault routing logic
- [ ] Implement document immutability markers
- [ ] Add version archival logic
- [ ] Create PR #4 generation workflow
- [ ] Update security log with vault placement

### Phase 2C-4: Testing & Validation
- [ ] Test with signed TEST-CAPA-001.adoc
- [ ] Verify all PR creation works end-to-end
- [ ] Validate git commit history
- [ ] Test escalation for invalid signatures

## Blocking Questions (User Input Required)

**Critical Clarifications Needed Before Phase 2C Implementation:**

1. **Vault Directory Routing Map**
   - Exact mapping of each document type (CAPA, DHR, DMR, ECR, etc.) to vault directories
   - User previously noted: "DHR, DMR are CONTROLLED documents" - need full explanation

2. **Vault Structure**
   - Are documents stored as: `[TYPE]/[DOC.ext]` or `[TYPE]/[DOC]/` (with signature files inside)?
   - How are old versions handled?

3. **Authorized Signers**
   - Static registry or dynamic per-document?
   - Where is the source of truth for who can sign?

4. **Signature Mechanics**
   - What creates the `.asc` files - manual human action or automated?
   - Are signers expected to commit signature files to git?
   - Or does signature file upload trigger an automated process?

5. **Signature Verification**
   - Should pipeline validate GPG signatures cryptographically?
   - What happens if signature is invalid - auto-reject or PM decision?

## Next Steps

**Immediate Action:**
Please clarify the blocking questions above so we can:
1. Create accurate vault routing logic
2. Implement proper signature verification
3. Build PR #2-4 creation workflows

**Expected Timeline:**
- Phase 2C-1 Infrastructure: 1-2 hours (after clarification)
- Phase 2C-2 Signature Verification: 2-3 hours
- Phase 2C-3 Vault Routing: 2-3 hours
- Phase 2C-4 Testing: 1-2 hours
- **Total Phase 2C:** ~6-10 hours of implementation

---

**Current Commit:** f2a679a - docs: Disposition pipeline implementation status and roadmap
**Waiting For:** User clarification on vault structure and signature management
