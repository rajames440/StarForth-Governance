# StarForth Governance Workflow Implementation Guide

**Status:** GitHub Workflows Complete | Jenkins Phase 2 Pending
**Last Updated:** November 3, 2025
**Author:** Claude Code (continued implementation)

---

## Table of Contents

1. [Executive Summary](#executive-summary)
2. [Architecture Overview](#architecture-overview)
3. [Implemented Components](#implemented-components)
4. [Workflow Diagrams](#workflow-diagrams)
5. [Testing Guide](#testing-guide)
6. [Known Limitations](#known-limitations)
7. [Next Steps](#next-steps)

---

## Executive Summary

The StarForth governance system enforces **Rule 1: Governance-First Backlog Injection**. This means:

- **Only authorized items** (ECO and CAPA) can enter the development backlog
- **All GitHub issues** must use structured templates (CAPA, ECR, ECO, or FMEA)
- **FMEA acts as a blocking gate** for high-risk items before proceeding
- **Type labels are exclusive** - each issue has exactly ONE type
- **Amendment tracking is automatic** via GitHub issue edit history
- **Full audit trail** from submission through governance vault routing

### Governance Lifecycle Summary

```
                           ┌─────────────────┐
                           │  ECR Submission │
                           └────────┬────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │  PM Reviews (7-day SLA)       │
                    │  - Approves OR Rejects        │
                    └───────────────┬───────────────┘
                                    │
                         ┌──────────▼──────────┐
                         │ If Approved:        │
                         │ PM Creates ECO      │
                         └──────────┬──────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │ Check FMEA Requirement        │
                    │ (Eng Mgr decides)             │
                    └───────────────┬───────────────┘
                                    │
                         ┌──────────▼──────────┐
                         │ If FMEA Required:   │
                         │ - Create FMEA       │
                         │ - Block parent      │
                         │ - Convene meeting   │
                         │ - Get approvals     │
                         │ - Unblock parent    │
                         └──────────┬──────────┘
                                    │
                    ┌───────────────▼───────────────┐
                    │ ECO Added to Backlog          │
                    │ Status: Ready for Dev         │
                    └───────────────┬───────────────┘
                                    │
                        ┌───────────▼────────────┐
                        │ Developer Implementation
                        │ - May create CAPAs     │
                        │ - During work          │
                        └───────────────────────┘

CAPA FLOW (Parallel):
┌─────────────────┐
│ CAPA Submission │  (Defect/bug report)
└────────┬────────┘
         │
    ┌────▼──────────────────────┐
    │ QA Triage & Validation    │  ← Can loop multiple times
    │ - Reproducibility         │     (reject/request edits)
    │ - FMEA requirement check  │
    └────┬──────────────────────┘
         │
    ┌────▼───────────────┐
    │ Check FMEA Needed? │
    └────┬────────┬──────┘
         │        │
     YES │        │ NO
         │        │
    ┌────▼──┐  ┌──▼───────────────┐
    │ FMEA  │  │ Add to Backlog    │
    │ Block │  │ Status: Ready     │
    │ Issue │  └──────────────────┘
    └────┬──┘
         │
    ┌────▼────────────────────┐
    │ Stakeholders Approve    │
    │ in FMEA comments        │
    │ (✅ APPROVED format)    │
    └────┬───────────────────┘
         │
    ┌────▼───────────────────┐
    │ Parent CAPA Unblocked  │
    │ Ready for Development  │
    └───────────────────────┘
```

---

## Architecture Overview

### Design Principles

1. **Layered Validation**: Multiple gates check issues at different stages
2. **Template-First**: All issues must use authorized templates (Rule 1)
3. **Automation-Driven**: Workflows handle validation, classification, blocking, and unblocking
4. **Audit Trail**: GitHub issue edit history provides immutable records
5. **Amendment Tracking**: Any stakeholder can amend; GitHub logs who, what, when
6. **Governance Separation**: GitHub workflows handle development flow; separate process routes to in_basket

### Gate Levels

| Gate | Workflow | Purpose | Trigger | Action |
|------|----------|---------|---------|--------|
| 1 | enforce-template-requirement.yml | Detect template type | Issue opened | Label/comment or block |
| 2 | capa-submission.yml, ecr-submission.yml, eco-creation.yml, fmea-submission.yml | Validate template structure | Issue created/edited | Classify, assign, label |
| 3 | validate-backlog-item-type.yml | Ensure only ECO/CAPA in backlog | Backlog labels added | Remove invalid types |
| 4 | prevent-fmea-in-backlog.yml | Prevent FMEA in backlog | Backlog labels + type:fmea | Remove from backlog |
| 5 | enforce-type-label-exclusivity.yml | Exactly ONE type per issue | Labels changed | Warn if multiple |
| 6 | fmea-approval-and-unblock.yml | Unblock when stakeholders approve | FMEA edited | Remove blocking labels |

### Data Flow

```
GitHub Issue Created
    ↓
enforce-template-requirement.yml
├─ Template Detected? → Classify
└─ No Template? → Label + Comment
    ↓
Type-Specific Workflow
├─ CAPA: capa-submission.yml → QA Triage
├─ ECR: ecr-submission.yml → PM Review
├─ ECO: eco-creation.yml → Backlog Entry
└─ FMEA: fmea-submission.yml → Stakeholder Review
    ↓
Backlog Labels Applied?
├─ validate-backlog-item-type.yml → Check type
└─ prevent-fmea-in-backlog.yml → Check FMEA
    ↓
FMEA Required & Approval Status
    ├─ Awaiting Approval → Parent Blocked
    └─ Approved → fmea-approval-and-unblock.yml → Parent Unblocked
    ↓
Ready for Vault Routing
└─ QA Lead routes to StarForth-Governance/in_basket/
```

---

## Implemented Components

### Issue Templates (4 Templates)

#### 1. CAPA Template (.github/ISSUE_TEMPLATES/capa.yml)

**Purpose**: Structured defect/bug report with quality requirements

**Required Sections:**
- Problem Statement (observed vs expected)
- Reproduction (step-by-step)
- Environment (version, platform, OS)
- Defect Classification (bug type)
- Severity Assessment (CRITICAL/MAJOR/MINOR/LOW)
- Root Cause & Location (optional)
- Dependencies & Relationships (parent ECO, related issues)
- Amendment Policy (governance tracking)

**Validation**: Rejects placeholder text; requires substantive content
**Labels**: `type:capa`, `status:submitted`, `severity:*`
**Next Stop**: QA Triage (capa-submission.yml)

#### 2. ECR Template (.github/ISSUE_TEMPLATES/ecr.yml)

**Purpose**: Feature request for Engineering Manager review

**Key Sections:**
- Change Description
- Motivation & Justification
- Affected Areas (checkboxes)
- Risk Level assessment
- Potential Failure Modes
- FMEA Assessment (do you think FMEA needed?)
- Acceptance Criteria
- Effort Estimate
- Dependencies & Related Issues
- Amendment Policy

**Labels**: `type:ecr`, `status:submitted`, `awaiting-pm-review`
**Next Stop**: PM Review (7-day SLA per 01-ECR_PROCESS.adoc)

#### 3. ECO Template (.github/ISSUE_TEMPLATES/eco.yml)

**Purpose**: Engineering Manager creates from approved ECR; ready for backlog

**Key Sections:**
- Related ECR (link back to approved ECR)
- What Will Be Implemented (acceptance criteria)
- Implementation Constraints (requirements)
- FMEA Decision (NO/OPTIONAL/REQUIRED - Eng Mgr decides)
- FMEA Decision Rationale
- Backlog Priority (CRITICAL/HIGH/MEDIUM/LOW)
- Effort Estimate (refined)
- Success Criteria
- Dependencies & Related Work
- Amendment Policy

**Labels**: `type:eco`, `status:approved`, `backlog-ready`
**Pre-Population**: Eng Mgr fills from approved ECR
**Next Stop**: Backlog (validate-backlog-item-type.yml checks type)

#### 4. FMEA Template (.github/ISSUE_TEMPLATES/fmea.yml)

**Purpose**: Failure Mode & Effects Analysis (blocking gate)

**Key Sections:**
- Submission Details
- Related Issue (CAPA/ECR/ECO issue #)
- Failure Mode Analysis
- Root Cause & Occurrence
- Detection & Mitigation
- RPN Calculation (Severity × Occurrence × Detection)
- Required Stakeholders for approval
- Approval Sign-Off format

**Industry Standard**: Follows conventional FMEA format
**Blocking Behavior**: Parent issue blocked until all stakeholders approve
**Labels**: `type:fmea`, `status:submitted`, `awaiting-approval`
**Stakeholder Format**:
```
✅ APPROVED

Stakeholder: [Name]
Role: [Title]
Date: [Approval Date]
Notes: [Any conditions or concerns]
```

---

### Workflow Components (9 Workflows)

#### 1. enforce-template-requirement.yml (Gate 2)

**Trigger**: Issue opened
**Purpose**: Detect which template (if any) was used

**Detection Logic:**
```
CAPA: Body contains "## 1. PROBLEM STATEMENT"
ECR:  Title starts with "ECR:" OR body contains "Change Description"
ECO:  Title starts with "ECO-" OR body contains "## 1. RELATED ECR"
FMEA: Body contains "## 1. SUBMISSION DETAILS" OR "Risk Priority Number (RPN)"
```

**Actions:**
- ✅ Template Detected → Log and continue
- ❌ No Template → Post helpful comment with template links, add labels: `status:invalid`, `needs-template`, `rule-1-violation`

**Key Decision**: Does NOT auto-close; user must close and resubmit
**Governance Impact**: Rule 1 enforcement at entry point

#### 2. capa-submission.yml (CAPA Validation)

**Trigger**: Issue created/edited with CAPA template markers
**Purpose**: Validate CAPA content and auto-classify

**Validation:**
- All 6 required sections present (headers + content)
- Content is not placeholder text (semantic validation)
- Rejects: "[What actually happens]", "[First action]", etc.

**Auto-Classification:**
- **Severity**: CRITICAL | MAJOR | MINOR | LOW (based on keywords)
- **Regression**: Detected if mentions "worked before", "broke", etc.

**FMEA Requirement Check:**
- CRITICAL → FMEA required
- MAJOR + Regression → FMEA required
- Mentions architecture/safety → FMEA required
- Otherwise → No FMEA

**Actions if Valid:**
- Add labels: `type:capa`, `status:submitted`, `severity:*`
- Assign to QA team
- Post message: "CAPA received and assigned to QA for triage"
- Add to Kanban QA Review column

**Actions if Invalid:**
- Add labels: `type:capa`, `status:needs-info`
- Post detailed error message explaining what's missing

#### 3. ecr-submission.yml (ECR Validation)

**Trigger**: Issue created with ECR template markers
**Purpose**: Validate ECR content and route to PM

**Validation:**
- Required sections: "What is the change?", "Why needed?", "Problem solved?", "Acceptance Criteria"

**FMEA Decision Check:**
- If ECR author indicates FMEA required → Block issue, add `fmea-required` + `blocked` labels
- Post message about creating FMEA

**Actions if Valid:**
- Add labels: `type:ecr`, `status:submitted`, `awaiting-pm-review`
- Assign to PM (configurable)
- Post message: "ECR received. PM will review within 7 business days"
- Post link to ECR_PROCESS.adoc

**Note**: ECR never goes directly to backlog. Only ECO does.

#### 4. eco-creation.yml (ECO Validation & Backlog Entry)

**Trigger**: Issue created with ECO template markers
**Purpose**: Validate ECO and add to backlog

**Validation:**
- Required sections: Related ECR, Implementation, Constraints, FMEA Decision, Priority

**ECR Linking:**
- Extract ECR number from "Closes: ECR-YYYY-###"
- Find closed ECR issue in repo
- Comment on ECR linking to new ECO

**FMEA Extraction:**
- Parse FMEA Decision field
- If REQUIRED → Add labels `fmea-required` + `blocked`

**Actions if Valid:**
- Add labels: `type:eco`, `status:approved`, `backlog-ready`
- Add to Kanban Backlog column
- Comment: "ECO approved. Added to backlog. Ready for developer pickup"
- Notify development team

**Actions if Invalid:**
- Add labels: `type:eco`, `status:needs-info`
- Post error message with required sections

#### 5. fmea-submission.yml (FMEA Validation & Blocking)

**Trigger**: Issue created with FMEA template markers
**Purpose**: Validate FMEA and block parent issue

**Validation:**
- All FMEA sections present: Related Issue, Failure Mode, Effects, Root Causes, Mitigations, RPN, Stakeholders

**Related Issue Detection:**
- Extract parent issue number from "Related Issue #NNN"
- Parse required stakeholders list

**Actions if Valid:**
- Add labels: `type:fmea`, `status:submitted`, `awaiting-approval`
- **Block parent issue**:
  - Add to parent: `fmea-required` + `blocked` labels
  - Comment on parent with link to FMEA
  - Post message: "This issue is blocked pending FMEA approval"
- **Notify stakeholders**:
  - Post approval template with format: ✅ APPROVED, Stakeholder, Role, Date, Notes
  - Post deadline and list of required reviewers
- **Add to governance tracking**

**Actions if Invalid:**
- Add labels: `type:fmea`, `status:needs-info`
- Post message with required sections checklist

#### 6. fmea-approval-and-unblock.yml (FMEA Approval Detection & Parent Unblocking) **[NEW]**

**Trigger**: FMEA issue edited or comment added
**Purpose**: Monitor approvals and automatically unblock parent

**Approval Detection:**
- Scan FMEA body and comments for approval markers
- Count "✅ APPROVED" entries (each represents one stakeholder)
- Compare against required stakeholder count

**Unblocking Action (when all approved):**
- Remove from parent: `fmea-required` + `blocked` labels
- Add to parent: `fmea-approved` label
- Comment on parent: "FMEA approved. Issue unblocked. Ready for implementation"
- List all approvers

**Vault Preparation:**
- Add labels to FMEA: `status:approved`, `vault-ready`, `awaiting-governance-routing`
- Create governance metadata JSON
- Comment on FMEA: "Ready for vault routing by QA Lead"

**QA Lead Notification:**
- Log details for QA Lead action
- Specify vault destination: `StarForth-Governance/in_basket/fmea-###.md`
- Outline steps: Export, Route, Collect Signatures, Archive

#### 7. validate-backlog-item-type.yml (Gate 3 - Type Validation)

**Trigger**: `backlog-item` or `backlog-ready` labels added
**Purpose**: Ensure only ECO and CAPA in backlog

**Validation:**
- Check issue type label
- ✅ ALLOWED: `type:eco`, `type:capa`
- ❌ REJECTED: `type:ecr`, `type:fmea`, no type label

**Rejection Actions:**
- Remove backlog labels
- Add labels: `backlog-validation-failed`, `needs-correction`
- Post detailed message explaining:
  - Why ECR not in backlog (only ECO after PM approves)
  - Why FMEA not in backlog (blocking gate, separate column)
  - Generic issues need proper type labels

#### 8. prevent-fmea-in-backlog.yml (Gate 4 - FMEA Prevention)

**Trigger**: FMEA issue gets `backlog-item` or `backlog-ready` labels
**Purpose**: Prevent FMEA from entering backlog (it's a blocking gate)

**Detection:**
- Check for `type:fmea` label OR body markers
- Check for backlog labels

**Prevention Actions:**
- Remove backlog labels immediately
- Add labels: `do-not-backlog`, `awaiting-approval`
- Post message: "FMEA is blocking gate, not backlog item. Moved to Awaiting Approval."
- Explain why: prevents developers from picking up approval task instead of implementation

#### 9. enforce-type-label-exclusivity.yml (Type Label Validation)

**Trigger**: Any label changes on issue
**Purpose**: Ensure exactly ONE type label per issue

**Validation:**
- Count labels matching `type:*` pattern
- ✅ OK: Exactly 1 type label
- ❌ VIOLATION: 0 or 2+ type labels

**Violation Actions:**
- Post warning message
- Add label: `type-label-violation`
- Explain which types found and that only ONE is allowed
- Provide guidance on fixing

---

## Workflow Diagrams

### Complete GitHub Issue Lifecycle

```
                     [GitHub Issue Created]
                              │
                              ▼
                  ┌─────────────────────────┐
                  │ enforce-template-       │
                  │ requirement.yml         │
                  │ (Gate 2: Detect Type)   │
                  └────────┬────────────────┘
                           │
            ┌──────────────┼──────────────┐
            │              │              │
        CAPA │          ECR │          ECO │        FMEA
            ▼              ▼              ▼          ▼
    ┌──────────────┐ ┌──────────────┐ ┌──────────────────┐ ┌──────────────┐
    │ capa-        │ │ ecr-         │ │ eco-             │ │ fmea-        │
    │ submission   │ │ submission   │ │ creation         │ │ submission   │
    │ .yml         │ │ .yml         │ │ .yml             │ │ .yml         │
    └──────┬───────┘ └──────┬───────┘ └──────┬───────────┘ └──────┬───────┘
           │                │                │                    │
           │                │         [Validate ECO]              │
           │                │                │                    │
           ▼                ▼                ▼                    ▼
      [QA Triage]    [PM Review]    [Add to Backlog]     [Stakeholder Review]
           │          (7-day SLA)           │                    │
           │                │               │              [Get Approvals]
           │          ┌──────▼───────┐      │                    │
           │          │ If Approved: │      │         ┌──────────▼──────┐
           │          │ Create ECO   │      │         │ fmea-approval   │
           │          └──────┬───────┘      │         │ -and-unblock    │
           │                │               │         │ .yml            │
           │          ┌──────▼───────┐      │         └──────┬──────────┘
           │          │ Check FMEA   │      │                │
           │          │ Required?    │      │          [All Approved?]
           │          └──────┬───────┘      │                │
           │                │               │                ▼
           │         ┌───────┴───────┐      │          [Unblock Parent]
           │         │               │      │                │
           │    REQUIRED         NO  │      │         ┌──────▼────────┐
           │         │               │      │         │ Route to      │
           │         ▼               ▼      │         │ Governance    │
           │     [FMEA Block]    [Ready]    │         │ Vault         │
           │         │               │      │         └───────────────┘
           │         └───────┬───────┘      │
           │                 │              │
           ├─────────────────┼──────────────┤
           │                 │              │
           └─────────────────▼──────────────┘
                              │
                    ┌─────────▼──────────┐
                    │ validate-backlog-  │
                    │ item-type.yml      │
                    │ (Gate 3)           │
                    └──────────┬─────────┘
                               │
                    ┌──────────▼──────────┐
                    │ prevent-fmea-in-    │
                    │ backlog.yml         │
                    │ (Gate 4)            │
                    └──────────┬──────────┘
                               │
                    ┌──────────▼──────────┐
                    │ enforce-type-label- │
                    │ exclusivity.yml     │
                    │ (Gate 5)            │
                    └──────────┬──────────┘
                               │
                  ┌────────────▼────────────┐
                  │ [Ready for Development] │
                  └─────────────────────────┘
```

### FMEA Blocking Gate Details

```
                 [CAPA/ECR/ECO]
                      │
        ┌─────────────▼──────────────┐
        │ FMEA Required?             │
        │ - Critical severity        │
        │ - Major + regression       │
        │ - Architecture impact      │
        └────────┬───────────────────┘
                 │
         ┌───────▼────────┐
         │                │
      YES │                │ NO
         │                │
    ┌────▼────────┐   ┌───▼──────────────┐
    │ Create FMEA │   │ Add to Backlog   │
    └────┬────────┘   │ Ready for Dev    │
         │            └──────────────────┘
    ┌────▼───────────────────────┐
    │ Parent Issue Blocked:       │
    │ - fmea-required label      │
    │ - blocked label            │
    │ - "Awaiting FMEA approval" │
    └────┬───────────────────────┘
         │
    ┌────▼─────────────────────────────────┐
    │ Notify Stakeholders:                 │
    │ - List @mentions for approvers       │
    │ - Post approval format template      │
    │ - Set deadline                       │
    └────┬──────────────────────────────────┘
         │
    ┌────▼──────────────────────────────────┐
    │ Wait for Approvals in Comments:      │
    │ ✅ APPROVED                           │
    │ Stakeholder: [name]                  │
    │ Role: [title]                        │
    │ Date: [date]                         │
    │ Notes: [comments]                    │
    └────┬───────────────────────────────────┘
         │
    ┌────▼──────────────────────────┐
    │ Monitor with:                 │
    │ fmea-approval-and-unblock.yml │
    │                               │
    │ Count approvals:              │
    │ Required count met?           │
    └────┬───────────┬──────────────┘
         │           │
      YES│           │ NO
         │           │
    ┌────▼───┐  ┌────▼──────┐
    │ Unblock│  │ Await more│
    │Parent  │  │ approvals │
    └────┬───┘  └───────────┘
         │
    ┌────▼──────────────────────┐
    │ Remove Blocking Labels:    │
    │ - fmea-required           │
    │ - blocked                 │
    │                           │
    │ Add Completion Labels:    │
    │ - fmea-approved          │
    │ - vault-ready            │
    └────┬─────────────────────┘
         │
    ┌────▼──────────────────────┐
    │ Route to Governance Vault: │
    │ StarForth-Governance/      │
    │ in_basket/fmea-###.md      │
    │                            │
    │ (QA Lead action)           │
    └────┬─────────────────────┘
         │
    ┌────▼──────────────────────┐
    │ Parent Ready for Dev       │
    │ Implement per FMEA        │
    │ constraints               │
    └───────────────────────────┘
```

---

## Testing Guide

### Manual Testing Checklist

#### Test CAPA Workflow

1. **Create CAPA Issue**
   - Use `.github/ISSUE_TEMPLATES/capa.yml` template
   - Fill all required sections with real content (not placeholders)
   - Title: `CAPA: [Brief description]`

2. **Verify Validation**
   - ✅ Should add labels: `type:capa`, `status:submitted`, `severity:*`
   - ✅ Should assign to QA team
   - ✅ Should post comment: "CAPA received and assigned to QA for triage"

3. **Test Invalid CAPA**
   - Create CAPA with placeholder text
   - ✅ Should add label: `status:needs-info`
   - ✅ Should post error message listing missing content

4. **Test FMEA Requirement**
   - Create CAPA with "CRITICAL" severity
   - ✅ Should add label: `fmea-required`
   - ✅ Should add label: `blocked`
   - ✅ Should post blocking message

#### Test ECR Workflow

1. **Create ECR Issue**
   - Use `.github/ISSUE_TEMPLATES/ecr.yml` template
   - Title: `ECR: [Brief description]`
   - Fill all required fields

2. **Verify Submission**
   - ✅ Should add labels: `type:ecr`, `status:submitted`, `awaiting-pm-review`
   - ✅ Should assign to PM
   - ✅ Should post comment: "ECR received. PM will review within 7 business days"

3. **Test ECR with FMEA Required**
   - Fill FMEA Assessment as "Yes - High-risk"
   - ✅ Should block with `fmea-required` + `blocked` labels
   - ✅ Should post message about creating FMEA

#### Test ECO Workflow

1. **Create ECO Issue**
   - Use `.github/ISSUE_TEMPLATES/eco.yml` template
   - Title: `ECO-YYYY-###: [Brief description]`
   - Include "Closes: ECR-YYYY-###" in body
   - Fill all required sections

2. **Verify ECO Creation**
   - ✅ Should add labels: `type:eco`, `status:approved`, `backlog-ready`
   - ✅ Should add to Kanban Backlog column
   - ✅ Should comment on linked ECR: "ECO created"

3. **Test ECO Entry to Backlog**
   - ECO should successfully enter backlog
   - ✅ Pass validate-backlog-item-type.yml (only ECO/CAPA allowed)
   - ✅ Skip prevent-fmea-in-backlog.yml (not FMEA)

#### Test FMEA Workflow

1. **Create FMEA Issue**
   - Use `.github/ISSUE_TEMPLATES/fmea.yml` template
   - Title: `FMEA: [Parent issue #NNN description]`
   - Fill "Related Issue" with parent issue number
   - List required stakeholders

2. **Verify FMEA Submission**
   - ✅ Should add labels: `type:fmea`, `status:submitted`, `awaiting-approval`
   - ✅ Should block parent issue (add `fmea-required` + `blocked`)
   - ✅ Should post stakeholder notification with approval template
   - ✅ Should comment on parent: "This issue is blocked pending FMEA approval"

3. **Test Stakeholder Approval**
   - Simulate stakeholder approvals by editing FMEA and adding approval comments in format:
     ```
     ✅ APPROVED
     Stakeholder: @alice
     Role: QA Lead
     Date: 2025-11-03
     Notes: Approved pending fix for edge case X
     ```

4. **Test FMEA Unblocking**
   - Add 3 approval comments (if 3 stakeholders listed)
   - ✅ fmea-approval-and-unblock.yml should detect approvals
   - ✅ Should remove `fmea-required` + `blocked` from parent
   - ✅ Should add `fmea-approved` label to parent
   - ✅ Should comment on parent: "FMEA approved. Issue unblocked."
   - ✅ Should add `vault-ready` label to FMEA
   - ✅ Should comment on FMEA with vault routing instructions

#### Test Backlog Gates

1. **Test Gate 3: Invalid Type in Backlog**
   - Try to add `backlog-item` label to ECR issue
   - ✅ Should auto-remove backlog labels
   - ✅ Should add `backlog-validation-failed` label
   - ✅ Should post detailed message explaining why ECR ≠ backlog

2. **Test Gate 4: FMEA Prevention**
   - Create FMEA issue
   - Try to add `backlog-ready` label
   - ✅ Should auto-remove the label
   - ✅ Should add `do-not-backlog` + `awaiting-approval` labels
   - ✅ Should post message: "FMEA is blocking gate, not backlog item"

3. **Test Gate 5: Type Exclusivity**
   - Try to add both `type:capa` and `type:eco` to same issue
   - ✅ Should post warning
   - ✅ Should add `type-label-violation` label
   - ✅ Should explain that exactly ONE type required

### Automated Test Strategy

**Future Enhancement**: Create GitHub Actions test workflow that:
1. Creates dummy issues for each type with various content patterns
2. Verifies correct workflow triggers
3. Validates label application
4. Tests blocked/unblocked state transitions
5. Reports coverage

---

## Known Limitations

### Current Implementation

1. **FMEA Approval Detection** (fmea-approval-and-unblock.yml)
   - Currently counts "✅ APPROVED" markers in issue body
   - Does not yet parse individual comments separately
   - **Workaround**: Edit issue body to add approval section with all approvals
   - **Future**: Enhanced parsing of comment threads

2. **Stakeholder Parsing** (fmea-submission.yml)
   - Extracts @mentions from issue body
   - May miss if formatted differently than expected
   - **Workaround**: Ensure consistent formatting: "Required Stakeholders: @user1, @user2, @user3"

3. **ECR-to-ECO Linking** (eco-creation.yml)
   - Requires ECO body to include "Closes: ECR-YYYY-###"
   - May not find ECR if issue closed before ECO created
   - **Workaround**: Manually link via issue comments

4. **Kanban Integration** (eco-creation.yml)
   - Requires GitHub Projects v2 with proper column configuration
   - Column IDs must be stored in action secrets
   - **Workaround**: Manual Kanban drag-drop if automation fails

5. **Jenkins Integration**
   - GitHub workflows complete ✅
   - Jenkins Phase 2 gates NOT YET IMPLEMENTED ⏳
   - **Next**: Jenkins pipeline must also enforce gates during devL → test → qual stages

6. **Governance Vault Routing**
   - GitHub workflows prepare documents for vault
   - Actual routing (copy to in_basket/) is manual QA Lead action
   - **Future**: Automated routing via Jenkins "mail-sorter" pipeline

7. **Multi-Workflow Coordination**
   - Each workflow runs independently
   - No explicit orchestration between workflows
   - **Potential Issue**: If workflow fails silently, issue may not proceed correctly
   - **Mitigation**: Check issue labels manually if status unclear

### Design Trade-offs

| Decision | Rationale | Limitation |
|----------|-----------|-----------|
| Template-First (Rule 1) | Enforce governance from creation | Users must know template exists |
| GitHub-Only Currently | Workflows battle-tested, GitHub API reliable | Jenkins not yet integrated |
| Label-Driven Flow | Simple, observable state machine | Labels are public, can be manually edited |
| FMEA Body Parsing | Simpler than comment API | Requires editing issue to confirm approval |
| QA Lead Manual Routing | Governance controls flow | Slow (human action required) |

---

## Next Steps

### Phase 1: Testing & Validation (Recommended Now)

1. **End-to-End Testing**
   - Create test issues for each type
   - Verify all workflows trigger correctly
   - Test FMEA approval workflow
   - Document any edge cases

2. **Kanban Integration Testing**
   - Verify ECO/CAPA correctly appear in backlog column
   - Test that FMEA cannot be added to backlog
   - Test type label validation

3. **Documentation**
   - Create user guide for submitting CAPA/ECR/ECO/FMEA
   - Document SLAs (PM 7-day, FMEA 5-day, etc.)
   - Create troubleshooting guide

### Phase 2: Jenkins Integration (Next Priority)

1. **Implement Jenkins FMEA Gates**
   - Echo gate to prevent FMEA from entering devL → test → qual pipeline
   - (FMEA is documentation/analysis, not code)

2. **Implement Jenkins Backlog Validation**
   - Check ECO/CAPA issue type before triggering pipeline
   - Reject unknown work items

3. **Implement Jenkins Document Routing**
   - Create "mail-sorter" pipeline for vault archival
   - Route approved documents to StarForth-Governance/in_basket/
   - Collect and archive signatures

### Phase 3: Remaining Intake Pathways (Future)

The governance model identifies 6 additional document types:
1. **Defects** - From production incidents/monitoring
2. **Security Findings** - From security reviews
3. **Audit Findings** - From compliance audits
4. **Compliance Evidence** - Documentation of compliance
5. **Design Specifications** - From architecture reviews
6. **Incident Reports** - From field incidents

These may need:
- Additional GitHub issue templates (or use existing CAPA/ECR)
- Specialized workflows for each type
- Alternative intake mechanisms (not all via GitHub)
- Routing rules to governance vault

**Decision Needed**: Should these be GitHub-based or handled separately?

### Phase 4: Enhancements

1. **FMEA Approval Enhancements**
   - Parse individual comment threads
   - Require digital signature capture
   - Enforce deadline SLAs with warnings

2. **Workflow Orchestration**
   - Create parent workflow that coordinates multiple gates
   - Add workflow status dashboard
   - Alert if any workflow fails

3. **Metrics & Reporting**
   - Track cycle time (submission → backlog → implementation)
   - Report FMEA approval times
   - Generate governance compliance reports

4. **Amendment Policy Enforcement**
   - Automatically reject amendments without stated reason
   - Require role/signature for major changes
   - Audit amendment history

---

## Conclusion

The StarForth governance workflow implementation provides:

✅ **Rule 1 Enforcement**: Template-first, authorization-controlled backlog injection
✅ **Automated Validation**: Smart classification and requirement detection
✅ **FMEA Blocking Gates**: Prevents high-risk items from proceeding without analysis
✅ **Amendment Tracking**: Immutable GitHub-based audit trail
✅ **Stakeholder Coordination**: FMEA approval with deadline tracking
✅ **Governance Integration**: Prepares documents for vault routing

**Current Status**: GitHub workflows complete and ready for testing
**Next Major Phase**: Jenkins integration and additional intake pathways

---

**Document Version**: 1.0
**Last Updated**: November 3, 2025
**Status**: Ready for End-to-End Testing