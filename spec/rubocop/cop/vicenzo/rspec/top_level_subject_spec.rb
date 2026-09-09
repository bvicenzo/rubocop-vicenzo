# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::TopLevelSubject, :rspec_config do
  describe 'offense detection' do
    context 'when the top-level group declares a named subject' do
      it 'registers an offense' do
        person_offense = 'Subject `:person` is declared in the top-level example group, where it reaches every ' \
                         'example in the file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            subject(:person) { described_class.new }
            ^^^^^^^^^^^^^^^^ #{person_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group declares an anonymous subject' do
      it 'registers an offense' do
        anonymous_offense = 'The subject is declared in the top-level example group, where it reaches every example ' \
                            'in the file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            subject { described_class.new }
            ^^^^^^^ #{anonymous_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group declares a subject!' do
      it 'registers an offense' do
        person_offense = 'Subject `:person` is declared in the top-level example group, where it reaches every ' \
                         'example in the file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            subject!(:person) { described_class.new }
            ^^^^^^^^^^^^^^^^^ #{person_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the subject is named by an expression' do
      it 'registers an offense naming no subject' do
        anonymous_offense = 'The subject is declared in the top-level example group, where it reaches every example ' \
                            'in the file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            subject(PREMISE) { described_class.new }
            ^^^^^^^^^^^^^^^^ #{anonymous_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group holds nothing but examples' do
      it 'registers an offense' do
        person_offense = 'Subject `:person` is declared in the top-level example group, where it reaches every ' \
                         'example in the file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            subject(:person) { described_class.new }
            ^^^^^^^^^^^^^^^^ #{person_offense}

            it { is_expected.to be_adult }
          end
        RUBY
      end
    end

    context 'when the top-level group is a bare describe' do
      it 'registers an offense' do
        person_offense = 'Subject `:person` is declared in the top-level example group, where it reaches every ' \
                         'example in the file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          describe Person do
            subject(:person) { described_class.new }
            ^^^^^^^^^^^^^^^^ #{person_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the top-level group declares two subjects' do
      it 'registers an offense on each one' do
        person_offense = 'Subject `:person` is declared in the top-level example group, where it reaches every ' \
                         'example in the file. Declare it in the group whose examples read it.'
        other_offense = 'Subject `:other` is declared in the top-level example group, where it reaches every ' \
                        'example in the file. Declare it in the group whose examples read it.'

        expect_offense(<<~RUBY)
          RSpec.describe Person do
            subject(:person) { described_class.new }
            ^^^^^^^^^^^^^^^^ #{person_offense}
            subject(:other) { described_class.new }
            ^^^^^^^^^^^^^^^ #{other_offense}

            describe '#adult?' do
              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the subject is declared in a nested describe' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            describe '#adult?' do
              subject(:person) { described_class.new(age: 18) }

              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when the subject is declared in a nested context' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            describe '#adult?' do
              context 'when the person is of age' do
                subject(:person) { described_class.new(age: 18) }

                it { is_expected.to be_adult }
              end
            end
          end
        RUBY
      end
    end

    context 'when the subject is declared in shared examples nested in the top-level group' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            shared_examples 'an adult' do
              subject(:person) { described_class.new(age: 18) }

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
            subject(:person) { described_class.new(age: 18) }

            it { is_expected.to be_adult }
          end
        RUBY
      end
    end

    context 'when the top-level group declares a let' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            let(:age) { 18 }

            describe '#adult?' do
              subject(:person) { described_class.new(age: age) }

              it { is_expected.to be_adult }
            end
          end
        RUBY
      end
    end
  end
end
