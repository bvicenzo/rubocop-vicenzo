# frozen_string_literal: true

require 'date'

desc 'Prepare release: update config, version file, and changelog'
task :cut_release, [:version] do |_t, args|
  version = args[:version]

  # 1. Validation
  abort 'Error: You must provide a version. Example: rake cut_release[0.3.0]' unless version

  config_file    = 'config/default.yml'
  version_file   = 'lib/rubocop/vicenzo/version.rb'
  changelog_file = 'CHANGELOG.md'

  # Check if files exist
  [config_file, version_file, changelog_file].each do |file|
    abort "Error: File not found at #{file}" unless File.exist?(file)
  end

  puts "✂️  Cutting release for version #{version}..."

  # -------------------------------------------------------
  # 2. Update config/default.yml (<<next>> -> version)
  # -------------------------------------------------------
  config_content = File.read(config_file)
  if config_content.include?("'<<next>>'")
    updated_config = config_content.gsub("'<<next>>'", "'#{version}'")
    File.write(config_file, updated_config)
    puts "   ✅ Updated 'VersionAdded' in #{config_file}"
  else
    puts "   ⚠️  No '<<next>>' found in #{config_file} (skipping)"
  end

  # -------------------------------------------------------
  # 3. Update lib/rubocop/vicenzo/version.rb
  # -------------------------------------------------------
  version_content = File.read(version_file)
  # Regex looks for: VERSION = '...' or VERSION = "..."
  if version_content.match?(/VERSION\s*=\s*['"](.+)['"]/)
    updated_version = version_content.gsub(/VERSION\s*=\s*['"](.+)['"]/, "VERSION = '#{version}'")
    File.write(version_file, updated_version)
    puts "   ✅ Updated VERSION constant in #{version_file}"
  else
    puts "   ❌ Could not find VERSION constant in #{version_file}"
  end

  # -------------------------------------------------------
  # 4. Update CHANGELOG.md
  # -------------------------------------------------------
  changelog_content = File.read(changelog_file)
  unreleased_header = '## [Unreleased]'
  date = Date.today.to_s # YYYY-MM-DD

  # We replace "## [Unreleased]" with:
  # ## [Unreleased]
  #
  # ## [version] - date
  #
  # This pushes the existing unreleased items down under the new version header.
  new_entry_header = "#{unreleased_header}\n\n## [#{version}] - #{date}"

  if changelog_content.include?(unreleased_header)
    # We use 'sub' to replace only the first occurrence (the top one)
    updated_changelog = changelog_content.sub(unreleased_header, new_entry_header)
    File.write(changelog_file, updated_changelog)
    puts "   ✅ Updated #{changelog_file} (moved items to [#{version}])"
  else
    puts "   ❌ Could not find '#{unreleased_header}' in #{changelog_file}"
  end

  puts "\n🎉 Release preparation complete! Don't forget to commit."
end
