# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::Style::MultilineMethodCallParentheses, :config do
  context 'when the code violates style guidelines' do
    context 'and the call is multiline with arguments' do
      it 'registers an offense when parentheses are missing' do
        expect_offense(<<~RUBY)
          method_name arg1,
          ^^^^^^^^^^^^^^^^^ Use parentheses for method calls with arguments that span multiple lines.
                      arg2
        RUBY

        expect_correction(<<~RUBY)
          method_name(arg1,
                      arg2)
        RUBY
      end
    end
  end

  context 'when the code follows style guidelines' do
    context 'and the call is single-line' do
      context 'and parentheses are omitted' do
        it 'does not register offense (optional style)' do
          expect_no_offenses(<<~RUBY)
            method_name arg1, arg2
          RUBY
        end
      end

      context 'and parentheses are present' do
        it 'does not register offense' do
          expect_no_offenses(<<~RUBY)
            method_name(arg1, arg2)
          RUBY
        end
      end
    end

    context 'and the call is multiline with parentheses' do
      it 'does not register offense' do
        expect_no_offenses(<<~RUBY)
          method_name(
            arg1,
            arg2
          )
        RUBY
      end
    end

    context 'but the method is an operator' do
      it 'does not register offense for arithmetic operators' do
        expect_no_offenses(<<~RUBY)
          sum = 1 +
                2
        RUBY
      end

      it 'does not register offense for array access' do
        expect_no_offenses(<<~RUBY)
          items[
            index
          ]
        RUBY
      end
    end

    context 'but the method is a setter' do
      it 'does not register offense for assignment methods' do
        expect_no_offenses(<<~RUBY)
          self.value =
            10
        RUBY
      end
    end
  end
end
