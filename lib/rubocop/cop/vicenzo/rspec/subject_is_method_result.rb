# frozen_string_literal: true

module RuboCop
  module Cop
    module Vicenzo
      module RSpec
        # The subject of an example group that describes a method must be the object under test,
        # not what the method returned.
        #
        # A specification is read as a sentence. In "the cat caught the ball", the subject is the
        # cat, not the ball. Storing the return value in the subject inverts that: the object the
        # example is about disappears from the text, the subject's name starts to lie (a
        # `subject(:cat)` holding a `Symbol`), and every scenario that would need the same object
        # in a different state has to redefine the whole call.
        #
        # An example group names a method when its description reads `#instance_method`,
        # `.class_method`, or the bare method name. The cop then looks at the subjects declared
        # under it - including the ones nested in a `context` - and reports the ones whose value
        # comes from calling that method.
        #
        # Some layers legitimately specify a single entry point, where the result is the subject
        # (a service object always invoked through `call`, for instance). `AllowedMethods` exists
        # for those and ships empty: the convention belongs to the project that adopts it, not to
        # this gem. Declaring it there - or excluding a whole directory through the standard
        # `Exclude` - keeps the exemption visible and reviewable in `.rubocop.yml`.
        #
        # An inline disable directive is not that: it is an exemption nobody reviewed. Dropping
        # the `#` from the description is not either - the cop reads bare descriptions too, and the
        # only thing lost is the reader's clue that a method is being specified there.
        #
        # @example
        #   # bad - the subject is the ball
        #   describe '#catch' do
        #     subject(:catch) { Cat.new(name: 'Bixano').catch(object: Ball.new) }
        #
        #     it { is_expected.to eq(:success) }
        #   end
        #
        #   # good - the subject is the cat
        #   describe '#catch' do
        #     subject(:cat) { Cat.new(name: 'Bixano') }
        #
        #     it { expect(cat.catch(object: Ball.new)).to eq(:success) }
        #   end
        #
        # @example a description without a prefix names a method too
        #   # bad - dropping the '#' silences nothing and costs the reader the
        #   # one clue that a method is being specified here
        #   describe 'catch' do
        #     subject(:catch) { Cat.new(name: 'Bixano').catch(object: Ball.new) }
        #   end
        #
        # @example AllowedMethods: ['call']
        #   # good - a layer whose convention is a single entry point. Declared in
        #   # .rubocop.yml, the exemption stays visible and reviewable, which an
        #   # inline disable directive never is
        #   describe '.call' do
        #     subject(:result) { described_class.(object: Ball.new) }
        #   end
        class SubjectIsMethodResult < RuboCop::Cop::RSpec::Base
          MSG = 'Subject holds what `%<method>s` returned, not the object under test. ' \
                'Make the subject the object that receives `%<method>s`, and call it inside the example.'

          # `#catch`, `.catch`, and the form carrying a signature such as `#catch(object:)`.
          PREFIXED_METHOD_DESCRIPTION = /\A[#.](?<name>.+?)(?:\(.*\))?\z/
          # `catch` - a description that is nothing but a method name.
          BARE_METHOD_DESCRIPTION = /\A(?<name>\w+[?!=]?)\z/

          def on_block(node)
            return unless subject?(node)

            method_name = described_method_name(node)
            return if method_name.nil? || allowed_methods.include?(method_name)

            invocation = invocation_of(node.body, method_name)
            return unless invocation

            add_offense(invocation, message: format(MSG, method: method_name))
          end

          alias on_numblock on_block
          alias on_itblock on_block

          private

          def allowed_methods
            cop_config.fetch('AllowedMethods', [])
          end

          # The nearest enclosing example group naming a method: a subject sitting in a `context`
          # still answers to the `describe '#method'` wrapping it.
          def described_method_name(node)
            node
              .each_ancestor(:any_block)
              .lazy
              .filter_map { |ancestor| method_name_from(ancestor) if example_group?(ancestor) }
              .first
          end

          def method_name_from(node)
            description = node.send_node.first_argument
            return unless description.respond_to?(:str_type?) && description.str_type?

            match = PREFIXED_METHOD_DESCRIPTION.match(description.value) ||
                    BARE_METHOD_DESCRIPTION.match(description.value)

            match&.[](:name)
          end

          # Only the expression the subject returns, walked down its receiver chain, counts:
          # `Cat.new(name: 'Bixano').catch(ball)` is the result of `catch`, while
          # `Cat.new(catches: other.catch)` is still a cat.
          def invocation_of(body, method_name)
            node = returned_expression(body)

            while node
              node = node.send_node if node.any_block_type?
              break unless node.type?(:call)
              return node if node.method?(method_name)

              node = node.receiver
            end

            nil
          end

          def returned_expression(body)
            return if body.nil?

            body.begin_type? ? body.children.last : body
          end
        end
      end
    end
  end
end
