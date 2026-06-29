# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::Style::JsonParseSymbolizeNames, :config do
  context 'when the code violates style guidelines' do
    context 'and JSON.parse is called without options' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          JSON.parse(payload)
          ^^^^^^^^^^^^^^^^^^^ Pass `symbolize_names: true` to `JSON.parse` so keys are symbols. Only when string keys are truly required, set `symbolize_names: false` explicitly.
        RUBY
      end
    end

    context 'and JSON.parse is called with options but without symbolize_names' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          JSON.parse(payload, max_nesting: 5)
          ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^ Pass `symbolize_names: true` to `JSON.parse` so keys are symbols. Only when string keys are truly required, set `symbolize_names: false` explicitly.
        RUBY
      end
    end

    context 'and ::JSON.parse is called without options' do
      it 'registers an offense' do
        expect_offense(<<~RUBY)
          ::JSON.parse(payload)
          ^^^^^^^^^^^^^^^^^^^^^ Pass `symbolize_names: true` to `JSON.parse` so keys are symbols. Only when string keys are truly required, set `symbolize_names: false` explicitly.
        RUBY
      end
    end
  end

  context 'when the code follows style guidelines' do
    context 'and JSON.parse passes symbolize_names: true' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          JSON.parse(payload, symbolize_names: true)
        RUBY
      end
    end

    context 'and JSON.parse passes symbolize_names: false' do
      it 'does not register an offense (deliberate opt-out)' do
        expect_no_offenses(<<~RUBY)
          JSON.parse(payload, symbolize_names: false)
        RUBY
      end
    end

    context 'and JSON.parse passes symbolize_names alongside other options' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          JSON.parse(payload, max_nesting: 5, symbolize_names: true)
        RUBY
      end
    end
  end

  context 'when the options cannot be analyzed statically' do
    context 'and the options are passed as a variable' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          JSON.parse(payload, options)
        RUBY
      end
    end

    context 'and the options are passed as a double splat' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          JSON.parse(payload, **options)
        RUBY
      end
    end

    context 'and the arguments are passed as a splat' do
      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          JSON.parse(*arguments)
        RUBY
      end
    end
  end

  context 'when the receiver is not JSON' do
    it 'does not register an offense' do
      expect_no_offenses(<<~RUBY)
        parser.parse(payload)
      RUBY
    end
  end
end
