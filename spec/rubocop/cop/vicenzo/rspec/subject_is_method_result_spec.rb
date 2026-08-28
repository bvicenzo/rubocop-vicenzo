# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::SubjectIsMethodResult, :rspec_config do
  let(:catch_offense) do
    'Subject holds what `catch` returned, not the object under test. ' \
      'Make the subject the object that receives `catch`, and call it inside the example.'
  end

  context 'when the example group describes an instance method' do
    context 'and the subject invokes it on a new instance' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          RSpec.describe Cat do
            describe '#catch' do
              subject(:catch) { Cat.new.catch(ball) }
                                ^^^^^^^^^^^^^^^^^^^ #{catch_offense}

              it { is_expected.to eq(:success) }
            end
          end
        RUBY
      end
    end

    context 'and the subject invokes it on a let' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          RSpec.describe Cat do
            describe '#catch' do
              subject(:catch) { cat.catch(ball) }
                                ^^^^^^^^^^^^^^^ #{catch_offense}

              let(:cat) { Cat.new }
            end
          end
        RUBY
      end
    end

    context 'and the description carries the method signature' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          RSpec.describe Cat do
            describe '#catch(object:)' do
              subject(:catch) { cat.catch(object: ball) }
                                ^^^^^^^^^^^^^^^^^^^^^^^ #{catch_offense}
            end
          end
        RUBY
      end
    end

    context 'and the subject is the object under test' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Cat do
            describe '#catch' do
              subject(:cat) { Cat.new }

              it { expect(cat.catch(ball)).to eq(:success) }
            end
          end
        RUBY
      end
    end
  end

  context 'when the example group describes a class method' do
    context 'and the subject invokes it on the described class' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          RSpec.describe Cat do
            describe '.catch' do
              subject(:catch) { described_class.catch(ball) }
                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{catch_offense}
            end
          end
        RUBY
      end
    end

    context 'and the subject invokes it on a new instance' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          RSpec.describe Cat do
            describe '.catch' do
              subject(:catch) { Cat.new.catch(ball) }
                                ^^^^^^^^^^^^^^^^^^^ #{catch_offense}
            end
          end
        RUBY
      end
    end
  end

  context 'when the description is a bare method name' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe 'catch' do
            subject(:catch) { Cat.new.catch(ball) }
                              ^^^^^^^^^^^^^^^^^^^ #{catch_offense}
          end
        end
      RUBY
    end
  end

  context 'when the subject is anonymous' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject { Cat.new.catch(ball) }
                      ^^^^^^^^^^^^^^^^^^^ #{catch_offense}
          end
        end
      RUBY
    end
  end

  context 'when the subject is eagerly evaluated' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject!(:catch) { Cat.new.catch(ball) }
                               ^^^^^^^^^^^^^^^^^^^ #{catch_offense}
          end
        end
      RUBY
    end
  end

  context 'when the subject body spans multiple lines' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject(:catch) do
              Cat.new(name: 'Bixano').catch(object: ball)
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{catch_offense}
            end
          end
        end
      RUBY
    end
  end

  context 'when the subject is nested in a context' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            context 'when the cat is hungry' do
              subject(:catch) { hungry_cat.catch(ball) }
                                ^^^^^^^^^^^^^^^^^^^^^^ #{catch_offense}
            end
          end
        end
      RUBY
    end
  end

  context 'when a nested example group describes another method' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            describe '#hungry?' do
              subject(:hungry) { cat.catch(ball) }
            end
          end
        end
      RUBY
    end
  end

  context 'when the described method name has no receiver' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Trip do
          describe '#driver' do
            subject(:trip) { create(:trip, driver: driver) }

            let(:driver) { create(:driver) }
          end
        end
      RUBY
    end
  end

  context 'when the described method is called in an argument' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Cat do
          describe '#catch' do
            subject(:cat) { Cat.new(catches: other_cat.catch(ball)) }
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
            subject(:catch) { Cat.new.catch(ball) }
          end
        end
      RUBY
    end
  end

  context 'when the example group describes a class' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Cat do
          subject(:catch) { Cat.new.catch(ball) }
        end
      RUBY
    end
  end

  context 'when the subject invokes the method through an implicit call' do
    let(:call_offense) do
      'Subject holds what `call` returned, not the object under test. ' \
        'Make the subject the object that receives `call`, and call it inside the example.'
    end

    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Cat do
          describe '.call' do
            subject(:result) { described_class.(object: ball) }
                               ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ #{call_offense}
          end
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
            subject(:result) { described_class.(object: ball) }
          end
        end
      RUBY
    end
  end
end
