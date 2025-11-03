# Foundation Training: StarForth Governance Overview

**Required for:** Everyone (all team members)
**Time:** ~30 minutes
**Prerequisites:** None

---

## What You Need to Know

### The Mailroom Model

StarForth governance works like a mailroom that handles change requests:

**MAILSLOT (StarForth Repository)**
- Anyone creates CAPA issues, PRs, documents
- Things move through states automatically
- Snapshots captured at each state transition

**MAILROOM (in_basket directory)**
- Temporary holding area for documents
- Everything arrives here first
- Waiting for intelligent sorting

**GATEKEEPER (Jenkins governance pipeline)**
- Processes documents from in_basket daily
- Routes them to permanent homes
- Archives and verifies immutability
- Alerts PM about exceptions

**PERMANENT VAULT (Reference/ directories)**
- Final, immutable archive
- Nothing ever deleted
- Everything preserved for audit
- Compliance-ready format

**PM (Ultimate Arbitrator)**
- Only intervenes when system can't decide
- Notified of exceptions, not routine items
- Makes judgment calls
- Enforces governance

---

## Core Principles

### 1. Immutability
**Once it's created, it never goes away.**

- Documents stored in git (can't delete without history visible)
- Vault contains complete history
- Checksums verify authenticity
- Snapshots captured at every state change
- Compliance-ready: nothing lost

### 2. Transparency
**Everything is visible to everyone.**

- All procedures documented in governance model
- Training materials available to all
- Audit trail complete and accessible
- No hidden rules or secret processes
- 100% openness

### 3. Auditability
**Every decision has a record.**

- Who approved what, when
- What changed and why
- GPG signatures prove authenticity
- Complete approval chain documented
- Ready for regulatory review

### 4. Automation First, Manual Fallback
**Machines do routine work, humans make judgment calls.**

- Kanban state transitions automated
- Snapshots captured automatically
- Vault processing automated (daily Jenkins)
- PM only called when system needs judgment
- Exceptions handled explicitly

### 5. Role-Based Responsibility
**You own your part of the process.**

- ENG_MGR approves ECRs and issues ECOs
- QUAL_MGR validates quality and approves gates
- PM approves releases and resolves exceptions
- Developers create CAPAs and code
- QA validates features
- Everyone accountable for their decisions

---

## Your Responsibilities

### Everyone's Job
1. **Understand the governance model** - Read your required training
2. **Follow the process** - Execute your procedures correctly
3. **Use GPG signatures** - Sign all governance documents
4. **Keep vault clean** - Put documents in right places
5. **Communicate changes** - Notify relevant people

### Your Team's Job
- Execute the procedures for your team
- Train new members on your team's procedures
- Maintain quality in your domain
- Escalate issues appropriately

### PM's Job
- Arbitrate exceptions
- Enforce governance
- Ensure compliance
- Remove blockers
- Make final decisions

---

## Key Terminology

**ECR (Engineering Change Request)**
- Anyone can create to propose changes
- Formal request with risk assessment
- Goes to ENG_MGR for review

**ECO (Engineering Change Order)**
- ENG_MGR's approval to proceed
- Authorizes implementation
- References ECR and any FMEA

**CAPA (Corrective/Preventive Action)**
- Issue created in GitHub
- Moves through states: CREATE → IMPLEMENT → VALIDATE → APPROVE → RELEASE → CLOSED
- Immutable snapshots at each state
- Links to ECR/ECO if needed

**FMEA (Failure Mode & Effects Analysis)**
- Team meeting for high-risk changes
- Identifies potential problems
- Defines mitigations
- All participants sign GPG
- Stored in vault

**Vault**
- Permanent archive in git
- Reference/Quality/CAPAs/, Reference/Processes/, etc.
- Nothing ever deleted
- Immutability verified

**in_basket**
- Temporary staging area
- Documents arrive here first
- Jenkins processes daily
- Archives to vault when complete

**GPG Signature**
- Cryptographic proof you created/approved something
- Can't be forged or modified
- Timestamp included
- Vault verification requires it

**Kanban Board**
- GitHub Project showing CAPA status
- 6 states: CREATE, IMPLEMENT, VALIDATE, APPROVE, RELEASE, CLOSED
- Status automatically updated
- Dashboard shows progress

---

## Roles & Authority

### Engineering Manager (ENG_MGR)
- Reviews ECRs for completeness
- Decides if FMEA needed (high-risk changes)
- Approves and creates ECOs
- Facilitates FMEA meetings
- Signs all ECR/ECO/FMEA approvals

### Quality Manager (QUAL_MGR)
- Runs qual gate tests
- Validates quality criteria
- Approves test→qual transition
- Can request FMEA at qual gate
- Facilitates FMEA if called

### Product Manager (PM)
- Approves qual→prod release
- Bumps version numbers
- Generates release artifacts
- Handles exceptions
- Final authority on governance

### Team Lead (TL)
- Coaches team on procedures
- Mentors new members
- Escalates blockers
- Responsible for team quality

### Developer
- Creates CAPAs and PRs
- Follows procedures
- Signs off on own work
- Communicates status changes

### QA/Test
- Validates features
- Writes tests
- Reviews results
- Reports quality issues

---

## When You Need to Do Something

**Creating a proposal?**
→ Use ECR if formal/risk review needed, CAPA issue if quick/simple

**Got ENG_MGR approval?**
→ They create ECO, you implement

**Need FMEA (high-risk)?**
→ ENG_MGR/QUAL_MGR facilitates team meeting

**Implementation ready?**
→ Create PR with "Closes #XYZ", request test approval

**Tests pass?**
→ QUAL_MGR reviews and approves test→qual

**Qual passes?**
→ PM reviews and approves qual→prod

**PM releases?**
→ Artifacts signed, version bumped, merged to master

**Done?**
→ Issue closed, Kanban shows CLOSED, snapshots archived

---

## Red Flags

**Stop and escalate if:**

- You're not sure which procedure applies
- A procedure is missing or unclear
- Someone bypasses the process
- Approval is requested without ECR/ECO
- Document can't be signed (GPG issue)
- Vault can't be accessed
- Jenkins can't process artifacts
- Someone wants to skip FMEA on high-risk change

→ **Escalate to PM**

---

## Comprehension Check

Read carefully. Answer YES or NO to each.

- [ ] **Do you understand that all changes require an ECR or CAPA issue?**
  - YES means: Every proposal starts with ECR or GitHub issue
  - NO means: Re-read "When You Need to Do Something"

- [ ] **Do you understand that ENG_MGR approves ECRs and issues ECOs?**
  - YES means: Developers don't approve their own work
  - NO means: Re-read "Roles & Authority"

- [ ] **Do you understand that vault documents are immutable?**
  - YES means: Once stored, nothing gets deleted
  - NO means: Re-read "Immutability" section

- [ ] **Do you understand that PM is the ultimate decision-maker?**
  - YES means: PM handles exceptions and escalations
  - NO means: Re-read "PM's Job"

- [ ] **Do you understand that GPG signatures prove you reviewed something?**
  - YES means: Your signature is legally binding, can't be undone
  - NO means: Re-read "Key Terminology"

**If any answer is NO:** Re-read the relevant section and check again.

---

## Acknowledgment

**I have read and understood the StarForth governance foundation.**

I acknowledge:
- The mailroom model (mailslot → mailroom → gatekeeper → vault → PM)
- Core principles (immutability, transparency, auditability, automation, roles)
- My responsibilities in the governance system
- The key roles and their authorities
- When to escalate issues

**Signature:**

Name: _____________________

Date: ______________________

GPG Signature: (signed document goes here)

---

**This acknowledgment is valid until the Foundation document revises.**

Once signed and vaulted, you're cleared to take governance training for your specific procedures and roles.

---

**Version:** 1.0
**Last Updated:** 2025-11-03
**Next Review:** When governance model updates