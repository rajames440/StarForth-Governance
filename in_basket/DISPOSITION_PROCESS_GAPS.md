# Gap Analysis - Document Disposition Process

## Critical Gaps (block implementation)

### GAP 1: Document Type Detection
**Issue:** Pipeline must scan document to determine type

**RESOLVED:**
- Scan/read the actual document file
- Claude can apply classification/intelligence if needed
- Document content should be self-describing (title, headers indicate type)
- Example: `= CAPA #042: Fix emoji parsing` clearly indicates CAPA
- If ambiguous, use Claude to classify based on content

**Implementation:** Read document, extract title/headers, determine type, use Claude if needed

---

### GAP 2: Required Signers Identification
**Issue:** Pipeline must determine WHO needs to sign each document

**RESOLVED:**
- Required signers determined by reading/scanning the document itself
- Document should clearly specify who must sign (in header, metadata, or signature block)
- Examples:
  - Document header: `:signers: rajames440, qa-lead`
  - Signature block shows required signers
  - Or document type + convention determines signers
- Pipeline reads and extracts signer requirements from document

**Implementation:** Parse document for signer requirements, default to convention if not specified

---

### GAP 3: Vault Directory Structure
**Issue:** Where exactly do documents go in [VAULT]?

**RESOLVED (partially):**
- Documents route to "where they belong in the directory structure of [VAULT]"
- Document NOT in force until all signatures collected OR PM override
- Master branch = current/in-effect documents at that time

**NEEDS CLARIFICATION:**
- What is the exact directory structure?
- Example structure needed:
  - `[VAULT]/CAPAs/CAPA-042/`?
  - `[VAULT]/Quality/CAPAs/CAPA-042/`?
  - `[VAULT]/Processes/CAPAs/CAPA-042/`?
  - Different for different types?

**NOTE:** DHR, DMR are controlled documents (not reference), structure TBD

**Impact:** BLOCKING - can't route without knowing destination

**Decision needed:** Exact vault directory structure for each document type

---

### GAP 4: Document Format Conversion
**Issue:** Pipeline must convert non-AsciiDoc to AsciiDoc

**Unknowns:**
- Which formats need conversion? (.md, .pdf, .docx, .odt, etc.)
- Can Claude handle this? (mentioned in step 2)
- Should conversion happen:
  - Before routing? (clean conversion in vault)
  - After signature? (original + signed version?)
  - Both? (preserve original + create .adoc version?)
- Does conversion lose information? (embedded images, complex formatting?)

**Impact:** MEDIUM - affects document quality/authenticity

**Decision needed:** Format conversion strategy?

---

### GAP 5: Signature Block Template
**Issue:** Where/how is signature block added to controlled documents?

**Unknowns:**
- Is template added to document content? (appended to .adoc)
  ```asciidoc
  == Signatures
  |===
  | Signer | Status | Date
  | rajames440 | Pending |
  |===
  ```
- Or tracked separately? (in document metadata or separate file?)
- Does signature block show required signers? Or created after all sign?
- Should it list signers pre-signing or post-signing?

**Impact:** LOW - nice-to-have for document completeness, not critical

**Decision needed:** Signature block format and placement?

---

### GAP 6: Document Timestamps
**Issue:** Pipeline needs created_at for escalation logic (Day 1 reminder, Day 3 PM escalation)

**RESOLVED:**
- Timestamps come from:
  1. **Git commit** (when document was first routed): `git log --follow document`
  2. **Document content** (if document specifies created timestamp in metadata/header)
- Use git commit timestamp as source of truth for "when was document routed"
- This provides precise audit trail

**Implementation:** Extract git commit date for routed document, use as created_at

---

### GAP 7: Document Type → Category Mapping
**Issue:** How do we know which vault category for each document type?

**Current mapping (guessed):**
```
CAPA → Quality or Processes?
CER → Quality or Processes?
ECR → Processes or Changes?
ECO → Processes or Changes?
FMEA → Quality?
DWG → Design?
ENG → Design or Engineering?
SEC → Security?
IR → Security or Incidents?
VAL → Verification?
DTA → Verification or Data?
```

**Unknowns:**
- Is there a defined mapping in StarForth-Governance already?
- Or should we create one?

**Impact:** MEDIUM - affects vault organization, not critical for signing

**Decision needed:** Document Type → Category mapping?

---

### GAP 8: Signature Verification - Authorized Signers
**Issue:** How does Jenkins know who CAN sign?

**Current understanding:** Check against `Security/Signatures.adoc`

**Unknowns:**
- Does Security/Signatures.adoc exist? Already created?
- Format?
  ```asciidoc
  | rajames440 | 0xABCDEF00 | [FINGERPRINT] |
  ```
- Does it list:
  - All authorized signers globally?
  - Or per-document-type signers?
  - Or per-role signers? (Owner, QA Lead, Engineer, etc.)

**Impact:** MEDIUM - critical for security, but can be created

**Decision needed:** Does Security/Signatures.adoc exist? What format?

---

### GAP 9: Signature Completion Criteria
**Issue:** How many signatures = document complete?

**RESOLVED:**
- **All required signers must sign** - unanimous required
- OR **PM override** - you can force completion without all signatures
- Document NOT in force until this condition met (or PM override)

**Implementation:**
- Count required signers from document
- Count verified signatures (matched to Security/Signatures.adoc)
- If count == required: complete
- If count < required AND no PM override: escalate (Day 1 reminder, Day 3 PM notification)
- If PM override applied: mark complete anyway

---

### GAP 10: Escalation Timing
**Issue:** Day 1 reminder and Day 3 PM escalation - configurable or hardcoded?

**Unknowns:**
- Are these fixed values for ALL documents?
- Or configurable per document type?
- What time of day does escalation check run?
- Should reminder be sent once or multiple times?

**Impact:** LOW - can be hardcoded initially, made configurable later

**Decision needed:** Escalation timing (hardcode or config)?

---

### GAP 11: PM Disposition Options
**Issue:** When PM is notified, what are the disposition options?

**Current understanding:**
- Push signers (contact them)
- Extend deadline
- Hold for next release
- Reject (not auto-reject, PM decides)

**Unknowns:**
- How does PM record their decision?
- Where is disposition logged?
- Can PM update the document/deadline in SEC_LOG?
- What happens to the document if rejected? (stays in vault? marked?)

**Impact:** MEDIUM - affects workflow, not critical for initial implementation

**Decision needed:** PM disposition workflow and logging?

---

### GAP 12: Push to GitHub - Timing
**Issue:** When does final push to GitHub happen?

**Unknowns:**
- After each document is complete?
- Batch push daily/weekly?
- Manual push by you?
- Automatic on completion of all documents?

**Impact:** LOW - can push after each document initially

**Decision needed:** Push timing and trigger?

---

## Non-Critical Gaps (nice-to-have)

**GAP 13:** Immutable marker format (`.immutable` file content)
**GAP 14:** Document archival cleanup (old documents moved out of active vault?)
**GAP 15:** Bulk document processing (multiple documents at once?)
**GAP 16:** Document version control (v1, v2 if revisions needed?)
**GAP 17:** Signature expiration (do signatures ever expire?)

---

## Summary of Blocking Issues

| Gap | Issue | Status |
|-----|-------|--------|
| 1 | Document type detection | ✓ RESOLVED - scan + Claude classification |
| 2 | Required signers | ✓ RESOLVED - extract from document |
| 3 | Vault directory structure | ✗ NEEDS CLARIFICATION - exact path structure? |
| 6 | Document timestamps | ✓ RESOLVED - from git commit date |
| 9 | Signature completion | ✓ RESOLVED - all required signers OR PM override |

**Remaining Blocker:**
- **GAP 3: Vault directory structure** - Need exact paths/structure for each document type

**Recommendation:** Clarify GAP 3, then proceed with implementation.

