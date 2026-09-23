# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::UnnestedContextImproperStart, :rspec_config do
  describe 'offense detection' do
    context 'when a context under a describe starts with and' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          describe '#available_colors' do
            context 'and the color pink is not available' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Unnested `context` should start with `when`, `with`, or `without`, not `and`.
              it 'does not show the pink option'
            end
          end
        RUBY
      end
    end

    context 'when a context under a describe starts with but' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          describe '#available_colors' do
            context 'but the color pink is not available' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Unnested `context` should start with `when`, `with`, or `without`, not `but`.
              it 'does not show the pink option'
            end
          end
        RUBY
      end
    end

    context 'when a context under a describe starts with however' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          describe '#available_colors' do
            context 'however, the color pink is not available' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Unnested `context` should start with `when`, `with`, or `without`, not `however`.
              it 'does not show the pink option'
            end
          end
        RUBY
      end
    end

    context 'when a context straight under RSpec.describe starts with and' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          RSpec.describe Product do
            context 'and the color pink is not available' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Unnested `context` should start with `when`, `with`, or `without`, not `and`.
              it 'does not show the pink option'
            end
          end
        RUBY
      end
    end

    context 'when a focused context under a describe starts with and' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          describe '#available_colors' do
            fcontext 'and the color pink is not available' do
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Unnested `context` should start with `when`, `with`, or `without`, not `and`.
              it 'does not show the pink option'
            end
          end
        RUBY
      end
    end

    context 'when a describe sits between the context starting with and and the enclosing context' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          context 'when the product is for sale' do
            describe '#available_colors' do
              context 'and the color pink is not available' do
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Unnested `context` should start with `when`, `with`, or `without`, not `and`.
                it 'does not show the pink option'
              end
            end
          end
        RUBY
      end
    end

    context 'when a context under a describe starts with when' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          describe '#available_colors' do
            context 'when the color pink is not available' do
              it 'does not show the pink option'
            end
          end
        RUBY
      end
    end

    context 'when a context under another context starts with and' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          describe '#available_colors' do
            context 'when the product is for sale' do
              context 'and the color pink is not available' do
                it 'does not show the pink option'
              end
            end
          end
        RUBY
      end
    end

    context 'when a context inside shared examples starts with and' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          shared_examples 'a product listing' do
            context 'and the color pink is not available' do
              it 'does not show the pink option'
            end
          end
        RUBY
      end
    end

    context 'when a context inside a shared context starts with and' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          shared_context 'with a product for sale' do
            context 'and the color pink is not available' do
              let(:colors) { %w[blue] }
            end
          end
        RUBY
      end
    end

    context 'when the description is a constant' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          describe '#available_colors' do
            context UNAVAILABLE_COLOR do
              it 'does not show the pink option'
            end
          end
        RUBY
      end
    end

    context 'when the description is an interpolated string' do
      it 'does not register an offense' do
        expect_no_offenses(<<~'RUBY')
          describe '#available_colors' do
            context "and the color #{color} is not available" do
              it 'does not show the option'
            end
          end
        RUBY
      end
    end

    context 'when the first word only begins with a conjunction' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          describe '#available_colors' do
            context 'android clients' do
              it 'shows every option'
            end
          end
        RUBY
      end
    end
  end

  describe 'configuration' do
    context 'when ForbiddenPrefixes replaces the defaults' do
      let(:cop_config) { { 'ForbiddenPrefixes' => %w[Also] } }

      context 'and the context starts with a configured word' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            describe '#available_colors' do
              context 'also when the color pink is not available' do
              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Unnested `context` should start with `when`, `with`, or `without`, not `also`.
                it 'does not show the pink option'
              end
            end
          RUBY
        end
      end

      context 'but the context starts with a default word left out of the configuration' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            describe '#available_colors' do
              context 'and the color pink is not available' do
                it 'does not show the pink option'
              end
            end
          RUBY
        end
      end
    end
  end
end
