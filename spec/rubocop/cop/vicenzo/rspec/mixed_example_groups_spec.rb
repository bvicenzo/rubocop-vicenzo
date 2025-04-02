# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::MixedExampleGroups, :rspec_config do
  context 'when an example and a group exist at the same level' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          it { is_expected.to validate_presence_of(:name) }
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not mix examples (`it`, `specify`, `example`) with groups (`describe`, `context`) at the same level.
          describe '#admin?' do
          ^^^^^^^^^^^^^^^^^^^^^ Do not mix examples (`it`, `specify`, `example`) with groups (`describe`, `context`) at the same level.
            it { expect(true).to eq(true) }
          end
        end
      RUBY
    end
  end

  context 'when a nested example and group exist at the same level' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe User do
          describe '#admin?' do
            it { expect(true).to eq(true) }
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not mix examples (`it`, `specify`, `example`) with groups (`describe`, `context`) at the same level.
            context 'when email starts with' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not mix examples (`it`, `specify`, `example`) with groups (`describe`, `context`) at the same level.
            end
          end
        end
      RUBY
    end
  end

  context 'when only examples exist' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          it { is_expected.to validate_presence_of(:name) }
          it { expect(true).to eq(true) }
        end
      RUBY
    end
  end

  context 'when all examples are not mixed with groups' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe User do
          describe '#admin?' do
            context 'when email starts with' do
              it { expect(true).to eq(true) }
            end

            context 'when email ends with' do
              it { expect(true).to eq(true) }
            end
          end
        end
      RUBY
    end
  end
end
