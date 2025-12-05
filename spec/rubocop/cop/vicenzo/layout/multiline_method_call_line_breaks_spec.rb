# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::Layout::MultilineMethodCallLineBreaks, :config do
  context 'when the code violates style guidelines' do
    context 'and configuration does not define a custom indentation width' do
      context 'and the first method is on the same line as the receiver' do
        it 'registers an offense and corrects by breaking the line' do
          expect_offense(<<~RUBY)
            object.method_one
                  ^^^^^^^^^^^ Method calls in a multiline chain must each be on their own line.
              .method_two
          RUBY

          expect_correction(<<~RUBY)
            object
              .method_one
              .method_two
          RUBY
        end
      end

      context 'and a middle method is attached to the previous one' do
        it 'registers an offense on the specific method attached incorrectly' do
          expect_offense(<<~RUBY)
            object
              .method_one.method_two
                         ^^^^^^^^^^^ Method calls in a multiline chain must each be on their own line.
              .method_three
          RUBY

          expect_correction(<<~RUBY)
            object
              .method_one
                .method_two
              .method_three
          RUBY
        end
      end

      context 'and safe navigation (&.) is used' do
        it 'registers an offense and preserves the operator' do
          expect_offense(<<~RUBY)
            object&.method_one
                  ^^^^^^^^^^^^ Method calls in a multiline chain must each be on their own line.
              &.method_two
          RUBY

          expect_correction(<<~RUBY)
            object
              &.method_one
              &.method_two
          RUBY
        end
      end

      context 'and an intermediate call has multiline arguments' do
        it 'registers offense because the next method must be on its own line' do
          expect_offense(<<~RUBY)
            object.method_one(
              arg1
            ).method_two
             ^^^^^^^^^^^ Method calls in a multiline chain must each be on their own line.
          RUBY

          # O Cop vai jogar o .method_two para a linha de baixo.
          # A indentação será baseada na linha do fechamento do parênteses.
          expect_correction(<<~RUBY)
            object.method_one(
              arg1
            )
              .method_two
          RUBY
        end
      end

      context 'and the violation occurs inside a method definition' do
        it 'calculates indentation based on the receiver position' do
          expect_offense(<<~RUBY)
            def my_method
              my_object.call_one
                       ^^^^^^^^^ Method calls in a multiline chain must each be on their own line.
                .call_two
            end
          RUBY

          expect_correction(<<~RUBY)
            def my_method
              my_object
                .call_one
                .call_two
            end
          RUBY
        end
      end

      context 'and using array access or operators' do
        it 'allows [] to remain on the same line as receiver in a multiline chain' do
          expect_no_offenses(<<~RUBY)
            params[:key]
              .permit(:value)
              .to_h
          RUBY
        end

        it 'allows []= to remain on the same line' do
          expect_no_offenses(<<~RUBY)
            data[:key] = value
              .to_s
              .upcase
          RUBY
        end
      end
    end

    context 'and configuration defines a custom indentation width' do
      let(:config) do
        RuboCop::Config.new(
          'Vicenzo/Layout/MultilineMethodCallLineBreaks' => {
            'IndentationWidth' => 4
          }
        )
      end

      it 'uses the configured indentation width' do
        expect_offense(<<~RUBY)
          object.method_one
                ^^^^^^^^^^^ Method calls in a multiline chain must each be on their own line.
              .method_two
        RUBY

        expect_correction(<<~RUBY)
          object
              .method_one
              .method_two
        RUBY
      end
    end
  end

  context 'when the code follows style guidelines' do
    context 'and the chain is single-line' do
      it 'does not register offense' do
        expect_no_offenses(<<~RUBY)
          object.method_one.method_two
        RUBY
      end
    end

    context 'and the chain has inline arguments' do
      it 'does not register offense' do
        expect_no_offenses(<<~RUBY)
          object.method_one(arg1, arg2).method_two
        RUBY
      end
    end

    context 'and the chain is multiline with correct breaks' do
      it 'does not register offense' do
        expect_no_offenses(<<~RUBY)
          object
            .method_one
            .method_two
        RUBY
      end
    end

    context 'and the multiline structure is caused by arguments' do
      context 'but the newline is strictly inside the arguments block' do
        it 'does not register offense' do
          expect_no_offenses(<<~RUBY)
            object.method_one(
              arg1,
              arg2
            )
          RUBY
        end
      end
    end
  end
end
