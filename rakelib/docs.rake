# frozen_string_literal: true

require 'yaml'
require 'fileutils'

DOCS_PAGES_DIR = 'docs/modules/ROOT/pages'
DOCS_NAV_FILE  = 'docs/modules/ROOT/nav.adoc'

desc 'Generate AsciiDoc documentation for all Vicenzo cops'
namespace :docs do
  task :generate do
    FileUtils.mkdir_p(DOCS_PAGES_DIR)

    default_config = YAML.load_file('config/default.yml')
    cop_data = default_config.keys.map { |name| build_cop_data(name, default_config) }

    cops_by_dept = cop_data.group_by { |c| c[:department] }

    cops_by_dept.sort.each do |department, cops|
      content  = render_department_page(department, cops.sort_by { |c| c[:name] })
      filename = "cops_#{department.downcase}.adoc"
      File.write(File.join(DOCS_PAGES_DIR, filename), content)
      puts "  Generated: #{filename} (#{cops.size} cop#{cops.size != 1 ? 's' : ''})"
    end

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

  {
    name:        cop_name,
    department:  cop_name.split('/')[1],
    description: config['Description'] || '',
    version:     config['VersionAdded'] || '-',
    enabled:     config.fetch('Enabled', true),
    autocorrect: source ? autocorrect?(source) : false,
    examples:    source ? extract_examples(source) : [],
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
  str.gsub(/([A-Z]+)([A-Z][a-z])/, '\1_\2')
     .gsub(/([a-z\d])([A-Z])/, '\1_\2')
     .downcase
end

def autocorrect?(source)
  source.include?('AutoCorrector')
end

def extract_examples(source)
  examples     = []
  current      = nil
  in_docstring = false

  source.each_line do |line|
    in_docstring = true if !in_docstring && line =~ /^\s+#/

    if in_docstring && line =~ /^\s+class\s/
      examples << current if current
      current = nil
      break
    end

    next unless in_docstring

    if line =~ /^\s+#\s+@example(.*)/
      examples << current if current
      current = { title: ::Regexp.last_match(1).strip, code: [] }
    elsif current
      # Strip leading whitespace + '#' + up to 3 spaces (the @example block indent),
      # preserving relative indentation of the code within the example.
      stripped = line.sub(/^\s+#\s{0,3}/, '').rstrip
      current[:code] << stripped
    end
  end

  examples << current if current
  examples.each { |e| e[:code].pop while e[:code].last&.empty? }
  examples
end

def extra_config_keys(config)
  skip = %w[Description Enabled Severity VersionAdded Include Exclude Safe]
  config.reject { |k, _| skip.include?(k) }
end

# ---------------------------------------------------------------------------
# AsciiDoc rendering
# ---------------------------------------------------------------------------

def render_department_page(department, cops)
  lines = []
  lines << "= Vicenzo/#{department}"
  lines << ':toc: left'
  lines << ':toc-title: Cops'
  lines << ':toclevels: 1'
  lines << ''

  cops.each do |cop|
    lines << "== #{cop[:name]}"
    lines << ''
    lines << cop[:description]
    lines << ''
    lines << '[cols="1,1,1,1"]'
    lines << '|==='
    lines << '| Enabled by default | Safe | Supports autocorrection | Version Added'
    lines << ''
    lines << "| #{cop[:enabled] ? 'Enabled' : 'Disabled'}"
    lines << '| Yes'
    lines << "| #{cop[:autocorrect] ? 'Yes' : 'No'}"
    lines << "| #{cop[:version]}"
    lines << '|==='
    lines << ''

    cop[:examples].each_with_index do |example, i|
      title = example[:title].empty? ? (i.zero? ? 'Example' : "Example #{i + 1}") : example[:title]
      lines << "=== #{title}"
      lines << ''
      lines << '[source,ruby]'
      lines << '----'
      lines += example[:code]
      lines << '----'
      lines << ''
    end

    unless cop[:config_keys].empty?
      lines << '=== Configurable attributes'
      lines << ''
      lines << '[cols="1,1"]'
      lines << '|==='
      lines << '| Name | Default value'
      lines << ''
      cop[:config_keys].each do |key, value|
        lines << "| #{key}"
        lines << "| `#{value.inspect}`"
        lines << ''
      end
      lines << '|==='
      lines << ''
    end

    lines << "'''"
    lines << ''
  end

  lines.join("\n")
end

def write_nav(cops_by_dept)
  lines = ['* xref:index.adoc[Home]', '* Cops']
  cops_by_dept.sort.each do |department, _|
    lines << "** xref:cops_#{department.downcase}.adoc[#{department}]"
  end
  File.write(DOCS_NAV_FILE, "#{lines.join("\n")}\n")
  puts "  Generated: nav.adoc"
end
