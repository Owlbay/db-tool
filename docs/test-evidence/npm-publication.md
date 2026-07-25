# npm Packaging And Publication Evidence

Date: 2026-07-25

Result: PACKAGING_PASS_PUBLICATION_EXTERNAL

## Scope

This evidence covers the repository's npm package generator, installer
contract, and prepublish workflow definition. It does not claim that packages
exist in the public npm registry or that the six native jobs have run.

## Package Topology

The default generator requires these native targets before writing a release:

| Target | Package |
| --- | --- |
| `x86_64-unknown-linux-musl` | `@yovinchen/dbtool-linux-x64` |
| `aarch64-unknown-linux-musl` | `@yovinchen/dbtool-linux-arm64` |
| `x86_64-apple-darwin` | `@yovinchen/dbtool-darwin-x64` |
| `aarch64-apple-darwin` | `@yovinchen/dbtool-darwin-arm64` |
| `x86_64-pc-windows-msvc` | `@yovinchen/dbtool-win32-x64` |
| `aarch64-pc-windows-msvc` | `@yovinchen/dbtool-win32-arm64` |
| JavaScript wrapper | `@yovinchen/dbtool` |

## Verification

Command:

```bash
node --check dist/npm/bin/dbtool.js
node --check scripts/package-npm.mjs
node --check scripts/package-npm-test.mjs
node scripts/package-npm-test.mjs
```

Observed result:

```text
npm packaging tests passed: 6 platform packages, wrapper, offline install, dry-run publish
```

The test builds a complete six-target fixture matrix, generates seven tarballs,
checks target/package/OS/CPU mappings and both license files, executes all seven
`npm publish --dry-run` paths, rejects an incomplete matrix without deleting
existing output, installs the host pair without registry access, invokes its
binary, validates `DBTOOL_BINARY`, and checks the one-line missing-package error.

Implementation commit: `8e631ac`.

## Public Publication Boundary

Current command and result:

```text
$ npm whoami --registry=https://registry.npmjs.org/
npm error code ENEEDAUTH
```

The official release workflow also produces only the selected macOS ARM64
binary, not the complete real six-platform binary matrix. Consequently no npm
publish command was executed. Publishing only the wrapper and one platform at
version `1.0.1` would create an immutable incomplete release that could not be
safely backfilled.

## Native Prepublish Harness

`.github/workflows/npm-prepublish-evidence.yml` is a manual-only workflow that
checks out one immutable version tag, builds the portable CLI on native Linux,
macOS, and Windows x64/arm64 runners, and executes the existing target-native
smoke on every binary. The aggregation job downloads exactly those six named
artifacts, runs `scripts/package-npm.mjs`, captures seven
`npm publish --dry-run --json` results, and uploads the tarballs plus JSON as
one evidence artifact.

Local verification parsed the workflow YAML, reran the complete fixture matrix,
and passed `scripts/validate-final-goal.sh`. This proves the repository-side
gate is wired and remains fail-closed; it is not evidence that GitHub-hosted
runners built the binaries. NPM-T06 stays open until a real workflow run
records all six native smokes and all seven package dry-runs.

Before public publication, supply the complete real matrix, authenticate and
verify control of the scope, create/publish all six native packages first, then
publish the wrapper. npm documents that scoped public packages need public
access configuration, and recommends trusted publishing/provenance for CI:

- https://docs.npmjs.com/creating-and-publishing-scoped-public-packages/
- https://docs.npmjs.com/trusted-publishers/
- https://docs.npmjs.com/generating-provenance-statements/
