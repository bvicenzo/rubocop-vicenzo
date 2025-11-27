# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::Rails::EnumInclusionOfValidation, :config do
  context 'when the enum is in a single line' do
    context 'and enum is in old rails style' do
      it 'ignores enums' do
        expect_no_offenses(<<~RUBY)
          enum status: { active: 1, inactive: 0 }
        RUBY
      end
    end

    context 'and enum is array format' do
      context 'and no option is provided' do
        it 'detects suggests correction' do
          expect_offense(<<~RUBY)
            enum :status, [:active, :inactive]
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add `validate: { allow_nil: true }` to the enum.
          RUBY

          expect_correction(<<~RUBY)
            enum :status, [:active, :inactive], validate: { allow_nil: true }
          RUBY
        end
      end

      context 'and validate option is missing' do
        it 'detects suggests correction' do
          expect_offense(<<~RUBY)
            enum :status, [:active, :inactive], suffix: true
            ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add `validate: { allow_nil: true }` to the enum.
          RUBY

          expect_correction(<<~RUBY)
            enum :status, [:active, :inactive], suffix: true, validate: { allow_nil: true }
          RUBY
        end
      end

      context 'and there is validate option' do
        context 'but the allow_nil option is missing' do
          it 'detects and corrects it' do
            expect_offense(<<~RUBY)
              enum :status, %i[active inactive], validate: true, suffix: true
                                                 ^^^^^^^^^^^^^^ The `validate` option for the enum must be `validate: { allow_nil: true }`.
            RUBY

            expect_correction(<<~RUBY)
              enum :status, %i[active inactive], validate: { allow_nil: true }, suffix: true
            RUBY
          end
        end

        context 'and allow_nil option is informed' do
          it 'does not register an offense' do
            expect_no_offenses(<<~RUBY)
              enum :status, [:active, :inactive], validate: { allow_nil: true }, suffix: true
            RUBY
          end
        end
      end
    end

    context 'but validate option is missing' do
      it 'detects suggests correction' do
        expect_offense(<<~RUBY)
          enum :status, { active: 1, inactive: 0 }, suffix: true
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Add `validate: { allow_nil: true }` to the enum.
        RUBY

        expect_correction(<<~RUBY)
          enum :status, { active: 1, inactive: 0 }, suffix: true, validate: { allow_nil: true }
        RUBY
      end
    end

    context 'and there is validate option' do
      context 'but the allow_nil option is missing' do
        it 'detects and corrects it' do
          expect_offense(<<~RUBY)
            enum :status, { active: 1, inactive: 0 }, validate: true, suffix: true
                                                      ^^^^^^^^^^^^^^ The `validate` option for the enum must be `validate: { allow_nil: true }`.
          RUBY

          expect_correction(<<~RUBY)
            enum :status, { active: 1, inactive: 0 }, validate: { allow_nil: true }, suffix: true
          RUBY
        end
      end

      context 'and allow_nil option is informed' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            enum :status, { active: 1, inactive: 0 }, validate: { allow_nil: true }, suffix: true
          RUBY
        end
      end
    end
  end

  context 'when the enum is in multiple lines' do
    context 'but validate option is missing' do
      it 'detects and suggests correction' do
        expect_offense(<<~RUBY)
          enum :status,
          ^^^^^^^^^^^^^ Add `validate: { allow_nil: true }` to the enum.
               { active: 1, inactive: 0 },
               suffix: true
        RUBY

        expect_correction(<<~RUBY)
          enum :status,
               { active: 1, inactive: 0 },
               suffix: true, validate: { allow_nil: true }
        RUBY
      end
    end

    context 'and there is validate option' do
      context 'but the allow_nil option is missing' do
        it 'detects and corrects it' do
          expect_offense(<<~RUBY)
            enum :status,
                 { active: 1, inactive: 0 },
                 validate: true,
                 ^^^^^^^^^^^^^^ The `validate` option for the enum must be `validate: { allow_nil: true }`.
                 suffix: true
          RUBY

          expect_correction(<<~RUBY)
            enum :status,
                 { active: 1, inactive: 0 },
                 validate: { allow_nil: true },
                 suffix: true
          RUBY
        end
      end

      context 'and allow_nil option is informed' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            enum :status,
                 { active: 1, inactive: 0 },
                 validate: { allow_nil: true },
                 suffix: true
          RUBY
        end
      end
    end
  end
end
