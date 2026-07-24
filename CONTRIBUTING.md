# Contributing

## Changelog entries

Releases are managed with [Reissue](https://github.com/SOFware/reissue), which
builds each release's changelog from **two sources that are merged together** at
release time. Use whichever fits the change — or both.

### 1. Git trailers (preferred for code changes)

Add a trailer to your commit message whose key is a changelog section. Reissue
collects these from every commit since the last version tag.

```
Harden the tracking middleware

Fixed: The middleware no longer breaks the request it observes
Added: An event_recorded.close_encounters notification on status change
```

- Valid keys: `Added`, `Changed`, `Deprecated`, `Removed`, `Fixed`, `Security`.
- Multiple trailers per commit are fine; multiple commits accumulate.
- Optionally add `version: major|minor|patch` to steer the next version bump.

Because trailers are read from commits reachable on the default branch, **merge
PRs with a merge commit** (the default here) so branch-commit trailers reach
`main`. If you squash, keep the trailers in the squash message.

### 2. Hand-edited `CHANGELOG.md` (for changes without trailers)

Some commits can't carry trailers — Dependabot bumps are the common case. For
those, add lines under the `## [Unreleased]` heading by hand:

```markdown
## [Unreleased]

### Changed

- Bump puma from 7 to 8
```

At release, Reissue merges these hand-written entries with the trailer-derived
ones into the same sections. Both show up.

## Releasing

Trigger the **"Release gem to RubyGems.org"** workflow from the Actions tab. It
runs the shared Reissue workflow: publishes the gem, writes a checksum, and
opens a follow-up PR that bumps to the next version. Run it with `dry_run`
first if you want to preview without publishing.
