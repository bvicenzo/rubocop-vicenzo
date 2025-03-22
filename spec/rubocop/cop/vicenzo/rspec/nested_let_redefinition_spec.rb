# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::NestedLetRedefinition, :config do
  let(:config) { RuboCop::Config.new }

  context 'when there is a single nested let' do
    it 'registers an offense for a single nested let inside a examples group' do
      expect_offense(<<~RUBY)
        RSpec.describe "Example" do
          let(:foo) { 42 }

          context "sub context" do
            let(:foo) { 43 }
            ^^^^^^^^^^^^^^^^ Vicenzo/RSpec/NestedLetRedefinition: Let `:foo` is already defined in ancestor(s) block(s) at: 2.

            it "example" do
              expect(true).to eq(true)
            end
          end
        end
      RUBY
    end
  end

  context 'when there are multiple nested contexts with let' do
    it 'registers offenses for each nested let inside a examples group' do
      expect_offense(<<~RUBY)
        RSpec.describe "Example" do
          let(:foo) { 42 }
          let(:bar) { 99 }

          describe "sub describe" do
            let(:foo) { 43 }
            ^^^^^^^^^^^^^^^^ Vicenzo/RSpec/NestedLetRedefinition: Let `:foo` is already defined in ancestor(s) block(s) at: 2.

            context "sub context" do
              let(:foo) { 44 }
              ^^^^^^^^^^^^^^^^ Vicenzo/RSpec/NestedLetRedefinition: Let `:foo` is already defined in ancestor(s) block(s) at: 2, 6.

              it "example" do
                expect(true).to eq(true)
              end
            end
          end
        end
      RUBY
    end
  end

  context 'when let is not nested inside a examples group' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe "Example" do
          let(:foo) { 42 }

          context "sub context" do
            let(:bar) { 43 }
          end
        end
      RUBY
    end
  end
end
