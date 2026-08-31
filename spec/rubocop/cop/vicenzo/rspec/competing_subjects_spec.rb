# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::CompetingSubjects, :rspec_config do
  let(:post_offense) do
    'The expectations here are about `:reviewed_post`, `:draft_post`, ' \
      'so this group has no one subject. ' \
      'Work out what these definitions are to it, and let the structure say so.'
  end

  context 'when two definitions are each asserted on' do
    it 'registers an offense on the group' do
      expect_offense(<<~RUBY)
        RSpec.describe Post do
          describe '#approved?' do
          ^^^^^^^^^^^^^^^^^^^^^ #{post_offense}
            let!(:reviewed_post) { create(:post, reviewed_at: Time.current) }
            let!(:draft_post) { create(:post) }

            it { expect(reviewed_post).to be_approved }
            it { expect(draft_post).not_to be_approved }
          end
        end
      RUBY
    end
  end

  context 'when both definitions are asserted in a single example' do
    it 'registers an offense on the group' do
      expect_offense(<<~RUBY)
        RSpec.describe Post do
          describe '#approved?' do
          ^^^^^^^^^^^^^^^^^^^^^ #{post_offense}
            let!(:reviewed_post) { create(:post, reviewed_at: Time.current) }
            let!(:draft_post) { create(:post) }

            it 'tells them apart', :aggregate_failures do
              expect(reviewed_post).to be_approved
              expect(draft_post).not_to be_approved
            end
          end
        end
      RUBY
    end
  end

  context 'when only one definition is asserted on' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Post do
          describe '#approved?' do
            let!(:reviewed_post) { create(:post, reviewed_at: Time.current) }
            let!(:rating) { 5 }

            it { expect(reviewed_post).to be_approved }
          end
        end
      RUBY
    end
  end

  context 'when the group declares a subject' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Post do
          describe '#approved?' do
            subject(:post) { create(:post, reviewed_at: Time.current) }

            let!(:other_feedback) { create(:post) }
            let!(:third_feedback) { create(:post) }

            it { expect(other_feedback).to be_approved }
            it { expect(third_feedback).not_to be_approved }
          end
        end
      RUBY
    end
  end

  context 'when the definitions only build the answer a single expectation compares' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Book do
          describe '.recent' do
            let!(:recent_order) { create(:order, created_at: 1.day.ago) }
            let!(:old_order) { create(:order, created_at: 1.year.ago) }

            it { expect(described_class.recent).to contain_exactly(recent_order) }
          end
        end
      RUBY
    end
  end

  context 'when the definitions are doubles with verified messages' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe PaymentGateway do
          describe '#token' do
            let(:api_client) { instance_double(ApiClient) }
            let(:cache) { instance_double(Cache) }

            it { expect(api_client).to have_received(:request_token) }
            it { expect(cache).to have_received(:set) }
          end
        end
      RUBY
    end
  end

  context 'when the definitions live in different groups' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Coupon do
          describe 'code uniqueness' do
            context 'when creating an active record' do
              let!(:active_coupon) { create(:coupon, status: :active) }

              it { expect(active_coupon).to be_valid }
            end

            context 'when updating an existing record' do
              let!(:inactive_coupon) { create(:coupon, status: :inactive) }

              it { expect(inactive_coupon).not_to be_valid }
            end
          end
        end
      RUBY
    end
  end

  context 'when AllowedMethods exempts one of the definitions' do
    let(:cop_config) { { 'AllowedMethods' => %w[call] } }

    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe Order::Cancel do
          describe '.call' do
            let(:service) { described_class.(order_id: 42) }
            let!(:line) { create(:line) }

            it { expect(service).to be_failure }
            it { expect(line).to be_persisted }
          end
        end
      RUBY
    end
  end
end
