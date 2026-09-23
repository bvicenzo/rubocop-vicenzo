# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::DescribeInsideContext, :rspec_config do
  describe 'offense detection' do
    context 'when a describe is nested straight in a context' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          RSpec.describe Person do
            context 'when the person is a minor' do
              describe '#adult?' do
              ^^^^^^^^^^^^^^^^^^ Do not describe inside a context: a context is a scenario of the behaviour a describe names. Describe the behaviour first and repeat the context under each describe that needs it. If this block states a circumstance, it is a context.
                it { is_expected.not_to be_adult }
              end
            end
          end
        RUBY
      end
    end

    context 'when a focused describe is nested in a context' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          RSpec.describe Person do
            context 'when the person is a minor' do
              fdescribe '#adult?' do
              ^^^^^^^^^^^^^^^^^^^ Do not describe inside a context: a context is a scenario of the behaviour a describe names. Describe the behaviour first and repeat the context under each describe that needs it. If this block states a circumstance, it is a context.
                it { is_expected.not_to be_adult }
              end
            end
          end
        RUBY
      end
    end

    context 'when a feature is nested in a context' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          RSpec.describe 'Sign up' do
            context 'when the visitor has an invitation' do
              feature 'filling in the form' do
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not describe inside a context: a context is a scenario of the behaviour a describe names. Describe the behaviour first and repeat the context under each describe that needs it. If this block states a circumstance, it is a context.
                it { is_expected.to be_valid }
              end
            end
          end
        RUBY
      end
    end

    context 'when an explicit RSpec.describe is nested in a context' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          context 'when the person is a minor' do
            RSpec.describe Person do
            ^^^^^^^^^^^^^^^^^^^^^ Do not describe inside a context: a context is a scenario of the behaviour a describe names. Describe the behaviour first and repeat the context under each describe that needs it. If this block states a circumstance, it is a context.
              it { is_expected.not_to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when a describe nested in a context holds another describe' do
      it 'registers an offense only for the outer one' do
        expect_offense(<<~RUBY)
          RSpec.describe Person do
            context 'when the person is a minor' do
              describe 'eligibility' do
              ^^^^^^^^^^^^^^^^^^^^^^ Do not describe inside a context: a context is a scenario of the behaviour a describe names. Describe the behaviour first and repeat the context under each describe that needs it. If this block states a circumstance, it is a context.
                describe '#adult?' do
                  it { is_expected.not_to be_adult }
                end
              end
            end
          end
        RUBY
      end
    end

    context 'when a describe is nested in a context at more than one level' do
      it 'registers an offense for each of them' do
        expect_offense(<<~RUBY)
          RSpec.describe Person do
            context 'when the person is a minor' do
              describe '#adult?' do
              ^^^^^^^^^^^^^^^^^^ Do not describe inside a context: a context is a scenario of the behaviour a describe names. Describe the behaviour first and repeat the context under each describe that needs it. If this block states a circumstance, it is a context.
                context 'and the person is emancipated' do
                  describe '#voter?' do
                  ^^^^^^^^^^^^^^^^^^ Do not describe inside a context: a context is a scenario of the behaviour a describe names. Describe the behaviour first and repeat the context under each describe that needs it. If this block states a circumstance, it is a context.
                    it { is_expected.not_to be_voter }
                  end
                end
              end
            end
          end
        RUBY
      end
    end

    context 'when the tree follows describe, context and example' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            describe '#adult?' do
              context 'when the person is a minor' do
                it { is_expected.not_to be_adult }
              end
            end
          end
        RUBY
      end
    end

    context 'when a describe is nested in another describe' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Person do
            describe 'eligibility' do
              describe '#adult?' do
                it { is_expected.to be_adult }
              end
            end
          end
        RUBY
      end
    end

    context 'when a context is nested in another context' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          describe '#adult?' do
            context 'when the person is a minor' do
              context 'and the person is emancipated' do
                it { is_expected.not_to be_adult }
              end
            end
          end
        RUBY
      end
    end

    context 'when an example group alias added to the RSpec language is nested in a context' do
      before { other_cops.dig('RSpec', 'Language', 'ExampleGroups', 'Regular') << 'response' }

      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          describe 'GET /people' do
            context 'when the person exists' do
              response '200', 'person found' do
                it { is_expected.to be_ok }
              end
            end
          end
        RUBY
      end
    end

    context 'when a describe is nested in a shared context' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          shared_context 'with a minor' do
            describe '#adult?' do
              it { is_expected.not_to be_adult }
            end
          end
        RUBY
      end
    end

    context 'when a describe is nested in shared examples' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          shared_examples 'a minor' do
            describe '#adult?' do
              it { is_expected.not_to be_adult }
            end
          end
        RUBY
      end
    end
  end
end
