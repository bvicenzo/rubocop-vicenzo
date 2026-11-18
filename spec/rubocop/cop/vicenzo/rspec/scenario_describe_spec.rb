# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::ScenarioDescribe, :rspec_config do
  describe 'offense detection' do
    context 'when the group calling the entry point is a context' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe ImageLoader do
            describe '.from_file' do
              it { expect(described_class.from_file(path)).to be_an(Image) }
            end

            context 'with the reference file' do
              it { expect(described_class.from_file(reference_path)).to be_an(Image) }
            end
          end
        RUBY
      end
    end

    context 'when the group calling the entry point is an example group alias added to the RSpec language' do
      before { other_cops.dig('RSpec', 'Language', 'ExampleGroups', 'Regular') << 'response' }

      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe ImageLoader do
            describe '.from_file' do
              it { expect(described_class.from_file(path)).to be_an(Image) }
            end

            response '200', 'image found' do
              it { expect(described_class.from_file(reference_path)).to be_an(Image) }
            end
          end
        RUBY
      end
    end

    context 'when the group calling the entry point is a describe' do
      context 'but it is a top-level group of the file' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            describe '.from_file' do
              it { expect(described_class.from_file(path)).to be_an(Image) }
            end

            describe 'the reference file' do
              it { expect(described_class.from_file(reference_path)).to be_an(Image) }
            end
          RUBY
        end
      end

      context 'and it sits inside an example group' do
        context 'but it names a class' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              RSpec.describe ImageLoader do
                describe '.from_file' do
                  it { expect(described_class.from_file(path)).to be_an(Image) }
                end

                describe ImageLoader::Cache do
                  it { expect(described_class.from_file(path)).to be_an(Image) }
                end
              end
            RUBY
          end
        end

        context 'but it names an instance method' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              RSpec.describe ImageLoader do
                describe '.from_file' do
                  it { expect(described_class.from_file(path)).to be_an(Image) }
                end

                describe '#size' do
                  subject(:loader) { described_class.from_file(path) }

                  it { expect(loader.size).to eq(393_232) }
                end
              end
            RUBY
          end
        end

        context 'but it names a class method' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              RSpec.describe ImageLoader do
                describe '.from_file' do
                  it { expect(described_class.from_file(path)).to be_an(Image) }
                end

                describe '.from_reference' do
                  it { expect(described_class.from_file(reference_path)).to eq(described_class.from_reference) }
                end
              end
            RUBY
          end
        end

        context 'and it names neither a class nor an entry point' do
          context 'but it has no sibling describe' do
            it 'does not register an offense' do
              expect_no_offenses(<<~RUBY)
                RSpec.describe ImageLoader do
                  describe 'the reference file' do
                    it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                  end
                end
              RUBY
            end
          end

          context 'but no sibling describe names an entry point' do
            it 'does not register an offense' do
              expect_no_offenses(<<~RUBY)
                RSpec.describe User do
                  describe 'enums' do
                    it { is_expected.to define_enum_for(:role) }
                  end

                  describe 'callbacks' do
                    describe 'after_create' do
                      it { expect { described_class.create!(role: :admin) }.to have_enqueued_mail(OwnerMailer, :created) }
                    end
                  end
                end
              RUBY
            end
          end

          context 'but the sibling describe names the method without a prefix' do
            it 'does not register an offense' do
              expect_no_offenses(<<~RUBY)
                RSpec.describe ImageLoader do
                  describe 'from_file' do
                    it { expect(described_class.from_file(path)).to be_an(Image) }
                  end

                  describe 'the reference file' do
                    it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                  end
                end
              RUBY
            end
          end

          context 'and a sibling describe names a class method' do
            context 'but the describe calls another class method' do
              it 'does not register an offense' do
                expect_no_offenses(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '.from_file' do
                      it { expect(described_class.from_file(path)).to be_an(Image) }
                    end

                    describe 'the reference bytes' do
                      it { expect(described_class.from_bytes(reference_bytes)).to be_an(Image) }
                    end
                  end
                RUBY
              end
            end

            context 'but the describe calls an instance method of the same name' do
              it 'does not register an offense' do
                expect_no_offenses(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '.from_file' do
                      it { expect(described_class.from_file(path)).to be_an(Image) }
                    end

                    describe 'the reference file' do
                      it { expect(subject.from_file(reference_path)).to be_an(Image) }
                    end
                  end
                RUBY
              end
            end

            context 'but the describe calls it on the class constant' do
              it 'does not register an offense' do
                expect_no_offenses(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '.from_file' do
                      it { expect(described_class.from_file(path)).to be_an(Image) }
                    end

                    describe 'the reference file' do
                      it { expect(ImageLoader.from_file(reference_path)).to be_an(Image) }
                    end
                  end
                RUBY
              end
            end

            context 'but the describe calls it without a receiver' do
              it 'does not register an offense' do
                expect_no_offenses(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '.from_file' do
                      it { expect(described_class.from_file(path)).to be_an(Image) }
                    end

                    describe 'the reference file' do
                      it { expect(from_file(reference_path)).to be_an(Image) }
                    end
                  end
                RUBY
              end
            end

            context 'but the describe calls it only inside a nested describe naming an entry point' do
              it 'does not register an offense' do
                expect_no_offenses(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '.from_file' do
                      it { expect(described_class.from_file(path)).to be_an(Image) }
                    end

                    describe 'loading' do
                      describe '.from_file' do
                        it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                      end
                    end
                  end
                RUBY
              end
            end

            context 'but the describe calls it only inside a nested describe naming a class' do
              it 'does not register an offense' do
                expect_no_offenses(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '.from_file' do
                      it { expect(described_class.from_file(path)).to be_an(Image) }
                    end

                    describe 'caching' do
                      describe ImageLoader::Cache do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end
                    end
                  end
                RUBY
              end
            end

            context 'and the describe calls it on described_class' do
              context 'and the call is in an example' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      describe 'the reference file', :local_file do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        it { expect(described_class.from_file(reference_path)).to have_attributes(size: 393_232) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the call is in the subject' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      describe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        subject(:image) { described_class.from_file(reference_path) }

                        it { is_expected.to have_attributes(size: 393_232) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the call is in a let' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      describe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        let(:image) { described_class.from_file(reference_path) }

                        it { expect(image.size).to eq(393_232) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the call is in a hook' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      describe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        before { described_class.from_file(reference_path) }

                        it { expect(ImageCache).to be_warm }
                      end
                    end
                  RUBY
                end
              end

              context 'and the call is in a nested context' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      describe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        context 'when it is compressed' do
                          it { expect(described_class.from_file(compressed_path)).to be_an(Image) }
                        end
                      end
                    end
                  RUBY
                end
              end

              context 'and the call is in a nested describe naming nothing' do
                it 'registers an offense only for the outer describe' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      describe 'the reference files' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        describe 'the largest one' do
                          it { expect(described_class.from_file(largest_path)).to be_an(Image) }
                        end
                      end
                    end
                  RUBY
                end
              end

              context 'and the call uses safe navigation' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      describe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        it { expect(described_class&.from_file(reference_path)).to be_an(Image) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the sibling names .call and the call uses the shorthand syntax' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.call' do
                        it { expect(described_class.(path)).to be_an(Image) }
                      end

                      describe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.call`, which the sibling `describe '.call'` already names: make it a `context` inside that group.
                        it { expect(described_class.(reference_path)).to be_an(Image) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the describe comes before its sibling' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                      end

                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the sibling names the method with its signature' do
                it 'registers an offense quoting the sibling description' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file(path)' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      describe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file(path)'` already names: make it a `context` inside that group.
                        it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the siblings sit inside a nested describe' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe 'loading' do
                        describe '.from_file' do
                          it { expect(described_class.from_file(path)).to be_an(Image) }
                        end

                        describe 'the reference file' do
                        ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                          it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                        end
                      end
                    end
                  RUBY
                end
              end

              context 'and the siblings sit inside a context' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    context 'when the disk is mounted' do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      describe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the siblings sit inside a shared group' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    shared_examples 'an image loader' do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      describe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the describe is focused' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      fdescribe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `fdescribe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the describe is skipped' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      xdescribe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `xdescribe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the describe is a feature' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      feature 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `feature` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the describe is an example_group' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      example_group 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `example_group` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                      end
                    end
                  RUBY
                end
              end

              context 'and the describe has no description' do
                it 'registers an offense' do
                  expect_offense(<<~RUBY)
                    RSpec.describe ImageLoader do
                      describe '.from_file' do
                        it { expect(described_class.from_file(path)).to be_an(Image) }
                      end

                      describe do
                      ^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                        it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                      end
                    end
                  RUBY
                end
              end
            end
          end

          context 'and a sibling describe names an instance method' do
            context 'but the describe calls another instance method on the subject' do
              it 'does not register an offense' do
                expect_no_offenses(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '#size' do
                      it { expect(subject.size).to eq(393_232) }
                    end

                    describe 'the reference file' do
                      subject(:loader) { described_class.new(reference_path) }

                      it { expect(loader.width).to eq(512) }
                    end
                  end
                RUBY
              end
            end

            context 'but the describe calls the class method of the same name' do
              it 'does not register an offense' do
                expect_no_offenses(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '#size' do
                      it { expect(subject.size).to eq(393_232) }
                    end

                    describe 'the reference file' do
                      it { expect(described_class.size).to eq(393_232) }
                    end
                  end
                RUBY
              end
            end

            context 'but the describe calls it on a let that is not the subject' do
              it 'does not register an offense' do
                expect_no_offenses(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '#size' do
                      it { expect(subject.size).to eq(393_232) }
                    end

                    describe 'the reference file' do
                      let(:reference_image) { Image.new(reference_path) }

                      it { expect(reference_image.size).to eq(393_232) }
                    end
                  end
                RUBY
              end
            end

            context 'but the describe calls it only inside a nested describe naming an entry point' do
              it 'does not register an offense' do
                expect_no_offenses(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '#size' do
                      it { expect(subject.size).to eq(393_232) }
                    end

                    describe 'measurements' do
                      describe '#size' do
                        it { expect(subject.size).to eq(393_232) }
                      end
                    end
                  end
                RUBY
              end
            end

            context 'and the describe calls it on the anonymous subject' do
              it 'registers an offense' do
                expect_offense(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '#size' do
                      it { expect(subject.size).to eq(393_232) }
                    end

                    describe 'the reference file' do
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `#size`, which the sibling `describe '#size'` already names: make it a `context` inside that group.
                      subject { described_class.new(reference_path) }

                      it { expect(subject.size).to eq(393_232) }
                    end
                  end
                RUBY
              end
            end

            context 'and the describe calls it on a subject named in the describe' do
              it 'registers an offense' do
                expect_offense(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '#size' do
                      subject(:loader) { described_class.new(path) }

                      it { expect(loader.size).to eq(393_232) }
                    end

                    describe 'the reference file' do
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `#size`, which the sibling `describe '#size'` already names: make it a `context` inside that group.
                      subject(:reference_loader) { described_class.new(reference_path) }

                      it { expect(reference_loader.size).to eq(393_232) }
                    end
                  end
                RUBY
              end
            end

            context 'and the describe calls it on a subject named in an ancestor group' do
              it 'registers an offense' do
                expect_offense(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe 'instances' do
                      subject(:loader) { described_class.new(path) }

                      describe '#size' do
                        it { expect(loader.size).to eq(393_232) }
                      end

                      describe 'the reference file' do
                      ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `#size`, which the sibling `describe '#size'` already names: make it a `context` inside that group.
                        let(:path) { reference_path }

                        it { expect(loader.size).to eq(393_232) }
                      end
                    end
                  end
                RUBY
              end
            end

            context 'and the describe calls it on a new instance of described_class' do
              it 'registers an offense' do
                expect_offense(<<~RUBY)
                  RSpec.describe ImageLoader do
                    describe '#size' do
                      it { expect(subject.size).to eq(393_232) }
                    end

                    describe 'the reference file' do
                    ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `#size`, which the sibling `describe '#size'` already names: make it a `context` inside that group.
                      it { expect(described_class.new(reference_path).size).to eq(393_232) }
                    end
                  end
                RUBY
              end
            end
          end

          context 'and siblings name two entry points the describe calls' do
            it 'registers one offense naming the first entry point called' do
              expect_offense(<<~RUBY)
                RSpec.describe ImageLoader do
                  describe '.from_file' do
                    it { expect(described_class.from_file(path)).to be_an(Image) }
                  end

                  describe '.from_bytes' do
                    it { expect(described_class.from_bytes(bytes)).to be_an(Image) }
                  end

                  describe 'the reference file' do
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_bytes`, which the sibling `describe '.from_bytes'` already names: make it a `context` inside that group.
                    it { expect(described_class.from_bytes(reference_bytes)).to eq(described_class.from_file(reference_path)) }
                  end
                end
              RUBY
            end
          end

          context 'and two describes call the entry point a sibling names' do
            it 'registers an offense for each of them' do
              expect_offense(<<~RUBY)
                RSpec.describe ImageLoader do
                  describe '.from_file' do
                    it { expect(described_class.from_file(path)).to be_an(Image) }
                  end

                  describe 'the reference file' do
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                    it { expect(described_class.from_file(reference_path)).to be_an(Image) }
                  end

                  describe 'the compressed file' do
                  ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ This `describe` exercises `.from_file`, which the sibling `describe '.from_file'` already names: make it a `context` inside that group.
                    it { expect(described_class.from_file(compressed_path)).to be_an(Image) }
                  end
                end
              RUBY
            end
          end
        end
      end
    end
  end
end
