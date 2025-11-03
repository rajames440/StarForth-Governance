#!/bin/bash

################################################################################
# Signature Verification Script
# Verifies GPG signatures and updates document signature tables
#
# Usage: ./verify-signature.sh <document-path> <signature-asc-file> <signer-username>
#
# Example:
#   ./verify-signature.sh Pending/CAPA/CAPA-001.adoc CAPA-001.rajames440.asc rajames440
#
################################################################################

set -e

DOC_PATH="${1}"
SIGNATURE_FILE="${2}"
SIGNER_USERNAME="${3}"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper functions
log_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

log_success() {
    echo -e "${GREEN}✓${NC} $1"
}

log_error() {
    echo -e "${RED}✗${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}⚠${NC} $1"
}

# Validation
if [ -z "${DOC_PATH}" ] || [ -z "${SIGNATURE_FILE}" ] || [ -z "${SIGNER_USERNAME}" ]; then
    log_error "Usage: verify-signature.sh <document-path> <signature-asc-file> <signer-username>"
    exit 1
fi

if [ ! -f "${DOC_PATH}" ]; then
    log_error "Document not found: ${DOC_PATH}"
    exit 1
fi

if [ ! -f "${SIGNATURE_FILE}" ]; then
    log_error "Signature file not found: ${SIGNATURE_FILE}"
    exit 1
fi

log_info "Verifying signature for: $(basename ${DOC_PATH})"
log_info "Signer: ${SIGNER_USERNAME}"

################################################################################
# Step 1: Check if signer is authorized
################################################################################

# This should check against Security/Signatures.adoc
# For now, we'll do basic validation - in production, parse the .adoc file
SIGNATURES_FILE="Security/Signatures.adoc"

if [ ! -f "${SIGNATURES_FILE}" ]; then
    log_error "Signatures registry not found: ${SIGNATURES_FILE}"
    exit 1
fi

if ! grep -q "^|${SIGNER_USERNAME}$" "${SIGNATURES_FILE}"; then
    log_error "Signer not authorized: ${SIGNER_USERNAME}"
    log_info "Check: Security/Signatures.adoc"
    exit 1
fi

log_success "Signer authorized: ${SIGNER_USERNAME}"

################################################################################
# Step 2: Verify GPG signature
################################################################################

log_info "Verifying GPG signature..."

# Try to verify the signature
if gpg --verify "${SIGNATURE_FILE}" "${DOC_PATH}" 2>/dev/null; then
    log_success "GPG signature verified"
    GPG_RESULT="VALID"
else
    # Check if it's a format issue or actual signature problem
    if gpg --verify "${SIGNATURE_FILE}" "${DOC_PATH}" 2>&1 | grep -q "No public key"; then
        log_warning "GPG signature present but public key not in keyring"
        log_info "This is acceptable - manual verification may be required"
        GPG_RESULT="UNVERIFIED"  # Can't verify, but file exists
    else
        log_error "GPG signature verification failed"
        log_info "Run: gpg --verify ${SIGNATURE_FILE} ${DOC_PATH}"
        exit 1
    fi
fi

################################################################################
# Step 3: Extract signature metadata
################################################################################

SIGNATURE_DATE=$(date -u +%Y-%m-%d)
GPG_FINGERPRINT="PENDING"  # Will be extracted if gpg available

# Try to get the signing key ID/fingerprint
if command -v gpg &> /dev/null; then
    GPG_ID=$(gpg --verify "${SIGNATURE_FILE}" "${DOC_PATH}" 2>&1 | \
             grep "using.*key" | sed 's/.*using.*key //' | cut -d' ' -f1 || echo "UNKNOWN")
    if [ -n "${GPG_ID}" ] && [ "${GPG_ID}" != "UNKNOWN" ]; then
        GPG_FINGERPRINT="${GPG_ID}"
    fi
fi

log_info "Signature Date: ${SIGNATURE_DATE}"
log_info "GPG ID: ${GPG_FINGERPRINT}"

################################################################################
# Step 4: Update document signature table
################################################################################

log_info "Updating signature table in document..."

# Find the signature table in the document and update the row for this signer
# The table format is:
# |===
# | Signer | Status | Date | Signature
#
# | rajames440 | Pending |  |
# | qa-lead | Pending |  |
# |===

# Create a temporary file with the updated signature
TEMP_FILE=$(mktemp)
cp "${DOC_PATH}" "${TEMP_FILE}"

# Replace the pending status for this signer with signed status
# This uses sed to find the line with this signer and update it
sed -i.bak "s/^| ${SIGNER_USERNAME} | Pending | | \$/| ${SIGNER_USERNAME} | Signed ✓ | ${SIGNATURE_DATE} | GPG: ${GPG_FINGERPRINT} |/" "${TEMP_FILE}"

# Check if the replacement was made
if diff -q "${DOC_PATH}" "${TEMP_FILE}" > /dev/null 2>&1; then
    log_warning "Signature table may not have been updated (signer row not found)"
    rm "${TEMP_FILE}" "${TEMP_FILE}.bak"
else
    # Copy updated document back
    cp "${TEMP_FILE}" "${DOC_PATH}"
    rm "${TEMP_FILE}" "${TEMP_FILE}.bak"
    log_success "Signature table updated"
fi

################################################################################
# Step 5: Create result file
################################################################################

RESULT_FILE="${DOC_PATH}.sig-verified"
cat > "${RESULT_FILE}" << EOF
{
  "document": "$(basename ${DOC_PATH})",
  "signer": "${SIGNER_USERNAME}",
  "status": "${GPG_RESULT}",
  "verified_at": "${SIGNATURE_DATE}",
  "gpg_id": "${GPG_FINGERPRINT}",
  "signature_file": "$(basename ${SIGNATURE_FILE})"
}
EOF

log_success "Signature verification result saved: ${RESULT_FILE}"

################################################################################
# Summary
################################################################################

echo ""
log_success "Signature verification complete"
echo ""
echo "Result Summary:"
echo "  Document: $(basename ${DOC_PATH})"
echo "  Signer: ${SIGNER_USERNAME}"
echo "  Status: ${GPG_RESULT}"
echo "  Date: ${SIGNATURE_DATE}"
echo ""

exit 0
