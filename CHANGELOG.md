# Changelog

All notable changes to claude-chroma will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [3.5.4] - 2025-09-28

### Security - Hardening Complete

**Registry**: jq-based updates, cross-platform locks (flock/lockf, mkdir fallback), atomic writes, 600 perms.

**MCP config**: absolute project data dir resolves at install time, with boundary checks.

**Docs**: end-to-end locking and atomic patterns, tests, and known limits.

#### Added
- Cross-platform file locking system (flock on Linux, lockf on macOS, mkdir fallback)
- Atomic JSONL operations with jq for all registry modifications
- CI stress testing for concurrent registry operations (10 parallel processes)
- Comprehensive security hardening documentation
- jq version checking with warnings for < 1.5
- Network filesystem compatibility notes for NFS/SMB users
- Strict file permissions (600) on all sensitive files

#### Changed
- Registry operations now use safe JSON manipulation instead of sed/regex
- .mcp.json uses absolute paths computed at install time (eliminates CWD fragility)
- Lock fallback timeout encoded in code with proper error handling
- Registry script includes umask 077 for strict permissions

#### Security
- **CRITICAL**: Eliminated registry corruption risk from concurrent operations
- **CRITICAL**: Fixed path portability issues in .mcp.json configuration
- **HIGH**: Added comprehensive input validation and boundary checks
- **MEDIUM**: Improved error handling and fallback safety

#### Fixed
- Race conditions in registry updates under concurrent access
- Working directory dependency in .mcp.json that broke IDE/launcher compatibility
- Infinite loops in mkdir-based lock fallback (now has 5-second timeout)
- Missing permission enforcement on temporary files

#### Infrastructure
- Added concurrent stress testing to CI pipeline
- Cross-platform permission validation in CI (Linux and macOS)
- Comprehensive documentation of security measures and testing procedures

## [3.5.3] - 2025-09-23

### Added
- Template externalization and production polish
- Intelligent CLAUDE.md merging capability

## [3.5.2] - 2025-09-23

### Added
- Gate shell function behind --full flag

## [3.5.1] - 2025-09-23

### Infrastructure
- CI improvements and ShellCheck validation

---

For detailed security implementation information, see `docs/development/SECURITY_HARDENING.md`.