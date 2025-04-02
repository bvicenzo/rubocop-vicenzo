# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::NestedContextImproperStart, :rspec_config do
  context 'when a single context is used' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        context 'when the product is for sale' do
          it 'is available for purchase'
        end
      RUBY
    end
  end

  context 'when inner context starts with when' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        context 'when the product is for sale' do
          context 'when the color pink is not available' do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Nested `context` should start with `and`, `but`, or `however`, not `when`, `with`, or `without`.
            it 'does not show the pink option'
          end
        end
      RUBY
    end
  end

  context 'when inner context starts with with' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        context 'when the product is for sale' do
          context 'with the color pink unavailable' do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Nested `context` should start with `and`, `but`, or `however`, not `when`, `with`, or `without`.
            it 'does not show the pink option'
          end
        end
      RUBY
    end
  end

  context 'when inner context starts with without' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        context 'when the product is for sale' do
          context 'without the color pink available' do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Nested `context` should start with `and`, `but`, or `however`, not `when`, `with`, or `without`.
            it 'does not show the pink option'
          end
        end
      RUBY
    end
  end

  context 'when inner context starts with and' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        context 'when the product is for sale' do
          context 'and the color pink is not available' do
            it 'does not show the pink option'
          end
        end
      RUBY
    end
  end

  context 'when inner context starts with but' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        context 'when the product is for sale' do
          context 'but the color pink is not available' do
            it 'does not show the pink option'
          end
        end
      RUBY
    end
  end

  context 'when inner context starts with however' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        context 'when the product is for sale' do
          context 'however, the color pink is not available' do
            it 'does not show the pink option'
          end
        end
      RUBY
    end
  end
end
