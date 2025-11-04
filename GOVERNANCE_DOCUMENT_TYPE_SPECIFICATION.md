# Governance Document Type Specification - Phase 3

**Status**: Specification Complete (Ready for Implementation)
**Date**: November 3, 2025
**Based On**: User-completed questionnaire
**Scope**: GitHub submission → approval → in_basket routing (NOT vault organization or signatures)

---

## Executive Summary

Phase 3 extends the governance system from CAPA/ECR/ECO/FMEA to **all document types bound for the governance vault**. The system is intentionally two-phase:

**THIS PHASE (GitHub Workflows)**:
- ✅ Document submission via GitHub (issues, PRs, templates)
- ✅ Template validation and auto-classification
- ✅ Approval workflows (QUAL_MGR, PROJ_MGR, or PM decision)
- ✅ PM/Committee decision: Backlog vs Vault routing
- ✅ Route approved documents to in_basket (flat structure)

**LATER PHASE (Vault Management - Out of Scope)**:
- ⏳ in_basket organization and archival
- ⏳ Signature collection and records management
- ⏳ Document control and version management

---

## Part 1: Document Type Catalog

### 1.1 Document Type Registry

All document types that route to governance vault:

#### BACKLOG-PRODUCING TYPES (May create implementation work)

| Type | Code | Description | GitHub Template | Requires Review | Approver | Route Decision |
|------|------|-------------|-----------------|-----------------|----------|----------------|
| Corrective/Preventive Action | CAPA | Defect/bug report | capa.yml | ✅ Required | QUAL_MGR | PM decides: Backlog or Vault |
| Engineering Change Request | ECR | Feature request | ecr.yml | ✅ Required | PROJ_MGR | PM decides: Backlog or Vault |
| Engineering Change Order | ECO | Approved impl order | eco.yml | ✅ Required | QUAL_MGR | ECO always → Backlog |
| Failure Mode & Effects Analysis | FMEA | Risk analysis | fmea.yml | ✅ Required | QUAL_MGR | FMEA always → Vault (blocking) |

#### NON-BACKLOG TYPES (Governance/Reference only)

| Type | Code | Description | GitHub Template | Requires Review | Approver | Route Decision |
|------|------|-------------|-----------------|-----------------|----------|----------------|
| Continuous Engineering Report | CER | Protocol + Data + Report | cer.yml | ✅ Required | PROJ_MGR/QUAL_MGR | PROJ_MGR: Backlog or Vault |
| Engineering Drawing | DWG | Drawings + spec diagrams | dwg.yml | ✅ Required | PROJ_MGR | PROJ_MGR: Backlog or Vault |
| Engineering Design Report | ENG | Design decisions + docs | eng.yml | ✅ Required | PROJ_MGR | PROJ_MGR: Backlog or Vault |
| Security Review | SEC | Security analysis report | sec.yml | ✅ Required | PROJ_MGR | PROJ_MGR: Backlog or Vault |
| Incident Report | IR | Field/production incident | ir.yml | ✅ Required* | QUAL_MGR/PROJ_MGR | QUAL_MGR: Backlog or Vault |
| Validation & Verification | VAL | Test protocols, results | val.yml | ✅ Required | QUAL_MGR | QUAL_MGR: Backlog or Vault |
| Design History Record | DHR | Release/version snapshot | dhr.yml | ❌ Optional | PROJ_MGR | Auto → Vault (reference) |
| Design & Master Record | DMR | Current state/master | dmr.yml | ❌ Optional | PROJ_MGR | Auto → Vault (reference) |
| Supporting Data | DTA | Data/evidence pointers | dta.yml | ✅ Required | Depends on context | PROJ_MGR: Backlog or Vault |
| Artwork/Brand | ART | Logo, brand materials | art.yml | ❌ Optional | PROJ_MGR | Auto → Vault (reference) |

*Incident Reports marked OPTIONAL - require review if CRITICAL/MAJOR severity

#### REFERENCE TYPES (No review needed)

| Type | Code | Description | GitHub Template | Requires Review | Route Decision |
|------|------|-------------|-----------------|-----------------|--|
| Meeting Minutes | MIN | Team meeting notes | min.yml | ❌ Never | Auto → Vault |
| Release Notes | REL | Release documentation | rel.yml | ❌ Never | Auto → Vault |
| Roadmap | RMP | Product/project roadmap | rmp.yml | ⚠️ Optional | Auto → Vault if approved |

---

### 1.2 Document Type Categories

Organized as defined:

- **Research & Analysis**: CER (Engineering Research), VAL (V&V), SEC (Security)
- **Design & Specification**: DWG (Drawings), ENG (Engineering Reports), DMR (Master Record)
- **Administrative**: DHR (History Record), ART (Artwork), MIN (Minutes)
- **Compliance & Audit**: FMEA, IR (Incident), DTA (Supporting Data)
- **Reference & Records**: REL (Release Notes), RMP (Roadmap)

---

## Part 2: Submission & Routing Rules

### 2.1 How Documents Are Submitted

**Platform**: GitHub Issues (all document types)

**Interface**:
- Issue template + form with structured fields
- GitHub Actions workflows for validation
- Comments for approval
- Label-driven state machine

**Key Rules**:
- ✅ All submission via GitHub (no email, no direct filesystem)
- ✅ All documents go through GitHub workflows
- ✅ Filesystem updates are OUTPUTS (to in_basket), not inputs

### 2.2 The PM/Committee Decision Gate

**This is the CRITICAL junction**:

```
Document Submitted → Validated → Approved by QUAL_MGR or PROJ_MGR
                                        ↓
                        PM/Committee Reviews & Decides:
                                        ↓
                    ┌───────────────────┼───────────────────┐
                    │                   │                   │
              "This creates        "This is just       "This is a
               work we need        documentation      reference
               to build"           we should keep"     we don't
                    │                   │               need"
                    ↓                   ↓                   ↓
              → BACKLOG           → VAULT            → VAULT
           (developer will     (archived as       (reference
            pick up from       controlled doc)    material)
            backlog)
```

**PM Decision Factors**:
1. Does it require code/implementation work? → Backlog
2. Will developers be assigned? → Backlog
3. Is this a change request or reference? → Change = Backlog, Reference = Vault
4. Does it create work or document existing work? → Creates = Backlog, Documents = Vault

### 2.3 Backlog vs Vault Routing by Type

| Type | Default Routing | Can PM Override? | Notes |
|------|-----------------|------------------|-------|
| CAPA | PM decides | ✅ Yes | Often → Backlog (needs fixing) |
| ECR | PM decides | ✅ Yes | Often → Backlog (creates work) |
| ECO | Always Backlog | ❌ No | Approved feature implementation |
| FMEA | Always Vault | ❌ No | Blocking gate, not backlog work |
| CER | PM decides | ✅ Yes | Usually → Vault (reference) |
| DWG | PM decides | ✅ Yes | If spans multiple ECOs → reference |
| ENG | PM decides | ✅ Yes | Design decision → usually Vault |
| SEC | PM decides | ✅ Yes | If remediation needed → Backlog |
| IR | PM decides | ✅ Yes | If requires fix → Backlog |
| VAL | PM decides | ✅ Yes | Usually → Vault (test records) |
| DHR | Auto Vault | ❌ No | Release snapshot (reference) |
| DMR | Auto Vault | ❌ No | Master record (reference) |
| DTA | PM decides | ✅ Yes | Depends on what data supports |
| ART | Auto Vault | ❌ No | Brand material (reference) |
| MIN | Auto Vault | ❌ No | Meeting notes (reference) |
| REL | Auto Vault | ❌ No | Release history (reference) |
| RMP | Auto Vault | ❌ Yes | Roadmap (reference, optional review) |

---

## Part 3: Approval Workflows

### 3.1 Standard Approval Format (All Types)

```
✅ APPROVED

Stakeholder: [Name]
Role: [Title]
Date: [YYYY-MM-DD]
Notes: [Optional conditions or concerns]
```

This format is **consistent across all document types**.

### 3.2 Approval Authorities

Current (until role delegation):

| Document Type | Approval Authority | Notes |
|---------------|-------------------|-------|
| CAPA, ECR, ECO | PROJ_MGR (rajames440) | Also routes backlog decision |
| FMEA | QUAL_MGR (starforth-qa) | Stakeholders + QA approval |
| CER, DWG, ENG, SEC | PROJ_MGR | PM decides backlog vs vault |
| IR | QUAL_MGR or PROJ_MGR | Depends on severity/type |
| VAL, DTA | QUAL_MGR | Quality/test authority |
| DHR, DMR, ART, MIN, REL, RMP | PROJ_MGR | Reference materials |

**Future Enhancement**: Delegate specific approvers by domain (Formal Methods expert for thy files, Security lead for SEC, etc.) - not needed for MVP.

### 3.3 Engineering Research Sequential Approval

For **CER (Continuous Engineering Report)** with Protocol + Data + Report:

```
PROTOCOL SUBMITTED
    ↓
PROJ_MGR Reviews & Approves
    ✅ APPROVED
    Stakeholder: PM
    Role: Project Manager
    Date: YYYY-MM-DD
    Notes: [optional]
    ↓
RESULTS/DATA SUBMITTED
    ↓
PROJ_MGR Reviews & Approves (must reference Protocol approval)
    ✅ APPROVED
    Stakeholder: PM
    Role: Project Manager
    Date: YYYY-MM-DD
    Notes: [optional]
    ↓
FINAL REPORT SUBMITTED
    ↓
PROJ_MGR Reviews & Approves (must reference Protocol + Results approvals)
    ✅ APPROVED
    Stakeholder: PM
    Role: Project Manager
    Date: YYYY-MM-DD
    Notes: [optional]
    ↓
Ready to Route to in_basket
```

**Key**: Each stage must be approved before next stage starts.

---

## Part 4: Review Requirements by Type

### 4.1 Which Types Require Review

```
REQUIRED (Must have approval before routing):
  ✅ CAPA, ECR, ECO, FMEA
  ✅ CER, DWG, ENG, SEC, IR, VAL, DTA

OPTIONAL (Review required IF conditions met):
  ⚠️  Incident Report (CRITICAL/MAJOR severity → required)
  ⚠️  Roadmap (major update → optional review)

NEVER (No review needed):
  ❌ DHR (release snapshot)
  ❌ DMR (master record)
  ❌ ART (brand materials)
  ❌ MIN (meeting notes)
  ❌ REL (release notes)
```

### 4.2 Decision Trees for Optional Reviews

**Incident Report**:
```
Severity: CRITICAL?
  → YES: Require PROJ_MGR + QUAL_MGR approval
  → NO: Continue

Severity: MAJOR?
  → YES: Require QUAL_MGR approval
  → NO: Continue

Severity: MINOR?
  → YES: No approval needed (auto-vault)
  → NO: PM discretion
```

**Logo/Artwork Update**:
```
Major rebrand?
  → YES: Require PROJ_MGR approval
  → NO: Auto-vault

Affects external materials?
  → YES: Require legal/compliance review
  → NO: Auto-vault
```

**Roadmap**:
```
Affects planned delivery dates?
  → YES: Require PM approval
  → NO: Auto-vault
```

---

## Part 5: Code Fragments & References

### 5.1 Code Fragment (thy file) Format

When submitting formal verification code:

**Must Include**:
- ✅ Inline thy file code (in markdown code block)
- ✅ Link to actual file (from git repo with commit hash)
- ✅ Explanation/context (why this matters)
- ✅ Formal Methods expert approval
- ✅ Line numbers and reference points
- ✅ Version-locked with commit hash (for auditability)

**Example**:
```
## Proof: Component X Correctness

### Code Snippet
```thy
theorem component_x_correct:
  "∀ x. valid x → safe_operation x"
  proof by simp [valid_def, safe_operation_def]
```

### Source File
[formal-verification/component_x.thy @ a3b4c5d6](https://github.com/StarForth/StarForth/blob/a3b4c5d6/formal-verification/component_x.thy#L42)

Current version: [latest](https://github.com/StarForth/StarForth/blob/master/formal-verification/component_x.thy)

### Explanation
This theorem proves that component X maintains safety invariants for all valid inputs.
The proof is mechanically checked in Isabelle/HOL version 2024.

### Approval
✅ APPROVED
Stakeholder: Formal Methods Lead
Role: Verification Expert
Date: 2025-11-03
Notes: Proof syntax valid, logic sound, aligned with architecture requirements
```

### 5.2 External File Linking

When documents reference controlled or reference materials:

**Format**:
- Link to actual file in version control (git commit hash)
- Include type: [CONTROLLED] or [REFERENCE]
- Pointer format: `[document-name @ commit-hash](url)`

**Example**:
```
Implementation follows design spec:
[CONTROLLED] Design Specification [design-spec.md @ a3b4c5d6](url)

Build procedure:
[REFERENCE] Makefile [Makefile @ a3b4c5d6](url)
```

---

## Part 6: Routing to in_basket

### 6.1 What Goes to in_basket

**IN SCOPE**:
- ✅ All documents that passed validation
- ✅ All documents that received required approvals
- ✅ Both Backlog items AND Vault items

**OUT OF SCOPE** (happens in LATER phase):
- ❌ Vault organization/structure
- ❌ Signature collection
- ❌ Records management
- ❌ Access controls
- ❌ Long-term archival

### 6.2 Routing Authority

**Current**: QA Lead (QUAL_MGR) routes everything to in_basket after approval

**Process**:
```
Document Approved
    ↓
QA Lead initiates in_basket routing
    ├─ Backlog items → StarForth-Governance/in_basket/BACKLOG/
    └─ Vault items → StarForth-Governance/in_basket/[flat structure]
    ↓
Document Routed
    (QA Lead responsibility until LATER process picks up)
```

**Not Automated Yet**: "Routing automation (Jenkins mail-sorter) out of scope for this phase"

---

## Part 7: GitHub Implementation Structure

### 7.1 Issue Templates Needed

One template per document type:

```
.github/ISSUE_TEMPLATES/
├── capa.yml (✅ existing)
├── ecr.yml (✅ existing)
├── eco.yml (✅ existing)
├── fmea.yml (✅ existing)
├── cer.yml (NEW - Engineering Research)
├── dwg.yml (NEW - Drawings)
├── eng.yml (NEW - Engineering Reports)
├── sec.yml (NEW - Security)
├── ir.yml (NEW - Incident Reports)
├── val.yml (NEW - Validation & Verification)
├── dhr.yml (NEW - Design History Record)
├── dmr.yml (NEW - Design & Master Record)
├── dta.yml (NEW - Supporting Data)
├── art.yml (NEW - Artwork)
├── min.yml (NEW - Meeting Minutes)
├── rel.yml (NEW - Release Notes)
└── rmp.yml (NEW - Roadmap)
```

Total: **12 new templates** (4 existing + 12 new = 16)

### 7.2 GitHub Workflows Needed

One workflow per document type (in addition to existing 9):

```
.github/workflows/
├── [Existing 9 workflows for CAPA/ECR/ECO/FMEA]
├── cer-submission.yml (NEW)
├── dwg-submission.yml (NEW)
├── eng-submission.yml (NEW)
├── sec-submission.yml (NEW)
├── ir-submission.yml (NEW)
├── val-submission.yml (NEW)
├── dhr-submission.yml (NEW)
├── dmr-submission.yml (NEW)
├── dta-submission.yml (NEW)
├── art-submission.yml (NEW)
├── min-submission.yml (NEW)
├── rel-submission.yml (NEW)
├── rmp-submission.yml (NEW)
├── pm-backlog-vault-decision.yml (NEW - critical)
└── route-to-vault.yml (NEW - unified routing)
```

Total: **15 new workflows** (9 existing + 15 new = 24)

### 7.3 Label Schema

Extend existing label schema:

```
Type Labels:
  type:capa, type:ecr, type:eco, type:fmea, type:cer, type:dwg,
  type:eng, type:sec, type:ir, type:val, type:dhr, type:dmr,
  type:dta, type:art, type:min, type:rel, type:rmp

Status Labels:
  status:submitted, status:approved, status:needs-info, status:invalid

Route Labels:
  route:backlog, route:vault, awaiting-pm-decision

Approval Labels:
  approved-by-qualm, approved-by-projm, needs-approval

Reference Labels:
  reference-only, controlled-document, compliance-required
```

---

## Part 8: Phase 3 Implementation Roadmap

### 8.1 MVP Scope

**Must Have**:
- ✅ Engineering Research (CER) - Protocol, Results, Report
- ✅ Code Fragments (thy files with links)
- ✅ Engineering Reports (ENG)
- ✅ Incident Reports (IR)
- ✅ Drawings & Specifications (DWG)
- ✅ All document types destined for [VAULT]

**Nice to Have**:
- ⚠️ Logo/Artwork (ART)
- ⚠️ Configuration Documentation
- ⚠️ Meeting Minutes (MIN)

**Can Wait**:
- ⏳ All above are MVP - nothing waits

### 8.2 Implementation Priority (TBD by User)

**Phase 1 (Immediate)**:
- [ ] To be determined based on user priorities

**Phase 2 (Next)**:
- [ ] To be determined

**Phase 3 (Future)**:
- [ ] To be determined

**Phase 4 (Nice to Have)**:
- [ ] To be determined

---

## Part 9: Label & Approval Workflow Example

### 9.1 Complete Document Submission Flow

**Example: Security Review Document**

```
1. ENGINEER SUBMITS
   ├─ Uses sec.yml template
   ├─ Fills in: threat analysis, findings, remediation
   ├─ Document created as GitHub Issue #42
   └─ Workflow auto-detects type:sec label

2. VALIDATION WORKFLOW (sec-submission.yml)
   ├─ Validates required sections present
   ├─ Auto-classifies severity (HIGH/MEDIUM/LOW)
   ├─ Adds labels: type:sec, status:submitted, severity:HIGH
   └─ Assigns to PROJ_MGR for review

3. PM REVIEW & APPROVAL
   ├─ PROJ_MGR reviews Issue #42
   ├─ Posts approval comment:
   │   ✅ APPROVED
   │   Stakeholder: PM
   │   Role: Project Manager
   │   Date: 2025-11-03
   │   Notes: Findings accepted, schedule remediation ECR
   └─ Adds label: approved-by-projm

4. PM MAKES ROUTING DECISION (pm-backlog-vault-decision.yml)
   ├─ "These findings require 3 security patches"
   ├─ Creates 3 ECRs for remediation
   ├─ Labels Issue #42 with: route:vault (document reference)
   └─ Adds label: reference-for-backlog-items

5. ROUTE TO VAULT (route-to-vault.yml)
   ├─ QA Lead initiates routing
   ├─ Document copied to: in_basket/security-review-042.md
   ├─ GitHub links created in issue
   └─ Adds label: in-vault

6. LATER PHASE (out of scope)
   ├─ in_basket processing by vault team
   ├─ Signature collection
   ├─ Archival in StarForth-Governance
   └─ Final records management
```

---

## Part 10: Summary Table

### Complete Document Type Matrix

| Type | Code | Backlog Possible? | Review Required? | Approver | Special Handling | Template Status |
|------|------|-------------------|------------------|----------|------------------|-----------------|
| Corrective/Preventive | CAPA | ✅ Yes (PM decides) | Required | PROJ_MGR | FMEA gate check | ✅ Exists |
| Engineering Change Req | ECR | ✅ Yes (PM decides) | Required | PROJ_MGR | Transforms to ECO | ✅ Exists |
| Engineering Change Order | ECO | ✅ Always backlog | Required | QUAL_MGR | Approved feature | ✅ Exists |
| Failure Mode Analysis | FMEA | ❌ Never backlog | Required | QUAL_MGR | Blocking gate | ✅ Exists |
| Continuous Engineering | CER | ✅ Yes (PM decides) | Required | PROJ_MGR | Sequential approval | 🆕 New |
| Drawing/Spec | DWG | ✅ Yes (PM decides) | Required | PROJ_MGR | Links to source files | 🆕 New |
| Engineering Report | ENG | ✅ Yes (PM decides) | Required | PROJ_MGR | Design decisions | 🆕 New |
| Security Review | SEC | ✅ Yes (PM decides) | Required | PROJ_MGR | May spawn ECRs | 🆕 New |
| Incident Report | IR | ✅ Yes (PM decides) | ⚠️ Optional* | QUAL_MGR | Severity-based review | 🆕 New |
| Validation & Verification | VAL | ✅ Yes (PM decides) | Required | QUAL_MGR | Test protocols & results | 🆕 New |
| Design History Record | DHR | ❌ Never backlog | Optional | PROJ_MGR | Release snapshot | 🆕 New |
| Design & Master Record | DMR | ❌ Never backlog | Optional | PROJ_MGR | Current master state | 🆕 New |
| Supporting Data | DTA | ✅ Yes (PM decides) | Required | Varies | Data with pointers | 🆕 New |
| Artwork/Brand | ART | ❌ Never backlog | ⚠️ Optional* | PROJ_MGR | Brand materials | 🆕 New |
| Meeting Minutes | MIN | ❌ Never backlog | ❌ Never | N/A | Reference only | 🆕 New |
| Release Notes | REL | ❌ Never backlog | ❌ Never | N/A | Release history | 🆕 New |
| Roadmap | RMP | ❌ Never backlog | ⚠️ Optional* | PROJ_MGR | Major changes only | 🆕 New |

*Severity/complexity-based

---

## Part 11: Open Questions & TBD Items

### Items Left for Later Decision

1. **Phase Implementation Order**: Which document types in Phase 1 vs 2 vs 3? (User to decide)
2. **Approver Delegation**: When to delegate from PROJ_MGR to domain experts? (Future enhancement)
3. **Decision Tree Details**: Exact conditions for optional review types (TBD)
4. **Artifact Size Limits**: Maximum document/attachment size? (TBD)
5. **Vault Automation**: When to implement Jenkins mail-sorter? (LATER phase)
6. **Signature Capture**: How to collect/store digital signatures? (LATER phase)
7. **in_basket Organization**: Folder structure and archival process? (LATER phase)

---

## Conclusion

Phase 3 governance system defines:

✅ **16 document types** in comprehensive catalog
✅ **PM/Committee as gatekeeper** for Backlog vs Vault routing
✅ **Unified approval format** across all types
✅ **GitHub submission interface** for all documents
✅ **Sequential approval** for engineering research
✅ **Clear scope boundaries** (THIS phase vs LATER phase)

**Ready for Implementation**:
- 12 new GitHub issue templates
- 15 new GitHub workflows
- Extended label schema
- PM routing decision workflow
- Unified in_basket routing

**Implementation can begin immediately upon Phase 1 type prioritization.**

---

**Next Step**: User specifies Phase 1/2/3/4 prioritization → Implementation begins