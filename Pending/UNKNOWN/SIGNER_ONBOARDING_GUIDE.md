# Signer Onboarding Guide

**Version:** 1.0
**Last Updated:** 2025-11-03
**Audience:** All authorized document signers
**Authority:** PM (rajames440)

Welcome to the StarForth-Governance signing workflow! This guide walks you through everything you need to know as an authorized signer.

---

## Table of Contents

1. [Overview](#overview)
2. [Your Role](#your-role)
3. [GPG Key Setup](#gpg-key-setup)
4. [Signing Documents](#signing-documents)
5. [The Workflow](#the-workflow)
6. [Timeline & Escalation](#timeline--escalation)
7. [Frequently Asked Questions](#frequently-asked-questions)
8. [Troubleshooting](#troubleshooting)

---

## Overview

The StarForth-Governance project uses **digital signatures** to ensure that critical documents are reviewed and approved by authorized team members. Your signature mathematically proves that you reviewed and approved a specific version of a document.

### Why Digital Signatures?

- **Proof of Review:** Your signature proves you reviewed the document
- **Integrity Verification:** Proves the document hasn't been modified since you signed it
- **Audit Trail:** Creates a permanent record for compliance and audits
- **Non-Repudiation:** You cannot deny having signed the document

### How It Works (High Level)

```
1. PM submits document to Pending/
   ↓
2. You receive notification to sign
   ↓
3. You review the document
   ↓
4. You sign with your GPG key
   ↓
5. Pipeline verifies your signature
   ↓
6. Document moves to vault when all signatures collected
```

---

## Your Role

### Find Your Authority Level

Check the **Authorized Signers Registry** (`Security/Signatures.adoc`) to find your role:

| Role | Example Documents | Responsibility |
|------|-------------------|-----------------|
| **OWNER** | All documents | Final approval authority, can override incomplete signatures |
| **ENGINEERING** | ECR, ECO, DWG, ENG | Technical review and approval |
| **QA_LEAD** | CAPA, FMEA, VAL, DTA | Quality assurance and testing approval |
| **SECURITY** | SEC, FMEA, ECR | Security review and approval |
| **COMPLIANCE** | CAPA, DHR, DMR, VAL | Regulatory compliance verification |
| **INCIDENT_MANAGER** | IR, CER, FMEA | Incident and risk approval |

### Your Document Types

Find your username in `Security/Signatures.adoc` to see which document types you're authorized to sign.

**Example:**
```
eng-manager (Engineering Manager)
Authority Level: ENGINEERING
Authorized for: ECR, ECO, FMEA, DWG, ENG, VAL, DTA
```

---

## GPG Key Setup

### Prerequisites

- Linux/macOS with GPG installed, OR Windows with Git Bash
- Email address for your key

### Step 1: Check if You Already Have a Key

```bash
gpg --list-keys
```

**If you see your key listed:** Skip to [Step 3: Share Your Public Key](#step-3-share-your-public-key)

**If you see no keys:** Continue to Step 2

### Step 2: Generate Your GPG Key

```bash
gpg --gen-key
```

You'll be prompted for:

1. **Key Type:** Select `RSA and RSA` (default)
2. **Key Size:** Select `4096` bits (more secure)
3. **Expiration:** Select `3y` (3 years)
4. **Real Name:** Your name (e.g., `Engineering Manager`)
5. **Email:** Your email (e.g., `eng@starforth.dev`)
6. **Passphrase:** Create a strong passphrase
   - ✅ At least 12 characters
   - ✅ Mix of uppercase, lowercase, numbers, symbols
   - ✅ Don't use your password
   - ✅ Write it down somewhere secure

**Example:**
```
Real Name: Engineering Manager
Email: eng@starforth.dev
Passphrase: MySecureP@ssPhrase123!
```

### Step 3: Share Your Public Key

Your public key needs to be shared with Jenkins so it can be imported. Do NOT share your private key.

**Option A: Share via Repository** (Preferred)

```bash
# Export your public key in armor format
gpg --export --armor eng-manager@starforth.dev > eng-manager-public.asc

# Share the file with the PM (rajames440) via:
# - Email
# - GitHub issue (attach the .asc file)
# - Slack DM
```

**Option B: Share via Key Server**

```bash
# Find your key ID
gpg --list-keys

# Example output:
# pub   rsa4096 2025-11-03 [SC]
#       ABCDEF1234567890ABCDEF1234567890ABCDEF12
# uid           [ unknown] eng-manager <eng@starforth.dev>

# Upload to key server
gpg --keyserver hkps://keys.openpgp.org --send-key ABCDEF1234567890ABCDEF1234567890ABCDEF12
```

### Step 4: Verify Your Setup

Test that your key works:

```bash
# Create a test file
echo "This is a test" > test.txt

# Sign it
gpg --detach-sign --armor test.txt

# This creates: test.txt.asc

# Verify the signature
gpg --verify test.txt.asc test.txt

# You should see:
# gpg: Signature made [date] [time]
# gpg: Good signature from "Your Name <your@email.com>"
```

If you see "Good signature," you're ready to sign documents!

---

## Signing Documents

### Step 1: Get Notified

When a document needs your signature, you'll receive a **GitHub notification** with:
- Document name
- Document type
- Link to the document
- Deadline (usually 3 days)

### Step 2: Review the Document

1. Go to the Pending directory on GitHub or clone the repo
2. Find your document: `Pending/[TYPE]/[DOCUMENT_NAME].adoc`
3. Read the document carefully
4. Ask questions if anything is unclear

**Example path:**
```
Pending/CAPA/CAPA-001.adoc
```

### Step 3: Create Your Signature

Once you've reviewed and approved the document:

**Method A: Using Command Line** (Recommended)

```bash
# Navigate to the document directory
cd StarForth-Governance/Pending/CAPA/

# Create a detached signature
gpg --detach-sign --armor CAPA-001.adoc

# This creates: CAPA-001.adoc.asc

# Rename to match expected format (if needed)
# Format: [DOCUMENT_NAME].[YOUR_USERNAME].asc
# Example: CAPA-001.adoc.rajames440.asc
```

**Method B: Using GitHub Web Interface**

If you prefer not to use command line:
1. Fork the repository
2. Navigate to `Pending/[TYPE]/`
3. Create a new file: `[DOCUMENT_NAME].[USERNAME].asc`
4. Copy-paste your signature file contents
5. Create a pull request

### Step 4: Commit Your Signature

Add your signature file to the repository:

```bash
# From StarForth-Governance/ directory
git add Pending/CAPA/CAPA-001.rajames440.asc
git commit -m "docs(signature): Add signature from rajames440 for CAPA-001"
git push origin master
```

Or create a pull request if you prefer.

### Step 5: Verify

The pipeline will automatically:
1. Detect your signature file
2. Verify your signature cryptographically
3. Update the document's signature table
4. Notify other signers of progress

You'll see the status change from "Pending" to "Signed ✓" in the document.

---

## The Workflow

### Document States

```
1. in_basket/
   ↓ (PM routes)

2. Pending/[TYPE]/
   - Notification sent to signers
   - Signature collection begins
   ↓ (Signers sign)

3. Pending/[TYPE]/ (with signatures)
   - All signatures collected OR PM overrides
   ↓ (PM routes)

4. Vault/[TYPE]/
   - Document archived
   - Process complete
```

### Your Involvement

**Phase 1: You're Notified**
- Receive GitHub notification
- 3 days to review and sign
- No action needed yet (just read the notification)

**Phase 2: You Sign**
- Review the document (usually 1-2 hours)
- Create your signature (5 minutes)
- Push/commit your signature
- ~Done!

**Phase 3: Automation**
- Pipeline verifies your signature
- Updates document with your info
- Notifies other signers of your approval

**Phase 4: Document Archived**
- When all signatures collected
- Document moves to vault
- You can see the final, signed version

---

## Timeline & Escalation

### Standard Timeline

| Time | Action | Who | Notes |
|------|--------|-----|-------|
| Day 0 | Document submitted | PM | You get notification |
| Day 0-3 | Review & sign | You | 3-day window |
| Day 1 | Reminder notification | Pipeline | If you haven't signed |
| Day 3 | Escalation to PM | Pipeline | If you still haven't signed |
| Day 3+ | PM override | PM | PM can force completion |

### What Happens if You Don't Sign?

**Day 1:** You receive a reminder notification

**Day 3:**
- PM receives escalation notice
- PM can either:
  - Give you more time (emails you directly)
  - Override your signature (if urgent)
  - Cancel the document

**Important:** This is not punitive! Sometimes you're on vacation, busy, or didn't see the notification. The escalation just ensures documents don't get stuck.

### How to Communicate

If you need more time:
- Reply to the GitHub notification comment
- Mention the PM: `@rajames440 Need 2 more days`
- Send a direct message to PM

---

## Frequently Asked Questions

### "What if I made a mistake in signing?"

You can sign the same document again. The pipeline will use the most recent valid signature.

```bash
# Sign again after reviewing your changes
gpg --detach-sign --armor CAPA-001.adoc
# Overwrites the old signature file
git commit -m "docs(signature): Update signature from rajames440 for CAPA-001"
git push origin master
```

### "Can I sign someone else's document?"

No, only authorized signers can sign documents in their role. The pipeline will reject signatures from unauthorized users.

### "What if the document is wrong?"

Reject it! Reply to the GitHub notification:
- Mention the PM: `@rajames440 This document has errors in section 3`
- Don't sign it
- The PM can route it back for revision

### "I lost my passphrase. What do I do?"

Contact the PM. Your old key cannot be used anymore (for security). You'll need to generate a new key.

### "What's the difference between signing and approving?"

They're the same! Your signature **is** your approval. Once you sign, you're officially approving the document.

### "Can I revoke my signature?"

Not automatically, but you can notify the PM. In most cases, you'd need to sign again after document revisions.

### "What document types can I sign?"

Check the Authorized Signers Registry in `Security/Signatures.adoc`. Look up your username to see your authority level and authorized document types.

---

## Troubleshooting

### Problem: "gpg: command not found"

**Solution:** Install GPG
```bash
# macOS
brew install gpg

# Ubuntu/Debian
sudo apt-get install gnupg

# Windows
# Download from: https://gnupg.org/download/
```

### Problem: "No public key" error during signature

**Cause:** Your public key hasn't been imported into Jenkins yet

**Solution:**
1. Export your public key: `gpg --export --armor your@email.com > your-public.asc`
2. Send to PM (rajames440)
3. PM imports it on Jenkins agents
4. Try signing again

### Problem: Signature verification fails

**Cause:** Usually means the document was modified after signing

**Solution:**
1. Don't modify the document - review it as-is
2. If the document needs changes, PM will route it back for revision
3. Sign only the final version

### Problem: "Bad signature" error

**Cause:** Usually a file transfer issue or corrupted signature file

**Solution:**
1. Delete the `.asc` file
2. Create a fresh signature: `gpg --detach-sign --armor [document]`
3. Re-commit and push

### Problem: "Bad passphrase" error

**Cause:** You typed your passphrase wrong

**Solution:**
- Try again with correct passphrase
- Make sure CAPS LOCK is off
- If you forget it, you'll need to generate a new key

### Problem: Can't find my document in Pending/

**Cause:** Document might not be routed yet, or you might not be an authorized signer

**Solution:**
1. Check GitHub notifications - has PM sent it yet?
2. Check your authority level in `Security/Signatures.adoc`
3. If it's there but not your doc type, you're not authorized
4. Contact PM if you think this is a mistake

### Problem: GitHub notification says my username but I didn't get it

**Cause:** GitHub notifications might be disabled, or you're not on the team

**Solution:**
1. Check GitHub Settings → Notifications
2. Make sure "Watch" is enabled for StarForth-Governance repo
3. Contact PM to add you to the team

---

## Getting Help

If you get stuck:

1. **Check this guide** - Most common issues are here
2. **Check `Security/Signatures.adoc`** - For your role and doc types
3. **Contact the PM** - `@rajames440` on GitHub or direct message
4. **Ask in the GitHub issue** - Other signers might have faced the same problem

---

## Quick Reference Card

**Your first time signing:**

```bash
# 1. Generate key (one-time)
gpg --gen-key
# → Follow prompts, save your passphrase

# 2. Export public key (one-time)
gpg --export --armor your@email.com > your-public.asc
# → Send to PM

# 3. When you get a notification to sign:
cd StarForth-Governance/Pending/[TYPE]/

# 4. Create signature
gpg --detach-sign --armor [DOCUMENT_NAME].adoc

# 5. Commit and push
git add [DOCUMENT_NAME].[USERNAME].asc
git commit -m "docs(signature): Add signature from [USERNAME] for [DOCUMENT_NAME]"
git push origin master

# Done! Pipeline handles the rest.
```

---

## What's Next?

Once you're set up:
1. ✅ GPG key generated and passphrase saved
2. ✅ Public key shared with PM
3. ✅ Watched the StarForth-Governance repository on GitHub
4. ✅ Ready to sign documents when notifications arrive

You'll be contacted when there's a document to sign. No action needed from you right now!

---

**Questions?** Contact Rajames (PM) at rajames@starforth.dev or `@rajames440` on GitHub

**Last Updated:** 2025-11-03
**Version:** 1.0
== Signatures

|===
| Signer | Status | Date | Signature

| rajames440 | Pending |  |
|===
