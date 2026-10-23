# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::LetAliasingSubject, :rspec_config do
  describe 'offense detection' do
    context 'when the definition is not a let' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          RSpec.describe Cat do
            describe 'hunting' do
              subject(:cat) { Cat.new }

              before { cat }
            end
          end
        RUBY
      end
    end

    context 'when the definition is a let' do
      context 'but its value is not a call' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            RSpec.describe Cat do
              describe 'hunting' do
                subject(:cat) { Cat.new }

                let(:hunter) { :ball }
              end
            end
          RUBY
        end
      end

      context 'but its value is built on more than one call' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            RSpec.describe Cat do
              describe 'hunting' do
                subject(:cat) { Cat.new }

                let(:name) { cat.name }
              end
            end
          RUBY
        end
      end

      context 'and its value is a single call' do
        context 'but the call takes arguments' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              RSpec.describe Cat do
                describe 'hunting' do
                  subject(:cat) { Cat.new }

                  let(:hunter) { cat(:hungry) }
                end
              end
            RUBY
          end
        end

        context 'but the call is not the subject' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              RSpec.describe Cat do
                describe 'hunting' do
                  subject(:cat) { Cat.new }

                  let(:hunter) { other_cat }
                end
              end
            RUBY
          end
        end

        context 'but the call names a subject declared only in a sibling group' do
          context 'and the sibling is an example group' do
            it 'does not register an offense' do
              expect_no_offenses(<<~RUBY)
                RSpec.describe Cat do
                  describe 'hunting' do
                    context 'when the cat is resting' do
                      let(:hunter) { cat }
                    end

                    context 'when the cat is hunting' do
                      subject(:cat) { Cat.new }
                    end
                  end
                end
              RUBY
            end
          end

          context 'and the sibling is a shared group' do
            it 'does not register an offense' do
              expect_no_offenses(<<~RUBY)
                RSpec.describe Cat do
                  describe 'hunting' do
                    shared_context 'with a cat' do
                      subject(:cat) { Cat.new }
                    end

                    context 'when the cat is resting' do
                      let(:hunter) { cat }
                    end
                  end
                end
              RUBY
            end
          end
        end

        context 'and the call is the subject' do
          context 'and it names the declared subject' do
            context 'and the subject is declared in the group of the let' do
              context 'and the group is an example group' do
                let(:alias_offense) do
                  'Let `:hunter` is the subject under another name. ' \
                    'Refer to the subject as `cat`.'
                end

                it 'registers an offense on the let, saying to refer to the subject by its name' do
                  expect_offense(<<~RUBY)
                    RSpec.describe Cat do
                      describe 'hunting' do
                        subject(:cat) { Cat.new }

                        let(:hunter) { cat }
                        ^^^^^^^^^^^^ #{alias_offense}
                      end
                    end
                  RUBY
                end
              end

              context 'and the group is a shared group' do
                let(:alias_offense) do
                  'Let `:hunter` is the subject under another name. ' \
                    'Refer to the subject as `cat`.'
                end

                it 'registers an offense on the let, saying to refer to the subject by its name' do
                  expect_offense(<<~RUBY)
                    RSpec.shared_examples 'a hunter' do
                      subject(:cat) { Cat.new }

                      let(:hunter) { cat }
                      ^^^^^^^^^^^^ #{alias_offense}
                    end
                  RUBY
                end
              end
            end

            context 'and the subject is declared in a group enclosing the let' do
              context 'and both groups are example groups' do
                let(:alias_offense) do
                  'Let `:hunter` is the subject under another name. ' \
                    'Refer to the subject as `cat`.'
                end

                it 'registers an offense on the let, saying to refer to the subject by its name' do
                  expect_offense(<<~RUBY)
                    RSpec.describe Cat do
                      describe 'hunting' do
                        subject(:cat) { Cat.new }

                        context 'when the cat is hungry' do
                          let(:hunter) { cat }
                          ^^^^^^^^^^^^ #{alias_offense}
                        end
                      end
                    end
                  RUBY
                end
              end

              context 'and the let sits in a shared group' do
                let(:alias_offense) do
                  'Let `:hunter` is the subject under another name. ' \
                    'Refer to the subject as `cat`.'
                end

                it 'registers an offense on the let, saying to refer to the subject by its name' do
                  expect_offense(<<~RUBY)
                    RSpec.describe Cat do
                      describe 'hunting' do
                        subject(:cat) { Cat.new }

                        shared_context 'when the cat is hungry' do
                          let(:hunter) { cat }
                          ^^^^^^^^^^^^ #{alias_offense}
                        end
                      end
                    end
                  RUBY
                end
              end

              context 'and the enclosing group is a shared group' do
                let(:alias_offense) do
                  'Let `:hunter` is the subject under another name. ' \
                    'Refer to the subject as `cat`.'
                end

                it 'registers an offense on the let, saying to refer to the subject by its name' do
                  expect_offense(<<~RUBY)
                    RSpec.shared_examples 'a hunter' do
                      subject(:cat) { Cat.new }

                      context 'when the cat is hungry' do
                        let(:hunter) { cat }
                        ^^^^^^^^^^^^ #{alias_offense}
                      end
                    end
                  RUBY
                end
              end
            end

            context 'and the subject is declared only in a group nested in the one of the let' do
              context 'and no other group gives the name another meaning' do
                context 'and both groups are example groups' do
                  let(:alias_offense) do
                    'Let `:hunter` is the subject under another name. ' \
                      'Refer to the subject as `cat`.'
                  end

                  it 'registers an offense on the let, saying to refer to the subject by its name' do
                    expect_offense(<<~RUBY)
                      RSpec.describe Cat do
                        describe 'hunting' do
                          let(:hunter) { cat }
                          ^^^^^^^^^^^^ #{alias_offense}

                          context 'when the cat is hunting' do
                            subject(:cat) { Cat.new }
                          end
                        end
                      end
                    RUBY
                  end
                end

                context 'and the nested group is a shared group' do
                  let(:alias_offense) do
                    'Let `:hunter` is the subject under another name. ' \
                      'Refer to the subject as `cat`.'
                  end

                  it 'registers an offense on the let, saying to refer to the subject by its name' do
                    expect_offense(<<~RUBY)
                      RSpec.describe Cat do
                        describe 'hunting' do
                          let(:hunter) { cat }
                          ^^^^^^^^^^^^ #{alias_offense}

                          shared_context 'with a cat' do
                            subject(:cat) { Cat.new }
                          end
                        end
                      end
                    RUBY
                  end
                end

                context 'and the let sits in a shared group' do
                  let(:alias_offense) do
                    'Let `:hunter` is the subject under another name. ' \
                      'Refer to the subject as `cat`.'
                  end

                  it 'registers an offense on the let, saying to refer to the subject by its name' do
                    expect_offense(<<~RUBY)
                      RSpec.shared_examples 'a hunter' do
                        let(:hunter) { cat }
                        ^^^^^^^^^^^^ #{alias_offense}

                        context 'when the cat is hunting' do
                          subject(:cat) { Cat.new }
                        end
                      end
                    RUBY
                  end
                end
              end

              context 'and another nested group declares the name as a plain let' do
                context "and the subject's group is an example group" do
                  let(:alias_offense) do
                    'Let `:hunter` is the subject under another name. ' \
                      'Refer to the subject as `cat`.'
                  end

                  it 'registers an offense on the let, saying to refer to the subject by its name' do
                    expect_offense(<<~RUBY)
                      RSpec.describe Cat do
                        describe 'hunting' do
                          let(:hunter) { cat }
                          ^^^^^^^^^^^^ #{alias_offense}

                          context 'when the cat is hunting' do
                            subject(:cat) { Cat.new }
                          end

                          context 'when another cat is watching' do
                            subject(:dog) { Dog.new }

                            let(:cat) { Cat.new }
                          end
                        end
                      end
                    RUBY
                  end
                end

                context "and the subject's group is a shared group" do
                  let(:alias_offense) do
                    'Let `:hunter` is the subject under another name. ' \
                      'Refer to the subject as `cat`.'
                  end

                  it 'registers an offense on the let, saying to refer to the subject by its name' do
                    expect_offense(<<~RUBY)
                      RSpec.describe Cat do
                        describe 'hunting' do
                          let(:hunter) { cat }
                          ^^^^^^^^^^^^ #{alias_offense}

                          shared_context 'with a cat' do
                            subject(:cat) { Cat.new }
                          end

                          context 'when another cat is watching' do
                            subject(:dog) { Dog.new }

                            let(:cat) { Cat.new }
                          end
                        end
                      end
                    RUBY
                  end
                end
              end
            end
          end

          context 'and it reads `subject`' do
            context 'and a named subject is in sight' do
              context 'and the let sits outside any shared group' do
                let(:alias_offense) do
                  'Let `:hunter` is the subject under another name. ' \
                    'Refer to the subject as `cat`.'
                end

                it 'registers an offense on the let, saying to refer to the subject by its name' do
                  expect_offense(<<~RUBY)
                    RSpec.describe Cat do
                      describe 'hunting' do
                        subject(:cat) { Cat.new }

                        let(:hunter) { subject }
                        ^^^^^^^^^^^^ #{alias_offense}
                      end
                    end
                  RUBY
                end
              end

              context 'and the let sits in a shared group' do
                let(:alias_offense) do
                  'Let `:hunter` is the subject under another name. ' \
                    'Refer to the subject as `cat`.'
                end

                it 'registers an offense on the let, saying to refer to the subject by its name' do
                  expect_offense(<<~RUBY)
                    RSpec.shared_examples 'a hunter' do
                      subject(:cat) { Cat.new }

                      let(:hunter) { subject }
                      ^^^^^^^^^^^^ #{alias_offense}
                    end
                  RUBY
                end
              end
            end

            context 'and no named subject is in sight' do
              context 'and the let sits outside any shared group' do
                context 'and the subject is declared with `subject`' do
                  let(:alias_offense) do
                    'Let `:hunter` is the subject under another name. ' \
                      'Name the subject `hunter` instead.'
                  end

                  it 'registers an offense on the let, saying to give the subject that name' do
                    expect_offense(<<~RUBY)
                      RSpec.describe Cat do
                        describe 'hunting' do
                          subject { Cat.new }

                          let(:hunter) { subject }
                          ^^^^^^^^^^^^ #{alias_offense}
                        end
                      end
                    RUBY
                  end
                end

                context 'and the subject is declared with `subject!`' do
                  let(:alias_offense) do
                    'Let `:hunter` is the subject under another name. ' \
                      'Name the subject `hunter` instead.'
                  end

                  it 'registers an offense on the let, saying to give the subject that name' do
                    expect_offense(<<~RUBY)
                      RSpec.describe Cat do
                        describe 'hunting' do
                          subject! { Cat.new }

                          let(:hunter) { subject }
                          ^^^^^^^^^^^^ #{alias_offense}
                        end
                      end
                    RUBY
                  end
                end

                context 'and no subject is declared' do
                  context 'and an example group holds the let' do
                    let(:alias_offense) do
                      'Let `:hunter` is the subject under another name. ' \
                        'Name the subject `hunter` instead.'
                    end

                    it 'registers an offense on the let, saying to give the subject that name' do
                      expect_offense(<<~RUBY)
                        RSpec.describe Cat do
                          describe 'hunting' do
                            let(:hunter) { subject }
                            ^^^^^^^^^^^^ #{alias_offense}
                          end
                        end
                      RUBY
                    end
                  end

                  context 'and no group holds the let' do
                    let(:alias_offense) do
                      'Let `:hunter` is the subject under another name. ' \
                        'Name the subject `hunter` instead.'
                    end

                    it 'registers an offense on the let, saying to give the subject that name' do
                      expect_offense(<<~RUBY)
                        module Hunting
                          extend RSpec::SharedContext

                          let(:hunter) { subject }
                          ^^^^^^^^^^^^ #{alias_offense}
                        end
                      RUBY
                    end
                  end
                end
              end

              context 'and the let sits in a shared group' do
                context 'and the shared group holds the let directly' do
                  context 'and the subject is declared with `subject`' do
                    let(:alias_offense) do
                      'Let `:hunter` is the subject under another name. ' \
                        'Refer to the subject as `subject`.'
                    end

                    it 'registers an offense on the let, saying to refer to the subject as `subject`' do
                      expect_offense(<<~RUBY)
                        RSpec.shared_examples 'a hunter' do
                          subject { Cat.new }

                          let(:hunter) { subject }
                          ^^^^^^^^^^^^ #{alias_offense}
                        end
                      RUBY
                    end
                  end

                  context 'and the subject is declared with `subject!`' do
                    let(:alias_offense) do
                      'Let `:hunter` is the subject under another name. ' \
                        'Refer to the subject as `subject`.'
                    end

                    it 'registers an offense on the let, saying to refer to the subject as `subject`' do
                      expect_offense(<<~RUBY)
                        RSpec.shared_examples 'a hunter' do
                          subject! { Cat.new }

                          let(:hunter) { subject }
                          ^^^^^^^^^^^^ #{alias_offense}
                        end
                      RUBY
                    end
                  end

                  context 'and no subject is declared' do
                    let(:alias_offense) do
                      'Let `:hunter` is the subject under another name. ' \
                        'Refer to the subject as `subject`.'
                    end

                    it 'registers an offense on the let, saying to refer to the subject as `subject`' do
                      expect_offense(<<~RUBY)
                        RSpec.shared_examples 'a hunter' do
                          let(:hunter) { subject }
                          ^^^^^^^^^^^^ #{alias_offense}
                        end
                      RUBY
                    end
                  end
                end

                context 'and the shared group encloses the group of the let' do
                  context 'and the subject is declared with `subject`' do
                    let(:alias_offense) do
                      'Let `:hunter` is the subject under another name. ' \
                        'Refer to the subject as `subject`.'
                    end

                    it 'registers an offense on the let, saying to refer to the subject as `subject`' do
                      expect_offense(<<~RUBY)
                        RSpec.shared_examples 'a hunter' do
                          subject { Cat.new }

                          context 'when the cat is hungry' do
                            let(:hunter) { subject }
                            ^^^^^^^^^^^^ #{alias_offense}
                          end
                        end
                      RUBY
                    end
                  end

                  context 'and the subject is declared with `subject!`' do
                    let(:alias_offense) do
                      'Let `:hunter` is the subject under another name. ' \
                        'Refer to the subject as `subject`.'
                    end

                    it 'registers an offense on the let, saying to refer to the subject as `subject`' do
                      expect_offense(<<~RUBY)
                        RSpec.shared_examples 'a hunter' do
                          subject! { Cat.new }

                          context 'when the cat is hungry' do
                            let(:hunter) { subject }
                            ^^^^^^^^^^^^ #{alias_offense}
                          end
                        end
                      RUBY
                    end
                  end

                  context 'and no subject is declared' do
                    let(:alias_offense) do
                      'Let `:hunter` is the subject under another name. ' \
                        'Refer to the subject as `subject`.'
                    end

                    it 'registers an offense on the let, saying to refer to the subject as `subject`' do
                      expect_offense(<<~RUBY)
                        RSpec.shared_examples 'a hunter' do
                          context 'when the cat is hungry' do
                            let(:hunter) { subject }
                            ^^^^^^^^^^^^ #{alias_offense}
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
      end
    end
  end
end
