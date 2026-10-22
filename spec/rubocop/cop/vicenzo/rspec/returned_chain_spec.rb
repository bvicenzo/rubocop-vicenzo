# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::ReturnedChain do
  describe '#expression' do
    subject(:chain) { described_class.new(body) }

    let(:body) { RuboCop::AST::ProcessedSource.new(source, 3.3).ast }

    context 'when the body is empty' do
      let(:source) { '' }

      it { expect(chain.expression).to be_nil }
    end

    context 'when the body is a single statement' do
      let(:source) { 'Cat.new.catch(ball)' }

      it { expect(chain.expression.source).to eq('Cat.new.catch(ball)') }
    end

    context 'when the body has several statements' do
      let(:source) { "ball.inflate\nCat.new.catch(ball)" }

      it { expect(chain.expression.source).to eq('Cat.new.catch(ball)') }
    end
  end

  describe '#each' do
    subject(:chain) { described_class.new(body) }

    let(:body) { RuboCop::AST::ProcessedSource.new(source, 3.3).ast }

    context 'when the body is empty' do
      let(:source) { '' }

      it { expect(chain.to_a).to be_empty }
    end

    context 'when the body has a value' do
      context 'but the value is neither a call nor something that passes one along' do
        let(:source) { ':ball' }

        it { expect(chain.to_a).to be_empty }
      end

      context 'and the value is a call' do
        context 'and its receiver is not a call' do
          let(:source) { 'Cat.new' }

          it { expect(chain.map(&:method_name)).to eq(%i[new]) }
        end

        context 'and its receiver is a call' do
          let(:source) { 'Cat.new.catch(ball).to_s' }

          it { expect(chain.map(&:method_name)).to eq(%i[to_s catch new]) }
        end

        context 'and a call reaches the value only as an argument' do
          let(:source) { 'Cat.new(catches: other_cat.catch(ball))' }

          it { expect(chain.map(&:method_name)).to eq(%i[new]) }
        end

        context 'and a call uses safe navigation' do
          let(:source) { 'Cat.new&.catch(ball)' }

          it { expect(chain.map(&:method_name)).to eq(%i[catch new]) }
        end

        context 'and a call takes a block' do
          let(:source) { 'Cat.new.tap { |cat| cat.purr }.catch(ball)' }

          it { expect(chain.map(&:method_name)).to eq(%i[catch tap new]) }
        end
      end

      context 'and the value is wrapped in parentheses' do
        context 'and they hold one statement' do
          let(:source) { '(Cat.new.catch(ball)).to_s' }

          it { expect(chain.map(&:method_name)).to eq(%i[to_s catch new]) }
        end

        context 'and they hold several statements' do
          let(:source) { '(ball.inflate; Cat.new).catch(ball)' }

          it { expect(chain.map(&:method_name)).to eq(%i[catch new]) }
        end
      end

      context 'and the value is an assignment' do
        let(:source) { 'caught = Cat.new.catch(ball)' }

        it { expect(chain.map(&:method_name)).to eq(%i[catch new]) }
      end

      context 'and the value reads a local variable' do
        context 'but it is assigned only inside another statement' do
          let(:source) { "adopt(caught = Cat.new.catch(ball))\ncaught.to_s" }

          it { expect(chain.map(&:method_name)).to eq(%i[to_s]) }
        end

        context 'and an earlier statement assigns it' do
          context 'and only once' do
            let(:source) { "caught = Cat.new.catch(ball)\ncaught.to_s" }

            it { expect(chain.map(&:method_name)).to eq(%i[to_s catch new]) }
          end

          context 'and more than once' do
            let(:source) { "caught = Cat.adopt\ncaught = Dog.new\ncaught.to_s" }

            it { expect(chain.map(&:method_name)).to eq(%i[to_s new]) }
          end

          context 'and the assignment reads the variable itself' do
            let(:source) { "caught = Cat.new\ncaught = caught.catch(ball)\ncaught.to_s" }

            it { expect(chain.map(&:method_name)).to eq(%i[to_s catch new]) }
          end
        end
      end
    end
  end
end
