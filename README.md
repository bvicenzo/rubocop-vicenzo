# RuboCop::Vicenzo

[![Ruby](https://github.com/bvicenzo/rubocop-vicenzo/actions/workflows/main.yml/badge.svg)](https://github.com/bvicenzo/rubocop-vicenzo/actions/workflows/main.yml)

📖 **[Documentation](https://bvicenzo.github.io/rubocop-vicenzo)**

## Installation

Add it to the `development`/`test` group of your `Gemfile`:

<!-- x-release-please-start-version -->
```ruby
group :development, :test do
  gem 'rubocop-vicenzo', '~> 0.6.0', require: false
end
```
<!-- x-release-please-end-version -->

> The version above is kept current automatically on every release; pin to
> whichever version you prefer.

Or let Bundler add the latest version for you:

```bash
bundle add rubocop-vicenzo --group=development --require=false
```

If bundler is not being used to manage dependencies, install the gem by executing:

```bash
gem install rubocop-vicenzo
```

## Usage

You need to tell RuboCop to load the Vicenzo extension. There are three
ways to do this:

### RuboCop configuration file

Put this into your `.rubocop.yml`.

```yaml
plugins: rubocop-vicenzo
```

Alternatively, use the following array notation when specifying multiple extensions.

```yaml
plugins:
  - rubocop-other-extension
  - rubocop-vicenzo
```

Now you can run `rubocop` and it will automatically load the RuboCop Vicenzo
cops together with the standard cops.

> [!NOTE]
> The plugin system is supported in RuboCop 1.72+. In earlier versions, use `require` instead of `plugins`.

### Command line

```bash
rubocop --plugin rubocop-vicenzo
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`.

Releases are automated: the version, the `CHANGELOG.md`, the git tag and the push
to [rubygems.org](https://rubygems.org) are all derived from
[Conventional Commits](https://www.conventionalcommits.org/) by release-please.
There is no version to edit and no release command to run by hand — see
[CONTRIBUTING.md](CONTRIBUTING.md).

### Documentation

The documentation site is built with [Antora](https://antora.org) and published automatically to GitHub Pages on every new release.

To build it locally, you will need [Node.js](https://nodejs.org) (v20+) installed. Then install Antora:

```bash
npm install -g @antora/cli @antora/site-generator
```

Generate the AsciiDoc pages from the cop sources and build the site:

```bash
bundle exec rake docs:generate
antora antora-playbook.yml
```

The site will be available at `build/site/index.html`.

### Generate binstubs

If you want is possible change the command `bundle exec something` by `bin/something` generating binstubs

```bash
bundle binstubs rake rspec-core rubocop
```

### Creating a new cop

```bash
bundle exec rake 'new_cop[Vicenzo/OptionalNamespace/CopName]'
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/bvicenzo/rubocop-vicenzo. Read [CONTRIBUTING.md](CONTRIBUTING.md) first — it covers the commit conventions the release automation depends on. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/bvicenzo/rubocop-vicenzo/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the Rubocop::Vicenzo project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/bvicenzo/rubocop-vicenzo/blob/master/CODE_OF_CONDUCT.md).
