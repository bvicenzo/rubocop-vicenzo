# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::NestedSubjectRedefinition, :rspec_config do
  context 'when there is a single nested subject' do
    it 'registers an offense for a single nested subject inside examples group' do
      expect_offense(<<~RUBY)
        RSpec.describe "Example" do
          subject(:foo) { 42 }

          context "sub context" do
            subject(:foo) { 43 }
            ^^^^^^^^^^^^^^^^^^^^ Subject `:foo` is already defined in ancestor(s) block(s) at: 2.

            it "example" do
              expect(true).to eq(true)
            end
          end
        end
      RUBY
    end
  end

  context 'when there is a single nested anonymous subject' do
    it 'registers an offense for a single nested anonymous subject inside a examples group' do
      expect_offense(<<~RUBY)
        RSpec.describe "Example" do
          subject { 42 }

          context "sub context" do
            subject { 43 }
            ^^^^^^^^^^^^^^ Subject `:anonymous` is already defined in ancestor(s) block(s) at: 2.

            it "example" do
              expect(true).to eq(true)
            end
          end
        end
      RUBY
    end
  end

  context 'when there are multiple nested contexts with subject' do
    it 'registers offenses for each nested subject inside a examples group' do
      expect_offense(<<~RUBY)
        RSpec.describe "Example" do
          subject(:foo) { 42 }
          let(:bar) { 99 }

          describe "sub describe" do
            subject(:foo) { 43 }
            ^^^^^^^^^^^^^^^^^^^^ Subject `:foo` is already defined in ancestor(s) block(s) at: 2.

            context "sub context" do
              subject(:foo) { 44 }
              ^^^^^^^^^^^^^^^^^^^^ Subject `:foo` is already defined in ancestor(s) block(s) at: 2, 6.

              it "example" do
                expect(true).to eq(true)
              end
            end
          end
        end
      RUBY
    end
  end

  context 'when subject is not nested inside a examples group' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe "Example" do
          subject(:foo) { 42 }

          context "sub context" do
            subject(:bar) { 43 }

            it "example" do
              expect(true).to eq(true)
            end
          end
        end
      RUBY
    end
  end
end
