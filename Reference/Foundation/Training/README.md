# StarForth Governance Training System

**Purpose:** Every person using the governance model must understand and acknowledge the procedures they execute

**Model:** Read → Understand → Acknowledge (with GPG signature, valid until procedure revises)

**Status:** Training system ready for team deployment

---

## How This Works

### 1. Foundation Training (Everyone)
All team members must complete:
- **FOUNDATION-OVERVIEW.md** - Core governance principles
- Understand the mailroom model
- Understand roles and authority
- Understand immutability and vault

Takes ~30 minutes. One-time sign-off.

### 2. Procedure Training (Per Procedure You Execute)
When you join a project or take on a role, you must train on the procedures YOU execute:

**If you CREATE things:**
- TRAINING-ECR.md (anyone can create ECRs)
- TRAINING-CAPA.md (anyone can create CAPAs)

**If you REVIEW things:**
- TRAINING-ECO.md (ENG_MGR reviews ECRs → creates ECOs)
- TRAINING-FMEA.md (facilitators run FMEAs)
- TRAINING-QA_GATE.md (QUAL_MGR approves test→qual)
- TRAINING-PM_RELEASE.md (PM approves qual→prod)

**If you MANAGE infrastructure:**
- TRAINING-CI_CD.md (understanding pipeline)
- TRAINING-GITHUB.md (projects, workflows, commits)
- TRAINING-JENKINS.md (jobs, triggers, releases)
- TRAINING-BRANCH_PROTECTION.md (enforcement)

**If you GOVERN:**
- TRAINING-SIGNATORY_MATRIX.md (authority levels)

### 3. Role Training (If You Have a Special Role)
Only needed if you're assigned a governance role:
- TRAINING-ENG_MGR.md (if you're Engineering Manager)
- TRAINING-QUAL_MGR.md (if you're Quality Manager)
- TRAINING-PM.md (if you're Product Manager)
- TRAINING-TEAM_LEAD.md (if you lead a team)

Each role training summarizes ALL procedures for that role.

### 4. Team Training (If You Join a Team)
Depending on your team:
- TRAINING-NEW_FEATURE_DEV.md (new features team)
- TRAINING-BUG_FIX_TEAM.md (CAPA/bug fixes team)
- TRAINING-QUAL_TEAM.md (quality assurance team)
- TRAINING-RELEASE_TEAM.md (release management team)
- (others added as teams form)

Each team training covers the procedures that team executes.

### 5. Sign-Off & Registry
When you complete training:
1. Read the document
2. Answer comprehension check (must answer YES to all)
3. Sign with GPG: `gpg --clearsign TRAINING_SIGN_OFF.md`
4. Move to vault: `./scripts/vault-move.sh training TRAINING_SIGN_OFF-[name].md`
5. Registered in TRAINING_REGISTRY.md (master sign-off log)

**Sign-off is valid until the procedure revises.** When procedure docs update, you need retraining.

---

## Training Files

### Foundation
- `FOUNDATION-OVERVIEW.md` - Everyone starts here

### Procedures (11 total)
- `TRAINING-ECR.md` - Creating Engineering Change Requests
- `TRAINING-ECO.md` - Approving and issuing Engineering Change Orders
- `TRAINING-CAPA.md` - Creating and tracking CAPAs
- `TRAINING-FMEA.md` - Running Failure Mode & Effects Analysis
- `TRAINING-QA_GATE.md` - Quality approval gate (test→qual)
- `TRAINING-PM_RELEASE.md` - Release approval (qual→prod)
- `TRAINING-CI_CD.md` - Understanding CI/CD workflow
- `TRAINING-GITHUB.md` - GitHub projects, workflows, commits
- `TRAINING-JENKINS.md` - Jenkins pipeline and jobs
- `TRAINING-BRANCH_PROTECTION.md` - Branch protection rules
- `TRAINING-SIGNATORY_MATRIX.md` - Authority levels and sign-off rights

### Roles (4 total)
- `TRAINING-ENG_MGR.md` - Engineering Manager responsibilities
- `TRAINING-QUAL_MGR.md` - Quality Manager responsibilities
- `TRAINING-PM.md` - Product Manager responsibilities
- `TRAINING-TEAM_LEAD.md` - Team Lead responsibilities

### Teams (scalable)
- `TRAINING-NEW_FEATURE_DEV.md` - New Feature Development Team
- `TRAINING-BUG_FIX_TEAM.md` - Bug Fix / CAPA Team
- `TRAINING-QUAL_TEAM.md` - Quality Assurance Team
- `TRAINING-RELEASE_TEAM.md` - Release Management Team
- (Add more as teams form)

### Sign-Off & Registry
- `TRAINING_SIGN_OFF_TEMPLATE.md` - Template to copy
- `TRAINING_REGISTRY.md` - Master log of all sign-offs

---

## Quick Start: New Team Member

**First Day:**
1. Read `FOUNDATION-OVERVIEW.md` (~30 min)
2. Answer comprehension check
3. Sign off (GPG signature)

**Before Starting Work:**
1. Identify your TEAM(s) and ROLE(s)
2. Read all PROCEDURE trainings for your team/role
3. Read TEAM training (if applicable)
4. Read ROLE training (if applicable)
5. Sign off on each

**Example: New Developer on Bug Fix Team**
- FOUNDATION-OVERVIEW ✓
- TRAINING-CAPA ✓ (you'll create CAPAs)
- TRAINING-CI_CD ✓ (you'll use pipeline)
- TRAINING-GITHUB ✓ (you'll commit code)
- TRAINING-BUG_FIX_TEAM ✓ (your team's procedures)

**Total time:** ~2-3 hours for onboarding

---

## When Training is Required

- **New team member:** Before first action
- **New team assignment:** Before joining team
- **New role assignment:** Before taking role
- **Procedure updates:** When governance model revises (all affected roles retrain)
- **Annual refresh:** Optional, recommended every 12 months

---

## Comprehension Checks

Each training doc has a **Comprehension Check** section:
- 3-5 simple yes/no questions
- Tests understanding of KEY CONCEPTS
- Must answer YES to ALL to sign off
- If you answer NO to any, re-read that section

Example questions:
```
[ ] Do you understand that vault documents are immutable?
[ ] Do you understand YOUR role in this procedure?
[ ] Can you identify when you need ENG_MGR approval?
```

---

## Sign-Off Process

### Step 1: Copy Template
```bash
cp Training/TRAINING_SIGN_OFF_TEMPLATE.md \
   Training/TRAINING_SIGN_OFF-[your_name].md
```

### Step 2: Fill Out
```markdown
# Training Sign-Off

**Trainee:** John Developer
**Date:** 2025-11-03
**Foundation:** ✓ (read and understood)
**Procedures Completed:**
- ✓ TRAINING-CAPA
- ✓ TRAINING-CI_CD
- ✓ TRAINING-GITHUB

**Teams:**
- ✓ TRAINING-BUG_FIX_TEAM

**Roles:**
- (none)

## Comprehension Check Results
[All comprehension checks answered YES]

## Acknowledgment

I have read and understood the above training materials.
I acknowledge my responsibilities in the StarForth governance system.
```

### Step 3: Sign with GPG
```bash
gpg --clearsign Training/TRAINING_SIGN_OFF-john_developer.md
# Creates: TRAINING_SIGN_OFF-john_developer.md.asc
```

### Step 4: Move to Vault
```bash
source .env.governance
./scripts/vault-move.sh training TRAINING_SIGN_OFF-john_developer.md --verify-gpg

# Results:
# ✓ GPG signature verified
# ✓ Moved to: in_basket/Training/TRAINING_SIGN_OFF-john_developer.md
```

### Step 5: Register
Add to TRAINING_REGISTRY.md:
```
| John Developer | 2025-11-03 | Foundation ✓ | CAPA, CI_CD, GitHub ✓ | BUG_FIX_TEAM ✓ | None | v1.0 |
```

---

## Procedure Revision Process

**When a procedure document updates:**

1. Update the TRAINING-[procedure].md to match
2. Increment version number
3. All people trained on that procedure must retrain
4. Previous sign-offs become invalid
5. New sign-offs required before using updated procedure

**Example:**
- TRAINING-ECO.md v1.0 → v1.1 (procedure changed)
- ENG_MGR who signed off on v1.0 must retrain on v1.1
- Until retrained, cannot approve new ECOs
- (System can check: `TRAINING_REGISTRY.md` shows version signed)

---

## Training Registry

**File:** TRAINING_REGISTRY.md

Master log of all sign-offs:

```
| Trainee | Date | Foundation | Procedures | Teams | Roles | Version |
|---------|------|-----------|-----------|-------|-------|---------|
| Alice M | 2025-11-01 | v1.0 ✓ | ECR v1.0, ECO v1.0, CAPA v1.0 | ENG_MGR | v1.0 |
| Bob D | 2025-11-02 | v1.0 ✓ | CAPA v1.0, CI_CD v1.0, GitHub v1.0 | BUG_FIX | v1.0 |
| Carol Q | 2025-11-03 | v1.0 ✓ | FMEA v1.0, QA_GATE v1.0 | QUAL_TEAM | v1.0 |
```

**Used for:**
- Quick lookup: who has trained on what?
- Compliance: proof of training on file
- Updates: when procedure revises, flag who needs retraining
- Audit: complete training history

---

## Access & Locations

**Training files location:**
```
StarForth-Governance/in_basket/Training/
├── (all .md files)
└── TRAINING_REGISTRY.md
```

**Signed acknowledgments location:**
```
StarForth-Governance/in_basket/Training/
└── TRAINING_SIGN_OFF-[name].md (GPG signed)
```

**Vault location (after processing):**
```
StarForth-Governance/in_basket/Training/
└── [stored in vault, immutable]
```

---

## Questions & Support

- **Understanding a procedure?** Read TRAINING-[procedure].md
- **Don't understand your role?** Read TRAINING-[role].md
- **Don't understand your team's procedures?** Read TRAINING-[team].md
- **Can't find training material?** Check this README
- **Procedure changed?** Check TRAINING_REGISTRY.md for version

---

## Governance Principles Behind Training

✓ **Transparency:** Everyone sees all procedures upfront
✓ **Openness:** No hidden rules or secret processes
✓ **Accountability:** Your GPG signature proves you read and understood
✓ **Scalability:** Add new procedures, teams, roles as needed
✓ **Immutability:** Signed acknowledgments can't be changed
✓ **Audit Trail:** Complete record of who trained when
✓ **Compliance:** 100% coverage - if it's in governance, it has training

---

**Status: Ready for team deployment**

All training materials are in place. New team members can begin immediately.

---

**Version:** 1.0
**Last Updated:** 2025-11-03
**Maintained by:** Governance Team