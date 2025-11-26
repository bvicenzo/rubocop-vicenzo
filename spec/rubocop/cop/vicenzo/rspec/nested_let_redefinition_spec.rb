# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::NestedLetRedefinition, :rspec_config do
  context 'when there is a single nested let' do
    it 'registers an offense for a single nested let inside a examples group' do
      expect_offense(<<~RUBY)
        RSpec.describe "Example" do
          let(:foo) { 42 }

          context "sub context" do
            let(:foo) { 43 }
            ^^^^^^^^^^^^^^^^ Let `:foo` is already defined in ancestor(s) block(s) at: 2.

            it "example" do
              expect(true).to eq(true)
            end
          end
        end
      RUBY
    end
  end

  context 'when there is a single nested let_it_be' do
    it 'registers an offense for a single nested let_it_be inside a examples group' do
      expect_offense(<<~RUBY)
        RSpec.describe "Example" do
          let_it_be(:foo) { 42 }

          context "sub context" do
            let_it_be!(:foo) { 43 }
            ^^^^^^^^^^^^^^^^^^^^^^^ Let `:foo` is already defined in ancestor(s) block(s) at: 2.

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
            ^^^^^^^^^^^^^^^^ Let `:foo` is already defined in ancestor(s) block(s) at: 2.

            context "sub context" do
              let(:foo) { 44 }
              ^^^^^^^^^^^^^^^^ Let `:foo` is already defined in ancestor(s) block(s) at: 2, 6.

              it "example" do
                expect(true).to eq(true)
              end
            end
          end
        end
      RUBY
    end
  end

  context 'when there are multiple nested contexts with let and let_it_be' do
    it 'registers offenses for each nested let inside a examples group' do
      expect_offense(<<~RUBY)
        RSpec.describe "Example" do
          let(:foo) { 42 }
          let_it_be(:bar) { 99 }

          describe "sub describe" do
            let!(:foo) { 43 }
            ^^^^^^^^^^^^^^^^^ Let `:foo` is already defined in ancestor(s) block(s) at: 2.

            context "sub context" do
              let_it_be(:foo) { 44 }
              ^^^^^^^^^^^^^^^^^^^^^^ Let `:foo` is already defined in ancestor(s) block(s) at: 2, 6.

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

            it "example" do
              expect(true).to eq(true)
            end
          end
        end
      RUBY
    end
  end

  context 'when let_it_be is not nested inside a examples group' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe "Example" do
          let_it_be(:foo) { 42 }

          context "sub context" do
            let_it_be(:bar) { 43 }

            it "example" do
              expect(true).to eq(true)
            end
          end
        end
      RUBY
    end
  end

  context 'when let is redefined in sibling groups' do
    it 'registers offenses pointing ONLY to the parent when multiple siblings' do
      expect_offense(<<~RUBY)
        RSpec.describe "Example" do
          let(:foo) { 0 }

          context "sibling A" do
            let(:foo) { 1 }
            ^^^^^^^^^^^^^^^ Let `:foo` is already defined in ancestor(s) block(s) at: 2.

            expect(true).to be_truthy
          end

          context "sibling B" do
            let(:foo) { 2 }
            ^^^^^^^^^^^^^^^ Let `:foo` is already defined in ancestor(s) block(s) at: 2.

            expect(true).to be_truthy
          end
        end
      RUBY
    end
  end
end
