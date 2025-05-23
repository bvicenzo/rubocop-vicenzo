# frozen_string_literal: true

require 'lint_roller'

module RuboCop
  module Vicenzo
    # A plugin that integrates rubocop-vicenzo with RuboCop's plugin system.
    class Plugin < LintRoller::Plugin
      def about
        LintRoller::About.new(
          name: 'rubocop-vicenzo',
          version: VERSION,
          homepage: 'https://github.com/bvicenzo/rubocop-vicenzo/',
          description: 'Cops created for sharing years of experiments of good practices.'
        )
      end

      def supported?(context)
        context.engine == :rubocop
      end

      def rules(_context)
        LintRoller::Rules.new(
          type: :path,
          config_format: :rubocop,
          value: Pathname.new(__dir__).join('../../../config/default.yml')
        )
      end
    end
  end
end
