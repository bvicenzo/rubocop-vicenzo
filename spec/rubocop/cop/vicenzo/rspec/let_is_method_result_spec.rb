# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::LetIsMethodResult, :rspec_config do
  let(:catch_offense) do
    'Let `:catch` holds what `catch` returned. ' \
      'Undo it and call `catch` on the subject inside the expectation.'
  end

  context 'when the let calls the described method on a named subject' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject(:cat) { Cat.new }

            let(:catch) { cat.catch(ball) }
                          ^^^^^^^^^^^^^^^ #{catch_offense}

            it { expect(catch).to eq(:success) }
          end
        end
      RUBY
    end
  end

  context 'when the let calls the described method on the anonymous subject' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject { Cat.new }

            let(:catch) { subject.catch(ball) }
                          ^^^^^^^^^^^^^^^^^^^ #{catch_offense}
          end
        end
      RUBY
    end
  end

  context 'when no subject is declared' do
    it 'registers an offense for a call on the implicit subject' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            let(:catch) { subject.catch(ball) }
                          ^^^^^^^^^^^^^^^^^^^ #{catch_offense}
          end
        end
      RUBY
    end
  end

  context 'when the let derives a value from the call' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject(:cat) { Cat.new }

            let(:catch) { cat.catch(ball).to_s }
                          ^^^^^^^^^^^^^^^ #{catch_offense}
          end
        end
      RUBY
    end
  end

  context 'when the let is eagerly evaluated' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject(:cat) { Cat.new }

            let!(:catch) { cat.catch(ball) }
                           ^^^^^^^^^^^^^^^ #{catch_offense}
          end
        end
      RUBY
    end
  end

  context 'when the let is a let_it_be' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject(:cat) { Cat.new }

            let_it_be(:catch) { cat.catch(ball) }
                                ^^^^^^^^^^^^^^^ #{catch_offense}
          end
        end
      RUBY
    end
  end

  context 'when the let body spans multiple lines' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject(:cat) { Cat.new }

            let(:catch) do
              cat.catch(object: ball)
              ^^^^^^^^^^^^^^^^^^^^^^^ #{catch_offense}
            end
          end
        end
      RUBY
    end
  end

  context 'when the let sits in a nested context' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject(:cat) { Cat.new }

            context 'when the cat is hungry' do
              let(:catch) { cat.catch(ball) }
                            ^^^^^^^^^^^^^^^ #{catch_offense}
            end
          end
        end
      RUBY
    end
  end

  context 'when the description is a bare method name' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe 'catch' do
            subject(:cat) { Cat.new }

            let(:catch) { cat.catch(ball) }
                          ^^^^^^^^^^^^^^^ #{catch_offense}
          end
        end
      RUBY
    end
  end

  context 'when the let calls the described method on another object' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject(:cat) { Cat.new }

            let(:taken_ball) { other_cat.catch(ball) }
          end
        end
      RUBY
    end
  end

  context 'when the let calls another method on the subject' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject(:cat) { Cat.new }

            let(:name) { cat.name }
          end
        end
      RUBY
    end
  end

  context 'when the subject itself holds the call' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject(:catch) { Cat.new.catch(ball) }
          end
        end
      RUBY
    end
  end

  context 'when the call reaches only an argument' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject(:cat) { Cat.new }

            let(:ball) { Ball.new(taken_by: cat.catch(other_ball)) }
          end
        end
      RUBY
    end
  end

  context 'when the description is prose' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Cat do
          describe 'catching a ball' do
            subject(:cat) { Cat.new }

            let(:catch) { cat.catch(ball) }
          end
        end
      RUBY
    end
  end

  context 'when the let is outside a method example group' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Cat do
          subject(:cat) { Cat.new }

          let(:catch) { cat.catch(ball) }
        end
      RUBY
    end
  end

  context 'when AllowedMethods lists the described method' do
    let(:cop_config) { { 'AllowedMethods' => %w[call] } }

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Cat do
          describe '.call' do
            subject(:service) { described_class.new }

            let(:result) { service.call(object: ball) }
          end
        end
      RUBY
    end
  end
end
