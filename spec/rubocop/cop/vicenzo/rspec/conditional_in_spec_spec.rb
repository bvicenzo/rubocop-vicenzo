# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::ConditionalInSpec, :rspec_config do
  context 'when if is used inside an it block' do
    it 'registers an offense on the if keyword' do
      expect_offense(<<~RUBY)
        it 'grants or denies access' do
          if user.admin?
          ^^ Do not use conditional logic in specs. Extract each branch into an explicit context instead.
            expect(result).to eq(:granted)
          end
        end
      RUBY
    end
  end

  context 'when unless is used inside an it block' do
    it 'registers an offense on the unless keyword' do
      expect_offense(<<~RUBY)
        it 'denies access for non-admins' do
          unless user.admin?
          ^^^^^^ Do not use conditional logic in specs. Extract each branch into an explicit context instead.
            expect(result).to eq(:denied)
          end
        end
      RUBY
    end
  end

  context 'when a modifier if is used inside a before hook' do
    it 'registers an offense on the if keyword' do
      expect_offense(<<~RUBY)
        before { setup_thing if feature_enabled? }
                             ^^ Do not use conditional logic in specs. Extract each branch into an explicit context instead.
      RUBY
    end
  end

  context 'when a modifier unless is used inside a before hook' do
    it 'registers an offense on the unless keyword' do
      expect_offense(<<~RUBY)
        before { setup_thing unless feature_disabled? }
                             ^^^^^^ Do not use conditional logic in specs. Extract each branch into an explicit context instead.
      RUBY
    end
  end

  context 'when a ternary is used inside a let' do
    it 'registers an offense on the ternary expression' do
      expect_offense(<<~RUBY)
        let(:user) { admin? ? create(:admin) : create(:client) }
                     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use conditional logic in specs. Extract each branch into an explicit context instead.
      RUBY
    end
  end

  context 'when unless is used at the example group level' do
    it 'registers an offense on the unless keyword' do
      expect_offense(<<~RUBY)
        unless legacy_mode?
        ^^^^^^ Do not use conditional logic in specs. Extract each branch into an explicit context instead.
          it 'uses the new behaviour' do
          end
        end
      RUBY
    end
  end

  context 'when if is used at the example group level' do
    it 'registers an offense on the if keyword' do
      expect_offense(<<~RUBY)
        if created_by == :whatsapp_driver
        ^^ Do not use conditional logic in specs. Extract each branch into an explicit context instead.
          it 'has exclusive whatsapp driver behaviour' do
          end
        end
      RUBY
    end
  end

  context 'when if is used inside a subject' do
    it 'registers an offense on the if keyword' do
      expect_offense(<<~RUBY)
        subject(:result) do
          if user.admin?
          ^^ Do not use conditional logic in specs. Extract each branch into an explicit context instead.
            :granted
          else
            :denied
          end
        end
      RUBY
    end
  end
end
