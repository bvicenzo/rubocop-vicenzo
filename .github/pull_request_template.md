## What changed

<!-- What this PR does and why. Link an issue if there is one. -->

## Type of change

<!-- Keep only what applies. It must match the Conventional Commit type in the PR title. -->

- [ ] `feat` — new cop or user-facing capability *(triggers a minor release)*
- [ ] `fix` — bug fix in a cop or in the config *(triggers a patch release)*
- [ ] `refactor` — behaviour-preserving change *(no release)*
- [ ] `chore` / `ci` / `docs` / `test` / `style` — maintenance *(no release)*
- [ ] breaking change — `!` in the title or a `BREAKING CHANGE:` footer

## Checklist

- [ ] The **PR title** is a valid Conventional Commit (`type: short description`).
      This PR is squash-merged, so the title is the commit release-please reads to
      decide the next version and to write the `CHANGELOG.md`.
- [ ] `bundle exec rake` passes locally (specs + RuboCop).
- [ ] A new cop ships with a spec and is registered in
      `lib/rubocop/cop/vicenzo_cops.rb`.
- [ ] A new cop's `config/default.yml` entry keeps `VersionAdded: '<<next>>'`.
      Never write a version by hand — the release workflow fills it in.
- [ ] The `CHANGELOG.md` was **not** edited by hand; release-please owns it.
