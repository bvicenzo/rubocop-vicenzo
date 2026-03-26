# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::DynamicExampleGeneration, :rspec_config do
  context 'when iteration generates context blocks' do
    it 'registers an offense on the iteration call' do
      expect_offense(<<~RUBY)
        [:admin, :driver].each do |role|
        ^^^^^^^^^^^^^^^^^^^^^^ Do not use iteration to dynamically generate example groups or examples. Write explicit, static contexts instead.
          context "when role is \#{role}" do
            it 'does something' do
            end
          end
        end
      RUBY
    end
  end

  context 'when iteration generates it blocks directly' do
    it 'registers an offense on the iteration call' do
      expect_offense(<<~RUBY)
        [:active, :inactive].each do |status|
        ^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use iteration to dynamically generate example groups or examples. Write explicit, static contexts instead.
          it "works for \#{status}" do
          end
        end
      RUBY
    end
  end

  context 'when iteration generates let definitions' do
    it 'registers an offense on the iteration call' do
      expect_offense(<<~RUBY)
        [:foo, :bar].each do |name|
        ^^^^^^^^^^^^^^^^^ Do not use iteration to dynamically generate example groups or examples. Write explicit, static contexts instead.
          let(name) { create(:thing) }
        end
      RUBY
    end
  end

  context 'when iteration generates before hooks' do
    it 'registers an offense on the iteration call' do
      expect_offense(<<~RUBY)
        [:a, :b].each do |trait|
        ^^^^^^^^^^^^^ Do not use iteration to dynamically generate example groups or examples. Write explicit, static contexts instead.
          before { setup(trait) }
        end
      RUBY
    end
  end

  context 'when each_with_index is used to generate contexts' do
    it 'registers an offense on the iteration call' do
      expect_offense(<<~RUBY)
        [:admin, :driver].each_with_index do |role, index|
        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Do not use iteration to dynamically generate example groups or examples. Write explicit, static contexts instead.
          context "case \#{index}" do
            it 'does something' do
            end
          end
        end
      RUBY
    end
  end

  context 'when map is used to generate contexts' do
    it 'registers an offense on the iteration call' do
      expect_offense(<<~RUBY)
        [:admin, :driver].map do |role|
        ^^^^^^^^^^^^^^^^^^^^^ Do not use iteration to dynamically generate example groups or examples. Write explicit, static contexts instead.
          context "when role is \#{role}" do
            it 'does something' do
            end
          end
        end
      RUBY
    end
  end

  context 'when iteration is used inside a regular method (not in a spec context)' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        def setup_roles
          [:admin, :driver].each do |role|
            create(:user, role: role)
          end
        end
      RUBY
    end
  end

  context 'when iteration does not contain any example group DSL' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        it 'processes all roles' do
          [:admin, :driver].each do |role|
            expect(role).to be_a(Symbol)
          end
        end
      RUBY
    end
  end

  context 'when iteration is used inside a before hook to set up data' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        before do
          [:admin, :driver].each do |role|
            create(:user, role: role)
          end
        end
      RUBY
    end
  end

  context 'when iteration is used inside a let to build a collection' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        let(:users) do
          [:admin, :driver].map do |role|
            create(:user, role: role)
          end
        end
      RUBY
    end
  end
end
