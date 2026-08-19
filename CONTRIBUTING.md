# Contributing

## Development setup

Run `bin/setup` once after cloning. It installs dependencies and points
`core.hooksPath` at `.githooks/`, enabling a `commit-msg` hook that enforces
Conventional Commits locally.

Run the test suite and the linter with the default task — the same one CI runs:

```bash
bundle exec rake
```

## Commit messages — Conventional Commits

This project follows [Conventional Commits](https://www.conventionalcommits.org/).
The version bump and the `CHANGELOG.md` are generated automatically from commit
messages, so the prefix matters:

| Type | When to use | Release effect |
|------|-------------|----------------|
| `feat:` | New cop or user-facing capability | minor bump |
| `fix:` | Bug fix in a cop or in the config | patch bump |
| `feat!:` or a `BREAKING CHANGE:` footer | Backwards-incompatible change | minor bump while `0.x`, major from `1.0` on |
| `chore:` `ci:` `docs:` `style:` `test:` `refactor:` | Maintenance | no release |

Title format: `type: short description` (e.g.
`feat: add Vicenzo/Style/JsonParseSymbolizeNames cop`).

Pull requests are squash-merged, so **the PR title becomes the commit message
release-please reads**. Get the title right even when the individual commits are
messy.

## Adding a new cop

Generate the cop, its spec and its `config/default.yml` entry with:

```bash
bundle exec rake 'new_cop[Vicenzo/Department/CopName]'
```

The generator writes `VersionAdded: '<<next>>'` into `config/default.yml`. Leave
that placeholder alone — never replace it with a version by hand. The release
workflow fills it in with the version being released (see below).

## Releasing (release-please)

Releases are automated with [release-please](https://github.com/googleapis/release-please):

1. Every push to `master` creates or updates a **release PR** titled
   `chore(master): release X.Y.Z`. It bumps
   `lib/rubocop/vicenzo/version.rb`, `.release-please-manifest.json`,
   `Gemfile.lock` and the version in the `README.md` install snippet, and updates
   `CHANGELOG.md` from the Conventional Commits made since the last release.
2. New cops are added with `VersionAdded: '<<next>>'`. The release workflow
   replaces every `<<next>>` in `config/default.yml` with the version being
   released, directly on the release PR — no manual editing needed. This matters
   because `rake docs:generate` reads `VersionAdded` to build the "Version Added"
   column of the documentation site.
3. **Merging the release PR** creates the git tag `vX.Y.Z` and a GitHub Release.
   That in turn triggers two things automatically:
   - `.github/workflows/publish.yml` publishes the gem to RubyGems via
     [Trusted Publishing](https://guides.rubygems.org/trusted-publishing/) (OIDC,
     no API key stored in the repository).
   - `.github/workflows/docs.yml` rebuilds and deploys the documentation site to
     GitHub Pages, because `lib/rubocop/vicenzo/version.rb` changed.
4. The release PR always reflects **everything on `master` since the last
   release**. Cut releases promptly: merge the release PR before landing
   unrelated new work you don't want included in that release.

Nothing about a release is done by hand — there is no `rake release` to run
locally and no version to edit yourself.

## If the release PR is failing

release-please only rebuilds the release branch when a **releasable** commit
(`feat:` / `fix:`) lands on `master`. Non-releasable fixes (`chore:`, `style:`,
`ci:`, `docs:`, `test:`) do **not** rebuild it, so the release branch can fall
behind `master` and its CI can run stale code.

When the release PR's CI is red:

1. Push the fix to `master` through a normal PR. **Never** push directly to the
   `release-please--…` branch — release-please overwrites it.
2. If those fix commits are non-releasable (so the release PR won't refresh on
   its own), **close the release PR and delete its branch**. On the next push to
   `master`, release-please recreates the release PR from the current `master`
   (now including the fix) and its CI passes.
3. Merge the freshly recreated release PR.

Never manually rebase or force-push the release-please branch.

## If the gem was not published

The tag and the GitHub Release already exist, so publishing is retryable: fix the
cause and use **Re-run jobs** on the failed `Publish gem` workflow run. An
authentication failure points at the trusted publisher registration on RubyGems
(the repository or the workflow filename must match `publish.yml`), not at the
workflow itself.
