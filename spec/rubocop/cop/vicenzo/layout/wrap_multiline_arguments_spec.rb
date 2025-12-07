# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::Layout::WrapMultilineArguments, :config do
  context 'when the code violates style guidelines' do
    context 'and arguments are multiline' do
      context 'and the first argument is a scalar spanning multiple lines' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            method_name arg1,
            ^^^^^^^^^^^^^^^^^ Method call with multiline arguments must use parentheses and break line before the first argument.
                        arg2
          RUBY

          expect_correction(<<~RUBY)
            method_name(
              arg1,
                        arg2)
          RUBY
        end
      end

      context 'and the last argument is a multiline hash' do
        it 'forces parentheses and wrap even if the first arg is single line' do
          expect_offense(<<~RUBY)
            method_1 arg1, { a: 1,
            ^^^^^^^^^^^^^^^^^^^^^^ Method call with multiline arguments must use parentheses and break line before the first argument.
                             b: 2 }
          RUBY

          expect_correction(<<~RUBY)
            method_1(
              arg1, { a: 1,
                             b: 2 })
          RUBY
        end
      end

      context 'and the first argument is a multiline array' do
        it 'forces parentheses and wrap' do
          expect_offense(<<~RUBY)
            method_1 [1,
            ^^^^^^^^^^^^ Method call with multiline arguments must use parentheses and break line before the first argument.
                      2], arg1
          RUBY

          expect_correction(<<~RUBY)
            method_1(
              [1,
                      2], arg1)
          RUBY
        end
      end

      context 'and using RSpec matcher inside .to' do
        it 'forces the matcher to the next line' do
          expect_offense(<<~RUBY)
            expect(x).to contain_exactly(
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Method call with multiline arguments must use parentheses and break line before the first argument.
              1,
              2
            )
          RUBY

          expect_correction(<<~RUBY)
            expect(x).to(
              contain_exactly(
              1,
              2
            ))
          RUBY
        end
      end
    end

    context 'and configuration defines a custom indentation width' do
      let(:config) do
        RuboCop::Config.new(
          'Vicenzo/Layout/WrapMultilineArguments' => {
            'IndentationWidth' => 4
          }
        )
      end

      it 'uses the configured indentation width' do
        expect_offense(<<~RUBY)
          method_name arg1,
          ^^^^^^^^^^^^^^^^^ Method call with multiline arguments must use parentheses and break line before the first argument.
                      arg2
        RUBY

        expect_correction(<<~RUBY)
          method_name(
              arg1,
                      arg2)
        RUBY
      end
    end

    context 'and arguments are multiline but started on next line with backslash' do
      it 'registers offense because parentheses are preferred over backslash' do
        expect_offense(<<~RUBY)
          method_name \\
          ^^^^^^^^^^^^^ Method call with multiline arguments must use parentheses and break line before the first argument.
            arg1,
            arg2
        RUBY

        expect_correction(<<~RUBY)
          method_name(
            arg1,
            arg2)
        RUBY
      end
    end
  end

  context 'when the code follows style guidelines' do
    context 'and arguments are single line' do
      it 'does not register offense' do
        expect_no_offenses(<<~RUBY)
          method_name(arg1, arg2)
        RUBY
      end

      it 'does not register offense without parentheses' do
        expect_no_offenses(<<~RUBY)
          method_name arg1, arg2
        RUBY
      end
    end

    context 'and arguments are multiline but correctly wrapped' do
      it 'does not register offense' do
        expect_no_offenses(<<~RUBY)
          method_name(
            arg1,
            arg2
          )
        RUBY
      end
    end

    context 'and the method is a setter (assignment)' do
      it 'does not register offense even with multiline value' do
        expect_no_offenses(<<~RUBY)
          spec.files = IO.popen(%w[git ls-files -z]) do |ls|
            ls.readlines
          end
        RUBY
      end
    end
  end
end
