# StarForth Governance Repository

**Component Validation Blueprint for FORTH-79 Standard Compliance**

This repository documents why **StarForth** can be defended as a standards-compliant, portable FORTH-79 virtual machine implementation in strict ANSI C99.

## Quick Facts

- **Component:** StarForth - FORTH-79 VM (core of StarshipOS)
- **Language:** ANSI C99 (strict, no external dependencies beyond optional libc)
- **Compliance:** FORTH-79 standard (full core words)
- **Test Suite:** 675+ functional tests
- **Portability:** Linux, L4Re/Fiasco.OC, seL4, embedded systems
- **License:** CC0 v1.0 (public domain)
- **Repository:** https://github.com/rajames440/StarForth

## Purpose

This governance repository establishes:

1. **Standards Compliance** - Proof that StarForth meets FORTH-79 specification
2. **Code Quality** - ANSI C99 strict compilation, no compromises
3. **Portability** - StarForth runs unchanged across multiple hypervisors
4. **Testing** - 675+ test suite validates all functionality
5. **Architecture** - Design decisions and rationale documented

## What This Repo Contains

- `FORTH-79_COMPLIANCE_MATRIX.adoc` - Standards compliance documentation
- `ANSI_C99_COMPLIANCE_MATRIX.adoc` - Language compliance proof
- `BUILD_AND_PORTABILITY_STANDARDS.adoc` - Build and portability validation
- `TEST_FRAMEWORK_AND_RESULTS.adoc` - Test harness documentation
- `ARCHITECTURE_DECISIONS.adoc` - Design decisions and rationale
- `PLATFORM_ABSTRACTION_LAYER.adoc` - Hypervisor independence layer
- `WORD_MODULE_INVENTORY.adoc` - All 19 modules documented
- `STANDARDS_AND_CERTIFICATION.adoc` - Certification approach
- `GOVERNANCE.md` - Repository governance and maintenance

## How StarForth Fits StarshipOS

StarForth is the **portable application/OS layer** that can run on:

1. **Phase 1 (NOW):** L4Re/Fiasco.OC (proven microkernel foundation)
2. **Phase 2 (COMING):** seL4 (formally verified microkernel)
3. **Phase 3 (FUTURE):** Hardware directly (StarForth as kernel)

This governance repo proves **StarForth's component-level correctness** independent of hypervisor. The StarshipOS governance repo handles **architecture and hypervisor integration** per phase.

## Key Defensibility Claims

✅ **StarForth is FORTH-79 standard compliant**
- Evidence: 675+ test suite with standard mapping
- Audit trail: Git history and test coverage

✅ **StarForth is strict ANSI C99**
- Evidence: Builds with `-std=c99 -Wall -Wextra -Werror`
- Validation: All platforms, all compilers

✅ **StarForth is portable across hypervisors**
- Evidence: Runs on Linux, L4Re, seL4, embedded
- Architecture: Platform abstraction layer

✅ **StarForth has zero external dependencies**
- Evidence: Standalone static binary
- Proof: No malloc, printf, or libc required

## For Siemens/Polarion

This repository demonstrates that **StarForth is a proven, defensible component** that can be used in increasingly verified hypervisor environments (L4Re → seL4 → none).

When evaluating StarshipOS for ALM support, note:

- **StarForth validation:** Complete today (standards compliance + testing)
- **StarForth portability:** Platform-independent layer proven
- **StarshipOS Phase 1:** Valid today (proven component + proven hypervisor)
- **StarshipOS Phase 2:** Requires ALM (adds novel physics algorithms to proven stack)

## Getting Started

1. Review `PHASE_ROADMAP.adoc` in the StarshipOS governance repo for overall strategy
2. Review this repo's documents for component-level validation
3. See StarForth repository for actual source code and tests

## License

Documentation: CC0 v1.0 (public domain)
StarForth source: CC0 v1.0 (public domain)

---

**StarForth:** The beating heart of StarshipOS. Proven. Portable. Perfect precision.