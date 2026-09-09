# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::TopLevelLet, :rspec_config do
  describe 'offense detection' do
    context 'when the top-level group declares a let' do
      it 'registers an offense' do
        age_offense = 'Let `:age` is declared in the top-level example group, where it reaches every example in the ' \
                      'file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            let(:age) { 18 }
            ^^^^^^^^^ #{age_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group declares a let!' do
      it 'registers an offense' do
        age_offense = 'Let `:age` is declared in the top-level example group, where it reaches every example in the ' \
                      'file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            let!(:age) { 18 }
            ^^^^^^^^^^ #{age_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group declares a let_it_be' do
      it 'registers an offense' do
        age_offense = 'Let `:age` is declared in the top-level example group, where it reaches every example in the ' \
                      'file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            let_it_be(:age) { 18 }
            ^^^^^^^^^^^^^^^ #{age_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group declares a let_it_be!' do
      it 'registers an offense' do
        age_offense = 'Let `:age` is declared in the top-level example group, where it reaches every example in the ' \
                      'file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            let_it_be!(:age) { 18 }
            ^^^^^^^^^^^^^^^^ #{age_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the let is named with a string' do
      it 'registers an offense' do
        age_offense = 'Let `:age` is declared in the top-level example group, where it reaches every example in the ' \
                      'file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            let('age') { 18 }
            ^^^^^^^^^^ #{age_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the let is named by an expression' do
      it 'registers an offense naming no let' do
        unnamed_offense = 'A let is declared in the top-level example group, where it reaches every example in the ' \
                          'file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            let(PREMISE) { 18 }
            ^^^^^^^^^^^^ #{unnamed_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group holds nothing but examples' do
      it 'registers an offense' do
        age_offense = 'Let `:age` is declared in the top-level example group, where it reaches every example in the ' \
                      'file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            let(:age) { 18 }
            ^^^^^^^^^ #{age_offense}

            it { expect(described_class.new(age: age)).to be_adult }
          end
        RUBY
      end
    end

    context 'when the top-level group is a bare describe' do
      it 'registers an offense' do
        age_offense = 'Let `:age` is declared in the top-level example group, where it reaches every example in the ' \
                      'file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          describe Person do
            let(:age) { 18 }
            ^^^^^^^^^ #{age_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group declares two lets' do
      it 'registers an offense on each one' do
        age_offense = 'Let `:age` is declared in the top-level example group, where it reaches every example in the ' \
                      'file. Declare it in the group whose examples read it.'
        height_offense = 'Let `:height` is declared in the top-level example group, where it reaches every example ' \
                         'in the file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            let(:age) { 18 }
            ^^^^^^^^^ #{age_offense}
            let(:height) { 1.75 }
            ^^^^^^^^^^^^ #{height_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the let is declared in a nested describe' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            describe '#adult?' do
              subject(:person) { described_class.new(age: age) }

              let(:age) { 18 }

              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the let is declared in a nested context' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            describe '#adult?' do
              context 'when the person is of age' do
                subject(:person) { described_class.new(age: age) }

                let(:age) { 18 }

                it { is_expected.to be_adult }
              end
            end
          end
        RUBY
      end
    end

    context 'when the let is declared in shared examples nested in the top-level group' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            shared_examples 'an adult' do
              let(:age) { 18 }

              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level block is not an example group' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.shared_examples 'an adult' do
            let(:age) { 18 }

            it { is_expected.to be_adult }
          end
        RUBY
      end
    end

    context 'when the top-level group declares a subject' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            subject(:person) { described_class.new }

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group declares a before hook' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            before { travel_to(Time.zone.local(2026, 1, 1)) }

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end
  end
end
