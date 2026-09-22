# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::Naming::ShortName, :config do
  describe 'offense detection' do
    context 'when the code violates style guidelines' do
      context 'and a local variable is a single letter' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            v = shelf.capacity
            ^ Name `v` spells 1 letter(s); at least 3 are required. A letter or an abbreviation carries no meaning to the next reader — write the whole word, in the language of the domain (`waiting_time`), not a shapeless label (`key`, `value`, `item`).
          RUBY
        end
      end

      context 'and a local variable spells two letters' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            id = catalog.first
            ^^ Name `id` spells 2 letter(s); at least 3 are required. [...]
          RUBY
        end
      end

      context 'and a multiple assignment target is a single letter' do
        it 'registers an offense for each target' do
          expect_offense(<<~RUBY)
            x, y = coordinates
               ^ Name `y` spells 1 letter(s); at least 3 are required. [...]
            ^ Name `x` spells 1 letter(s); at least 3 are required. [...]
          RUBY
        end
      end

      context 'and underscores are the only thing padding the name' do
        it 'registers an offense, since underscores spell no letter' do
          expect_offense(<<~RUBY)
            a_b = shelf.capacity
            ^^^ Name `a_b` spells 2 letter(s); at least 3 are required. [...]
          RUBY
        end
      end

      context 'and an unused local variable is a single letter' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            _p = catalog.first
            ^^ Name `_p` spells 1 letter(s); at least 3 are required. [...]
          RUBY
        end
      end

      context 'and a for loop variable is a single letter' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            for i in catalog
                ^ Name `i` spells 1 letter(s); at least 3 are required. [...]
              reserve(i)
            end
          RUBY
        end
      end

      context 'and the keyword argument receives the variable explicitly' do
        it 'registers an offense, since the name was not imposed by the signature' do
          expect_offense(<<~RUBY)
            def measure
              h = 10
              ^ Name `h` spells 1 letter(s); at least 3 are required. [...]
              area(height: h)
            end
          RUBY
        end
      end

      context 'and the shorthand that would excuse it lives in another scope' do
        let(:ruby_version) { 3.4 }

        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def measure
              h = 10
              ^ Name `h` spells 1 letter(s); at least 3 are required. [...]
              h
            end

            def elsewhere
              area(h:)
            end
          RUBY
        end
      end
    end

    context 'when the code follows style guidelines' do
      context 'and the local variable spells whole words' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            volume = shelf.capacity
            available_books = shelf.capacity
            column, row = coordinates
          RUBY
        end
      end

      context 'and the name is made only of underscores' do
        it 'does not register an offense, since it belongs to Vicenzo/Naming/AnonymousUnusedName' do
          expect_no_offenses(<<~RUBY)
            _ = catalog.first
          RUBY
        end
      end

      context 'and the variable feeds a keyword argument shorthand' do
        let(:ruby_version) { 3.4 }

        it 'does not register an offense, since the signature imposed the name' do
          expect_no_offenses(<<~RUBY)
            def measure
              h = 10
              w = 15
              area(h:, w:)
            end
          RUBY
        end
      end

      context 'and the short name is a rescued error' do
        it 'does not register an offense, since it belongs to Naming/RescuedExceptionsVariableName' do
          expect_no_offenses(<<~RUBY)
            begin
              shelf.reorder
            rescue ShelfLocked => e
              shelf.skip
            end
          RUBY
        end
      end

      context 'and the short name is a block parameter' do
        it 'does not register an offense, since it belongs to Naming/BlockParameterName' do
          expect_no_offenses(<<~RUBY)
            catalog.each { |wp| reserve(wp) }
          RUBY
        end
      end

      context 'and the short name is a method parameter' do
        it 'does not register an offense, since it belongs to Naming/MethodParameterName' do
          expect_no_offenses(<<~RUBY)
            def area(h:, w:)
              h * w
            end
          RUBY
        end
      end
    end

    context 'when MinNameLength is configured' do
      let(:cop_config) { { 'MinNameLength' => 5 } }

      context 'and the name is shorter than the configured minimum' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            book = build
            ^^^^ Name `book` spells 4 letter(s); at least 5 are required. [...]
          RUBY
        end
      end

      context 'and the name reaches the configured minimum' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            book_title = build
          RUBY
        end
      end
    end
  end
end
