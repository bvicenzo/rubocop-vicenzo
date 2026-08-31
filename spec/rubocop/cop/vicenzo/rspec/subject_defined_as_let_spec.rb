# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::SubjectDefinedAsLet, :rspec_config do
  let(:service_offense) do
    'Let `:service` is what the expectations assert on, so it is the subject. ' \
      'Declare it with `subject(:service)`.'
  end

  context 'when the expectation asserts on the let' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Order::Cancel do
          describe '.call' do
            let(:service) { described_class.(order_id: 42) }
            ^^^^^^^^^^^^^ #{service_offense}

            it { expect(service).to be_failure }
          end
        end
      RUBY
    end
  end

  context 'when the expectation wraps the let in a block' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Order::Cancel do
          describe '.call' do
            let(:service) { described_class.(order_id: 42) }
            ^^^^^^^^^^^^^ #{service_offense}

            it { expect { service }.to change(Order, :count).by(1) }
          end
        end
      RUBY
    end
  end

  context 'when the expectation lives in a nested context' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Order::Cancel do
          describe '.call' do
            let(:service) { described_class.(order_id: 42) }
            ^^^^^^^^^^^^^ #{service_offense}

            context 'when the order is unknown' do
              it { expect(service).to be_failure }
            end
          end
        end
      RUBY
    end
  end

  context 'when sibling contexts each redefine the let' do
    it 'registers an offense on every definition' do
      expect_offense(<<~RUBY)
        RSpec.describe Order::Cancel do
          describe '.call' do
            context 'when the order is unknown' do
              let(:service) { described_class.(order_id: 42) }
              ^^^^^^^^^^^^^ #{service_offense}

              it { expect(service).to be_failure }
            end

            context 'when the order exists' do
              let(:service) { described_class.(order_id: 7) }
              ^^^^^^^^^^^^^ #{service_offense}

              it { expect(service).to be_success }
            end
          end
        end
      RUBY
    end
  end

  context 'when the definition is a let_it_be' do
    it 'registers an offense' do
      expect_offense(<<~RUBY)
        RSpec.describe Order::Cancel do
          describe '.call' do
            let_it_be(:service) { described_class.(order_id: 42) }
            ^^^^^^^^^^^^^^^^^^^ #{service_offense}

            it { expect(service).to be_failure }
          end
        end
      RUBY
    end
  end

  context 'when the group declares a subject' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Order::Cancel do
          describe '.call' do
            subject(:result) { described_class.(order_id: 42) }

            let(:service) { described_class.(line_ids: 777) }

            it { expect(service).to be_failure }
          end
        end
      RUBY
    end
  end

  context 'when an ancestor group declares the subject' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Order::Cancel do
          subject(:result) { described_class.(order_id: 42) }

          describe '.call' do
            let(:service) { described_class.(line_ids: 777) }

            it { expect(service).to be_failure }
          end
        end
      RUBY
    end
  end

  context 'when the expectation only reads through the let' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Book do
          describe '#author' do
            let(:trip) { create(:book, author: author) }
            let(:author) { create(:author) }

            it { expect(book.author).to eq(author) }
          end
        end
      RUBY
    end
  end

  context 'when the let is never asserted on' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Order::Cancel do
          describe '.call' do
            let(:line_ids) { [1, 2] }

            it { expect(described_class.(line_ids: line_ids)).to be_successful }
          end
        end
      RUBY
    end
  end

  context 'when a sibling let is asserted on as well' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Post do
          describe '#approved?' do
            let!(:reviewed_post) { create(:post, verification_comment: 'comment') }
            let!(:draft_post) { create(:post) }

            it { expect(reviewed_post).to be_approved }
            it { expect(draft_post).not_to be_approved }
          end
        end
      RUBY
    end
  end

  context 'when AllowedMethods lists the method the let calls' do
    let(:cop_config) { { 'AllowedMethods' => %w[call] } }

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Order::Cancel do
          describe '.call' do
            let(:service) { described_class.(order_id: 42) }

            it { expect(service).to be_failure }
          end
        end
      RUBY
    end
  end
end
