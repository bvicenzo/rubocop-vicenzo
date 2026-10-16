# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::Style::PreferManyOverSizeComparison, :config do
  describe 'collection size compared with one' do
    context 'when Active Support extensions are disabled' do
      let(:all_cops_config) { { 'TargetRubyVersion' => ruby_version, 'ActiveSupportExtensionsEnabled' => false } }

      context 'and the collection method is count' do
        it 'registers no offense' do
          expect_no_offenses(<<~RUBY)
            items.count > 1
          RUBY
        end
      end

      context 'and the collection method is size' do
        it 'registers no offense' do
          expect_no_offenses(<<~RUBY)
            items.size > 1
          RUBY
        end
      end

      context 'and the collection method is length' do
        it 'registers no offense' do
          expect_no_offenses(<<~RUBY)
            items.length > 1
          RUBY
        end
      end
    end

    context 'when Active Support extensions are enabled' do
      let(:all_cops_config) { { 'TargetRubyVersion' => ruby_version, 'ActiveSupportExtensionsEnabled' => true } }

      context 'and the collection method is count' do
        it 'registers no offense, leaving it to Style/CollectionQuerying' do
          expect_no_offenses(<<~RUBY)
            items.count > 1
          RUBY
        end
      end

      context 'and the collection method is size' do
        context 'and it has no receiver' do
          it 'registers no offense' do
            expect_no_offenses(<<~RUBY)
              size > 1
            RUBY
          end
        end

        context 'and it takes an argument' do
          it 'registers no offense' do
            expect_no_offenses(<<~RUBY)
              items.size(:active) > 1
            RUBY
          end
        end

        context 'and it is greater than another number' do
          it 'registers no offense' do
            expect_no_offenses(<<~RUBY)
              items.size > 2
            RUBY
          end
        end

        context 'and it is equal to one' do
          it 'registers no offense' do
            expect_no_offenses(<<~RUBY)
              items.size == 1
            RUBY
          end
        end

        context 'and it is greater than one' do
          it 'registers an offense and corrects to many?' do
            expect_offense(<<~RUBY)
              items.size > 1
              ^^^^^^^^^^^^^^ Use `many?` instead of `size > 1`.
            RUBY

            expect_correction(<<~RUBY)
              items.many?
            RUBY
          end
        end

        context 'and it is greater than or equal to two' do
          it 'registers an offense and corrects to many?' do
            expect_offense(<<~RUBY)
              items.size >= 2
              ^^^^^^^^^^^^^^^ Use `many?` instead of `size >= 2`.
            RUBY

            expect_correction(<<~RUBY)
              items.many?
            RUBY
          end
        end

        context 'and one is less than it' do
          it 'registers an offense and corrects to many?' do
            expect_offense(<<~RUBY)
              1 < items.size
              ^^^^^^^^^^^^^^ Use `many?` instead of `1 < size`.
            RUBY

            expect_correction(<<~RUBY)
              items.many?
            RUBY
          end
        end

        context 'and two is less than or equal to it' do
          it 'registers an offense and corrects to many?' do
            expect_offense(<<~RUBY)
              2 <= items.size
              ^^^^^^^^^^^^^^^ Use `many?` instead of `2 <= size`.
            RUBY

            expect_correction(<<~RUBY)
              items.many?
            RUBY
          end
        end

        context 'and it is called with safe navigation' do
          it 'registers an offense and corrects keeping the safe navigation' do
            expect_offense(<<~RUBY)
              items&.size > 1
              ^^^^^^^^^^^^^^^ Use `many?` instead of `size > 1`.
            RUBY

            expect_correction(<<~RUBY)
              items&.many?
            RUBY
          end
        end

        context 'and it is chained on a collection pipeline' do
          it 'registers an offense and corrects to many?' do
            expect_offense(<<~RUBY)
              multiple = records.values.grep(Item).uniq.size > 1 && overlapping?(items.last)
                         ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Use `many?` instead of `size > 1`.
            RUBY

            expect_correction(<<~RUBY)
              multiple = records.values.grep(Item).uniq.many? && overlapping?(items.last)
            RUBY
          end
        end
      end

      context 'and the collection method is length' do
        context 'and it is greater than one' do
          it 'registers an offense and corrects to many?' do
            expect_offense(<<~RUBY)
              items.length > 1
              ^^^^^^^^^^^^^^^^ Use `many?` instead of `length > 1`.
            RUBY

            expect_correction(<<~RUBY)
              items.many?
            RUBY
          end
        end

        context 'and two is less than or equal to it' do
          it 'registers an offense and corrects to many?' do
            expect_offense(<<~RUBY)
              2 <= items.length
              ^^^^^^^^^^^^^^^^^ Use `many?` instead of `2 <= length`.
            RUBY

            expect_correction(<<~RUBY)
              items.many?
            RUBY
          end
        end
      end
    end
  end
end
