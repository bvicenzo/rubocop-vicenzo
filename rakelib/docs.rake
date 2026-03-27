# frozen_string_literal: true

require 'yaml'
require 'fileutils'

DOCS_PAGES_DIR = 'docs/modules/ROOT/pages'
DOCS_NAV_FILE  = 'docs/modules/ROOT/nav.adoc'

namespace :docs do
  desc 'Generate AsciiDoc documentation for all Vicenzo cops'
  task :generate do
    FileUtils.mkdir_p(DOCS_PAGES_DIR)

    default_config = YAML.load_file('config/default.yml')
    cop_data = default_config.keys.map { |name| build_cop_data(name, default_config) }

    cops_by_dept = cop_data.group_by { |c| c[:department] }

    cops_by_dept.sort.each do |department, cops|
      content  = render_department_page(department, cops.sort_by { |c| c[:name] })
      filename = "cops_#{department.downcase}.adoc"
      File.write(File.join(DOCS_PAGES_DIR, filename), content)
      puts "  Generated: #{filename} (#{cops.size} cop#{'s' if cops.size != 1})"
    end

    write_index(cop_data)
    write_nav(cops_by_dept)
    puts "\nDone. #{cop_data.size} cops documented across #{cops_by_dept.size} departments."
  end
end

# ---------------------------------------------------------------------------
# Data extraction
# ---------------------------------------------------------------------------

def build_cop_data(cop_name, default_config)
  config = default_config[cop_name] || {}
  source = read_cop_source(cop_name)
  cop_data_hash(cop_name, config, source)
end

def cop_data_hash(cop_name, config, source)
  {
    name: cop_name,
    department: cop_name.split('/')[1],
    description: config['Description'] || '',
    version: config['VersionAdded'] || '-',
    enabled: config.fetch('Enabled', true),
    autocorrect: source ? autocorrect?(source) : false,
    examples: source ? extract_examples(source) : [],
    config_keys: extra_config_keys(config)
  }
end

def read_cop_source(cop_name)
  path = cop_name_to_path(cop_name)
  File.exist?(path) ? File.read(path) : nil
end

def cop_name_to_path(cop_name)
  parts = cop_name.split('/')
  dept  = parts[1].downcase
  klass = underscore(parts[2])
  "lib/rubocop/cop/vicenzo/#{dept}/#{klass}.rb"
end

def underscore(str)
  str
    .gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
    .gsub(/([a-z\d])([A-Z])/, '\1_\2')
    .downcase
end

def autocorrect?(source)
  source.include?('AutoCorrector')
end

def extract_examples(source)
  docstring = extract_docstring(source)
  parse_examples(docstring)
end

def extract_docstring(source)
  lines = []
  source.each_line do |line|
    break if /^\s+class\s/.match?(line)

    lines << line if /^\s+#/.match?(line)
  end
  lines
end

def parse_examples(docstring_lines)
  examples = []
  current = nil
  docstring_lines.each do |line|
    examples, current = update_examples(line, examples, current)
  end
  finalize_examples(examples, current)
end

def update_examples(line, examples, current)
  if line =~ /^\s+#\s+@example(.*)/
    examples << current if current
    [examples, { title: Regexp.last_match(1).strip, code: [] }]
  elsif current
    current[:code] << line.sub(/^\s+#\s{0,3}/, '').rstrip
    [examples, current]
  else
    [examples, current]
  end
end

def finalize_examples(examples, current)
  examples << current if current
  examples.each { |e| e[:code].pop while e[:code].last&.empty? }
  examples
end

def extra_config_keys(config)
  skip = %w[Description Enabled Severity VersionAdded Include Exclude Safe]
  config.except(*skip)
end

# ---------------------------------------------------------------------------
# AsciiDoc rendering
# ---------------------------------------------------------------------------

def render_department_page(department, cops)
  lines = ["= Vicenzo/#{department}", ':toc: left', ':toc-title: Cops', ':toclevels: 1', '']
  cops.each { |cop| lines.concat(render_cop(cop)) }
  lines.join("\n")
end

def render_cop(cop)
  lines = ["== #{cop[:name]}", '', cop[:description], '']
  lines.concat(render_metadata_table(cop))
  lines.concat(render_all_examples(cop[:examples]))
  lines.concat(render_config_keys(cop[:config_keys])) unless cop[:config_keys].empty?
  lines.push("'''", '')
end

def render_all_examples(examples)
  examples.each_with_index.flat_map { |example, i| render_example(example, i) }
end

def render_metadata_table(cop)
  enabled     = cop[:enabled] ? 'Enabled' : 'Disabled'
  autocorrect = cop[:autocorrect] ? 'Yes' : 'No'
  ['[cols="1,1,1,1"]', '|===', '| Enabled by default | Safe | Supports autocorrection | Version Added',
   '', "| #{enabled}", '| Yes', "| #{autocorrect}", "| #{cop[:version]}", '|===', '']
end

def render_example(example, index)
  title = if example[:title].empty?
            index.zero? ? 'Example' : "Example #{index + 1}"
          else
            example[:title]
          end
  ["=== #{title}", '', '[source,ruby]', '----', *example[:code], '----', '']
end

def render_config_keys(config_keys)
  lines = ['=== Configurable attributes', '', '[cols="1,1"]', '|===', '| Name | Default value', '']
  config_keys.each { |key, value| lines.push("| #{key}", "| `#{value.inspect}`", '') }
  lines.push('|===', '')
end

# ---------------------------------------------------------------------------
# Index and navigation
# ---------------------------------------------------------------------------

def write_index(cop_data)
  lines = index_header_lines + index_cops_table_lines(cop_data)
  File.write(File.join(DOCS_PAGES_DIR, 'index.adoc'), lines.join("\n"))
  puts '  Generated: index.adoc'
end

def index_header_lines
  ['= RuboCop Vicenzo', ':toc: left', ''] +
    ['Custom RuboCop cops for enforcing conventions adopted by Vicenzo projects.', ''] +
    installation_section_lines +
    ['== Cops', '', '[cols="2,1,1"]', '|===', '| Cop | Department | Version Added', '']
end

def installation_section_lines
  ['== Installation', ''] +
    gemfile_installation_lines +
    rubocop_yml_installation_lines
end

def gemfile_installation_lines
  ['Add to your `Gemfile`:', '', '[source,ruby]', '----',
   "gem 'rubocop-vicenzo', require: false", '----', '']
end

def rubocop_yml_installation_lines
  ['Then add to your `.rubocop.yml`:', '', '[source,yaml]', '----',
   'plugins:', '  - rubocop-vicenzo', '----', '']
end

def index_cops_table_lines(cop_data)
  lines = cop_data.sort_by { |c| c[:name] }.map do |cop|
    dept     = cop[:department]
    filename = "cops_#{dept.downcase}.adoc"
    anchor   = cop[:name].downcase.tr('/', '-').gsub(/[^a-z0-9-]/, '')
    "| xref:#{filename}##{anchor}[#{cop[:name]}] | #{dept} | #{cop[:version]}"
  end
  lines.push('|===', '')
end

def write_nav(cops_by_dept)
  lines = ['* xref:index.adoc[Home]', '* Cops']
  cops_by_dept.sort.each do |department, _|
    lines << "** xref:cops_#{department.downcase}.adoc[#{department}]"
  end
  File.write(DOCS_NAV_FILE, "#{lines.join("\n")}\n")
  puts '  Generated: nav.adoc'
end
