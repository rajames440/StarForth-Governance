# Governance Document Type & Routing Questionnaire

**Purpose**: Define the complete multi-pathway governance system
**Instructions**: Fill out each section with your answers. You can leave blank any sections that need more thought and come back to them.
**Format**: This will become the specification for Phase 3 governance implementation

---

## Section 1: Document Type Taxonomy

### 1.1 Complete List of Document Types

List ALL document types that should be routed to the governance vault. Include any I missed.

```
BACKLOG-PRODUCING TYPES (Will create implementation work):
  ✅ CAPA - Defect/bug report
  ✅ ECR - Feature request
  ✅ FMEA - Risk analysis (blocking gate)
  ? [Your additions]:
  CER (Contunuious Engineering report) may be a Protocol, Experimental data and a final engineering report. These are signed & controld documents in the Engineering folder in the [VAULT].
  DWG Drawings from any source
  ART Artwork
  DHR (per tag & release [the current release state of the union])
  DMR (TODO for Governance Model [what StarForth is and it's uses & overall master record])
  SEC Security related documents
  IR Incident Report
  ENG Engineering reports of any kind including design decissions.
  This must be built to extend easily.
  VAL Validation & Verification Protocols and reports
  DTA any data needed to support a documented claim. with pointer as needed
  
  _________________________________________________________________
  _________________________________________________________________
  _________________________________________________________________

NON-BACKLOG TYPES (Governance/Reference only, no implementation):
  ? [List them]:
  We have a pathway for dealing with reference docs othat are [VAULT]ed but not considered to be regulated already.
  Only two things may be backlogged, Reference documents and Controled documents. All others require PM approval to be directly inserted into theor proper place. (PM or committiee)
  _________________________________________________________________
  _________________________________________________________________
  _________________________________________________________________
  _________________________________________________________________
  _________________________________________________________________
  _________________________________________________________________

UNSURE CATEGORY (Might produce backlog, might not):
  ? [List them]:
  See above
  anything that's not controlled or refference
  _________________________________________________________________
  _________________________________________________________________
  _________________________________________________________________
```

---

### 1.2 Document Type Categories

Should we organize document types into broader categories? If so, what are they?

```
Current proposal:
  - Research & Analysis (protocols, experiments, proofs)
  - Design & Specification (drawings, architecture, code)
  - Administrative (logos, configs, records)
  - Compliance & Audit (evidence, reports)
  - Reference & Records (changelogs, minutes)

Do you agree with these categories?
  [X] YES, use as-is
  [ ] MODIFY - suggest changes:
  _________________________________________________________________
  _________________________________________________________________
  [ ] NO, use different categories:
  _________________________________________________________________
  _________________________________________________________________
  _________________________________________________________________

Where do the following fit?
  - Engineering Protocol: _________________________________________
  - Code Fragments (thy files): DWG with pointer to the actual source
  - Engineering Drawings: DWG 
  - Security Review Reports: SEC 
  - Incident Reports: IR
  - Configuration Documentation: DWG with pointer
  - Design Decisions: ENG
  - Formal Verification Artifacts: VAL
  - Other: for PM or committee decision. 
```

---

## Section 2: Review & Approval Requirements

### 2.1 Which Document Types REQUIRE Review?

```
For each type, mark: REQUIRED | OPTIONAL | NEVER

CAPA:                     [X] Required [ ] Optional [ ] Never
ECR:                      [X] Required [ ] Optional [ ] Never
ECO:                      [X] Required [ ] Optional [ ] Never
FMEA:                     [ ] Required [ ] Optional [ ] Never

Engineering Protocol:     [X] Required [ ] Optional [ ] Never
Experiment Results:       [X] Required [ ] Optional [ ] Never
Engineering Report:       [X] Required [ ] Optional [ ] Never
Code Fragment (thy):      [X] Required [ ] Optional [ ] Never
Engineering Drawings:     [X] Required [ ] Optional [ ] Never

Security Review:          [X] Required [ ] Optional [ ] Never
Incident Report:          [X] Required [ ] Optional [ ] Never
Logo/Brand Update:        [ ] Required [X] Optional [ ] Never
Design Document:          [X] Required [ ] Optional [ ] Never
Configuration Change:     [X] Required [ ] Optional [ ] Never
Compliance Evidence:      [X] Required [ ] Optional [ ] Never
Meeting Minutes:          [ ] Required [X] Optional [ ] Never
Release Notes:            [ ] Required [X] Optional [ ] Never

Other:
  Roadmap                 : [ ] Required [X] Optional [ ] Never
  ________________________: [ ] Required [ ] Optional [ ] Never
  ________________________: [ ] Required [ ] Optional [ ] Never
```

---

### 2.2 Conditional Review (Decision Trees)

For documents marked OPTIONAL, what's the decision tree?

**Example 1: Logo/Brand Update**
```
Logo/Brand Update
  ├─ IF: Is this a major rebrand?
  │   [X] YES → Require PM approval
  │   [ ] NO → Skip approval
  │
  └─ IF: Affects external customer materials?
      [X] YES → Require legal/compliance review
      [ ] NO → Skip approval
```

**Example 2: Incident Report**
```
Incident Report
  ├─ IF: Severity is CRITICAL?
  │   [X] YES → Require PM + QA approval
  │   [ ] NO → Continue
  │
  ├─ IF: Severity is MAJOR?
  │   [X] YES → Require QA approval
  │   [ ] NO → Continue
  │
  └─ IF: Severity is MINOR?
      [X] YES → No approval needed
      [ ] NO → [other action]
```

**Your Decision Trees** (fill in for types marked OPTIONAL):
TBD
```
Document Type: ______________________________
  ├─ IF: ______________________________?
  │   [ ] YES → Require ______________________ approval
  │   [ ] NO → ______________________________
  │
  └─ IF: ______________________________?
      [ ] YES → Require ______________________ approval
      [ ] NO → ______________________________

Document Type: ______________________________
  ├─ IF: ______________________________?
  │   [ ] YES → Require ______________________ approval
  │   [ ] NO → ______________________________
  │
  └─ IF: ______________________________?
      [ ] YES → Require ______________________ approval
      [ ] NO → ______________________________

Document Type: ______________________________
  ├─ IF: ______________________________?
  │   [ ] YES → Require ______________________ approval
  │   [ ] NO → ______________________________
  │
  └─ IF: ______________________________?
      [ ] YES → Require ______________________ approval
      [ ] NO → ______________________________
```

---

### 2.3 Who Are the Approvers?

For each review role needed, define who they are:

```
Approver Roles (by responsibility):

QA Lead always defined in QUAL_MGR
  Current: starforth-qa team (or specific person)
  Definition: Reviews for QA impact, testing requirements
  For document types: CAPA, FMEA, _____________________________
  [ ] Use same person as CAPA/FMEA reviews
  [ ] Different person/team: ___________________________________

PM (Product Manager)
  Current: rajames440 (PROJ_MGR)
  All reviews gated here for signoff for now
  
  Definition: Reviews for business impact, backlog priority
  For document types: ECR, ECO, _______________________________
  [ ] Use same person as ECR reviews
  [ ] Different person/team: ___________________________________

Architecture Lead
  Current: [Who?] PROJ_MGR
  Definition: Reviews for system impact, design alignment
  For document types: Design Doc, FMEA, Code Fragment, _________
  [ ] Needs to be defined
  [X] Person/team: Captain Bob

SME (Subject Matter Expert)
PROJ_MGR
  Definition: Domain expert review (varies by type)
  For document types: Engineering Protocol, Report, Code, _______
  [ ] One person for all SME reviews: __________________________
  [ ] Different SMEs by domain:
      - Research/Math: _________________________________________
      - Security: _____________________________________________
      - Performance: __________________________________________
      - Other domain: __________________________________________

Formal Methods Expert PROJ_MGR
  Current: [Who?] _______________________________________________
  Definition: Reviews Isabelle proofs, thy files, formal verification
  For document types: Code Fragment (thy), _____________________
  [ ] Needs to be defined
  [ ] Person/team: _______________________________________________

Security Team
PROJ_MGR
  Current: [Who?] _______________________________________________
  Definition: Reviews security-related documents
  For document types: Security Review, Incident Report, ________
  [ ] Needs to be defined
  [ ] Person/team: _______________________________________________

Other Approver Role: ____________________
  Definition: ____________________________________________________
  For document types: _____________________________________________
  Person/team: ____________________________________________________

Other Approver Role: ____________________
  Definition: ____________________________________________________
  For document types: _____________________________________________
  Person/team: ____________________________________________________
```

---

## Section 3: Submission & Approval Workflows

### 3.1 How Should Each Type Be Submitted?

For each document type, select submission method:

```
Method Options:
  A = GitHub Issue (with template)
  B = GitHub PR (direct to in_basket)
  C = Web Form (custom interface)
  D = Email (auto-creates issue)
  E = Filesystem (direct git push)
  F = Mixed (depends on sub-type)
  G = Other
  regardless of doc type we use GitHub Actions & workflows and with PR's and templates/forms
  
  email will never generate documentation Filesystem stuff is always a producer for the in_basket
  
  This is true for ALL document types
  
Document Type               Submission Method    Why?
_________________________  [ ] A [ ] B [ ] C [ ] D [ ] E [ ] F [ ] G   _________
_________________________  [ ] A [ ] B [ ] C [ ] D [ ] E [ ] F [ ] G   _________
_________________________  [ ] A [ ] B [ ] C [ ] D [ ] E [ ] F [ ] G   _________
_________________________  [ ] A [ ] B [ ] C [ ] D [ ] E [ ] F [ ] G   _________
_________________________  [ ] A [ ] B [ ] C [ ] D [ ] E [ ] F [ ] G   _________
_________________________  [ ] A [ ] B [ ] C [ ] D [ ] E [ ] F [ ] G   _________
_________________________  [ ] A [ ] B [ ] C [ ] D [ ] E [ ] F [ ] G   _________
_________________________  [ ] A [ ] B [ ] C [ ] D [ ] E [ ] F [ ] G   _________
```

---

### 3.2 Approval Format & Signatures

For documents requiring approval, how should approvals be recorded?

```
Current FMEA Format:
  ✅ APPROVED
  Stakeholder: [Name]
  Role: [Title]
  Date: [Date]
  Notes: [Optional conditions]

Should we use this format for all approvals?
  [X] YES - Consistent across all types
  [ ] NO - Different format for different types

If NO, what formats are needed?

For Engineering Research:
  [ ] Same as FMEA
  [ ] Different format:
  _________________________________________________________________

For Code Fragments (thy files):
  [ ] Same as FMEA
  [ ] Different format:
  _________________________________________________________________

For other types:
  [ ] Same as FMEA
  [ ] Different format:
  _________________________________________________________________

E-Signature Requirements:

  Which documents need digital signatures? Anything that is in the inbox that is bound for any directory in the [VAULT] except for Reference material will eventually end up in a controlled & signed. That will hapen later in the in_basket processing., Not needed here.
  _________________________________________________________________
  _________________________________________________________________

  How should digital signatures be captured?
  [X] GitHub commit signatures (GPG signing)
  [ ] External e-signature service (DocuSign, etc.)
  [X] Metadata field in document
  [ ] Physical signatures (scanned/attached)
  [X] Mixed approach:
  _________________________________________________________________

  Who is responsible for collecting signatures? Automated notifications LATER
  _________________________________________________________________

  Timeline for signature collection:
  [ ] Must be done before vault routing
  [ ] Can be done after vault routing
  [ ] Depends on document type:
  LATER
  _________________________________________________________________
```

---

## Section 4: Vault Organization & Structure

### 4.1 How Should in_basket Be Organized?

Which structure makes most sense?
TBD in_basket flat You don't have worry about that part. a LATER process will deal with the in_basket.
```

OPTION A: Flat (current approach)
  in_basket/
  ├── fmea-###.md
  ├── protocol-YYYY-###.md
  ├── report-YYYY-###.md
  └── logo-update-YYYY-MM-DD.md
You are spending time on things that will be done later.

This process only needs to toss it in the in_basket and forget it.
  Pros: ___________________________________________________________
  Cons: ___________________________________________________________

OPTION B: By Document Type (hierarchical)
  in_basket/
  ├── fmea/
  ├── engineering-research/
  │   ├── protocol/
  │   ├── results/
  │   └── report/
  ├── design/
  │   ├── drawings/
  │   └── specifications/
  └── administrative/

  Pros: ___________________________________________________________
  Cons: ___________________________________________________________

OPTION C: By Date (temporal)
  in_basket/
  ├── 2025-11/
  │   ├── fmea-###.md
  │   ├── protocol-YYYY-###.md
  │   └── logo-update.md
  └── 2025-12/

  Pros: ___________________________________________________________
  Cons: ___________________________________________________________

OPTION D: Mixed (combination of above)
  in_basket/
  ├── 2025-11/
  │   ├── fmea/
  │   ├── research/
  │   └── admin/

  Pros: ___________________________________________________________
  Cons: ___________________________________________________________

YOUR CHOICE:
  [ ] Option A - Flat
  [ ] Option B - By Type
  [ ] Option C - By Date
  [ ] Option D - Mixed
  [ ] Other:
  _________________________________________________________________

If hierarchical, list the folder structure:

in_basket/
├── [Category 1]/
│   ├── [Subcategory]/
│   └── [Subcategory]/
├── [Category 2]/
│   └── [Subcategory]/
└── [Category 3]/

Actual Structure:
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

### 4.2 File Naming Conventions

How should files be named in vault?
Don't worry about the [VAULT] a LATER process will handle this
```
Current Examples:
  - fmea-###.md (issue number)
  - protocol-YYYY-###.md (year + sequence)
  - logo-update-YYYY-MM-DD.md (date)

Naming Convention by Type:

CAPA:
  [ ] capa-###.md
  [ ] capa-YYYY-###.md
  [ ] Other: ____________________________________________________

FMEA:
  [ ] fmea-###.md
  [ ] fmea-YYYY-###.md
  [ ] Other: ____________________________________________________

Engineering Protocol:
  [ ] protocol-YYYY-###.md
  [ ] engineering-protocol-[title].md
  [ ] Other: ____________________________________________________

Code Fragment (thy file):
  [ ] code-YYYY-###-[component].thy
  [ ] proof-[component]-YYYY-###.md
  [ ] Other: ____________________________________________________

Engineering Drawings:
  [ ] drawing-[component]-YYYY-###.adoc
  [ ] spec-[component]-v##.md
  [ ] Other: ____________________________________________________

Other Types:
  Type: __________________________
    Naming: ________________________________________________________

  Type: __________________________
    Naming: ________________________________________________________
```

---

## Section 5: Backlog vs. Vault Routing Logic

### 5.1 When Does a Document Go to Backlog (Not Vault)?

```
You said: "I don't want anything to get into the backlog without
justification of some sort."

For items that DO go to backlog, what justification is required?

Current backlog items:
  - CAPA: Defect that needs fixing
  - ECR: Feature request that needs decision
  - ECO: Approved feature ready for implementation
  - FMEA: Risk analysis (blocking, not implementation)

Question: Should FMEA ever go to backlog, or always vault?
  [X] FMEA always goes vault (never backlog)
  [ ] FMEA can go to backlog if: __________________________________

For future document types, what decides: Backlog or Vault?

  [X] RULE 1: "Does it require code/implementation work?"
      YES → Backlog
      NO → Vault

  [X] RULE 2: "Will developers be assigned or pick from backlog to do this?"
      YES → Backlog
      NO → Vault

  [X] RULE 3: "Is this a change request or a reference document?"
      Change request → Backlog
      Reference → Vault

  [X] RULE 4: "Does this create work, or document existing work?"
      Creates work → Backlog
      Documents work → Vault

  [ ] OTHER RULE:
      _________________________________________________________________
      _________________________________________________________________

Are there any document types that COULD go either way?
  Type: Probably PM routes
    Decision factor: __________________________________________________
    If [condition] → Backlog
    If [condition] → Vault

  Type: ____________________________
    Decision factor: __________________________________________________
    If [condition] → Backlog
    If [condition] → Vault
```

---

### 5.2 How Does FMEA Interact With Backlog?

```
Current FMEA Flow:
  FMEA created → Parent issue blocked → Stakeholders approve
  → Parent unblocked → FMEA goes to vault

Questions:

1. Can a FMEA analysis result in changes that DO go to backlog?
   Example: "FMEA identifies missing test coverage → Create ECO
            for test development"

   [ ] NO - FMEA is always vault-only, never creates backlog work
   [X] YES - FMEA can spawn backlog items if analysis recommends them

   If YES, what's the trigger?
   _________________________________________________________________

2. Should the spawned backlog item (ECO) reference the FMEA?
   [X] YES - ECO links to FMEA in "Related Documents" field
   [ ] NO - ECO stands alone
   [ ] MAYBE - Depends on severity: ______________________________

3. Engineering Research that spawns development work:
   Example: Protocol + Experiment → proves feasibility → ECR for feature

   [ ] Research goes vault → spawn ECR separately
   [X] Research + ECR are linked documents
   [ ] Other: ____________________________________________________
```

---

## Section 6: Direct-to-Vault Pathway

### 6.1 Simple Documents That Skip Backlog

For documents that don't require backlog entry, what's the flow?
ALL documents going to the [VAULT] need QUAL_MGR or PROJ_MGR approval
```
Example: Logo Update
  Submitted → [Quick Review?] → Vault → Done

Example: Configuration Change
  Submitted → [SME Review? revalidation] → Vault → Done

Example: Meeting Minutes
  Submitted → [No Review?] → Vault → Done

For each document type, what's the flow?

Document Type: ______________________________
  Submitted → [ ] No review needed → Vault
  Submitted → [ ] Quick review (pass/fail) → Vault
  Submitted → [ ] Approval required → Vault
  Submitted → [ ] Other: ___________________________________________

Document Type: ______________________________
  Submitted → [ ] No review needed → Vault
  Submitted → [ ] Quick review (pass/fail) → Vault
  Submitted → [ ] Approval required → Vault
  Submitted → [ ] Other: ___________________________________________

Document Type: ______________________________
  Submitted → [ ] No review needed → Vault
  Submitted → [ ] Quick review (pass/fail) → Vault
  Submitted → [ ] Approval required → Vault
  Submitted → [ ] Other: ___________________________________________

Document Type: ______________________________
  Submitted → [ ] No review needed → Vault
  Submitted → [ ] Quick review (pass/fail) → Vault
  Submitted → [ ] Approval required → Vault
  Submitted → [ ] Other: ___________________________________________
```

---

### 6.2 Who Routes Documents to Vault?

```
Current: QA Lead manually routes approved documents to in_basket

Question: Should QA Lead always route, or different people per type?

  [X] QA Lead routes everything for now. delegates may be added at a later time.
  
  
  [ ] Different routing authority per type:
      Type: ______________________ → Routed by: __________________
      Type: ______________________ → Routed by: __________________
      Type: ______________________ → Routed by: __________________

Should routing be automated (Jenkins "mail-sorter" pipeline)?
Not in scope
  [ ] YES - Automate everything
  [ ] PARTIAL - Automate certain types:
      Which types? ___________________________________________________
  [ ] NO - Always manual (human gate)
  [ ] HYBRID - Approval automatic, but human confirms before vault:
```

---

## Section 7: Code Fragments & Engineering Research

### 7.1 Code Fragment Submission (thy files)

Special handling for proof files and code snippets:

```
Example scenario:
  Engineer writes: "Here's a proof sketch that component X is correct"

  Document should contain:
  [X] The actual thy file code (inline, in code block)
  [X] Link to the actual file (from git repo, with commit hash)
  [X] Link to the proof in Isabelle version control
  [X] Explanation/context
  [X] Formal Methods expert approval
  [X] All of above
  [ ] Other: ____________________________________________________

When referencing "thy file as it's in use":

  Format preference:
  [ ] Just the file link: [proof.thy @ abc1234](github.com/...)
  [ ] Inline code + link:
      ```thy
      [code]
      ```
      Source: [proof.thy @ abc1234](github.com/...)
  [X] Embedded with line numbers + link
  [ ] Other: ____________________________________________________

Should the code be version-locked (commit hash) in vault document?
  [X] YES - Always include commit hash so proof is auditable
  [ ] NO - Just link to current file
  [ ] BOTH - Show hash but also latest version link
```

---

### 7.2 Engineering Research Documents

Protocol, Results, Final Report - should they be:

```
Submission Method:
  [X] Single GitHub issue with all 3 sections
  [ ] 3 separate GitHub issues (Protocol, Results, Report)
  [ ] Mixed (depends on size/complexity)

Relationships:
  Results should reference Protocol:
    [X] YES - Link to protocol issue/document
    [ ] NO - Can be independent

  Report should reference both:
    [X] YES - Link to protocol + results
    [ ] NO - Can be independent summary

Out of scope
Vault Organization:
  [ ] All in single document
  [ ] Separate documents linked together
  [ ] Folder structure:
      research-###/
      ├── protocol.md
      ├── results.md
      └── report.md

Approval Workflow:
  [X] Protocol → Approval → Results → Approval → Report → Approval
  [ ] All three together at end: Protocol + Results + Report → Approval
  [ ] Custom: ____________________________________________________
```

---

## Section 8: Edge Cases & Special Scenarios

### 8.1 FMEA-Driven Research

```
Scenario: FMEA uncovers risk that requires experimental validation

Flow:
  FMEA created → Research needed → Engineering Protocol + Experiment
  → Report validates/refutes risk → FMEA updated → Parent decision

Your approach:
  [X] Research stands alone in vault, FMEA references it
  [X] FMEA links to research before unblocking parent
  [X] Research is attachment to FMEA issue
  [ ] Other: ____________________________________________________

If research results in "we need to build this":
  [X] Spawn new ECR from research report
  [ ] Update original parent issue with ECO
  [ ] Other: ____________________________________________________
```

---

### 8.2 Related Documents

```
Some documents will be related:
  - ECR can spawn ECO
  - ECO can spawn CAPA during implementation
  - CAPA might need FMEA
  - FMEA might spawn Research
  - Research might spawn ECR

Should vault documents link to related items?

  [X] YES - Each vault document has "Related Documents" section
  [ ] NO - Related items are historical, vault docs stand alone
  [ ] MAYBE - Only for certain types: ____________________________

If YES, format for links:
  [ ] GitHub issue link (even if closed)
  [ ] Vault document link
  [X] Both
  [ ] Other: ____________________________________________________
```

---

### 8.3 Large/Complex Documents

```
Some submissions might be large (100+ page engineering report,
technical specification with drawings, etc.)

Should we split into parts?
  [ ] YES - Maximum document size: ________ pages/KB
  [X] NO - Accept any size
  [ ] DEPENDS - On type: ____________________________________________

Attachment handling:
  [ ] Keep all in single file (markdown with embedded images)
  [X] Link to external (CONTROLLED or REF) files (drawings, spreadsheets, etc.)
  [ ] Separate folder: document.md + attachments/
  [ ] Other: ____________________________________________________
```

---

## Section 9: Implementation Priorities

### 9.1 Which Types Should Be Implemented First?
All TBD Escalation out of scope
```
Phase 1 (Immediate, this week):
  Priority 1 Types:
  _________________________________________________________________
  _________________________________________________________________

Phase 2 (Next week):
  Priority 2 Types:
  _________________________________________________________________
  _________________________________________________________________

Phase 3 (Future):
  Priority 3 Types:
  _________________________________________________________________
  _________________________________________________________________

Phase 4 (Nice to Have):
  Priority 4 Types:
  _________________________________________________________________
  _________________________________________________________________
```

---

### 9.2 What's the MVP (Minimum Viable Product)?

```
To make this system useful, what's the absolute minimum?

Must Have:
  [X] Engineering Research (Protocol, Report)
  [X] Code Fragments (thy files)
  [X] Design Documents
  [X] Incident Reports
  [X] Other: anything destine for the [VAULT] Regulated or unregulated ref material

Nice to Have:
  [X] Logo/Brand Updates
  [X] Configuration Documentation
  [X] Meeting Minutes
  [ ] Other: See above

Can Wait:
  [X] All the above are MVP
  [ ] Some can wait until later: Nope
```

---

## Section 10: Questions & Notes for Me

```
Anything I didn't ask about? Questions about the governance system?
Clarifications needed? Write them here:

_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
_________________________________________________________________
```

---

## Summary Section (For Your Reference)

Once you fill this out, I'll create:

1. **GOVERNANCE_DOCUMENT_TYPE_SPEC.md** - Formal specification
2. **Workflow designs** for each document type + submission pathway
3. **GitHub issue templates** for non-backlog document types
4. **GitHub workflows** for validation and routing
5. **Vault organization** structure in StarForth-Governance
6. **Implementation plan** with estimated effort for each phase

The completed questionnaire becomes the source of truth for Phase 3 implementation.

---

**When you're done**: Save as filled-in markdown and let me know. I'll process and come back with implementation recommendations.