# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::InconsistentSiblingStructure, :rspec_config do
  context 'when mixing examples with describe groups' do
    it 'registers an offense on the describe block' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          it { is_expected.to validate_presence_of(:name) }

          describe '#admin?' do
          ^^^^^^^^^^^^^^^^^^^^^ Do not mix example with describe at the same level.
            it { expect(true).to eq(true) }
          end
        end
      RUBY
    end
  end

  context 'when mixing examples with context groups' do
    it 'registers an offense on the context block' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          it { is_expected.to validate_presence_of(:name) }

          context 'when valid' do
          ^^^^^^^^^^^^^^^^^^^^^^^ Do not mix example with context at the same level.
            it { expect(true).to eq(true) }
          end
        end
      RUBY
    end
  end

  context 'when mixing describe with context groups' do
    it 'registers an offense on the context block' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          describe '#admin?' do
            it { expect(true).to be_truthy }
          end

          context 'when user is logged out' do
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not mix describe with context at the same level.
            it { expect(true).to be_falsey }
          end
        end
      RUBY
    end
  end

  context 'when the group contains only examples' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          it { is_expected.to validate_presence_of(:name) }
          it { expect(true).to eq(true) }
        end
      RUBY
    end
  end

  context 'when the group contains only describe blocks' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          describe '#admin?' do
            it { expect(true).to eq(true) }
          end

          describe '#client?' do
            it { expect(false).to eq(false) }
          end
        end
      RUBY
    end
  end

  context 'when the group contains only context blocks' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          context 'when valid' do
            it { expect(true).to eq(true) }
          end

          context 'when invalid' do
            it { expect(false).to eq(false) }
          end
        end
      RUBY
    end
  end

  context 'when offense is deep inside a structure' do
    it 'registers an offense inside a nested describe' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          describe '#foo' do
            describe '#bar' do
              it { expect(1).to eq(1) }

              context 'when nested' do
              ^^^^^^^^^^^^^^^^^^^^^^^^ Do not mix example with context at the same level.
              end
            end
          end
        end
      RUBY
    end
  end
end
