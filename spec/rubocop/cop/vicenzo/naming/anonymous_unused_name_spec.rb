# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::Naming::AnonymousUnusedName, :config do
  describe 'offense detection' do
    context 'when the code violates style guidelines' do
      context 'and a block parameter is anonymous' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            catalog.each { |_, copies| copies.each(&:reserve) }
                            ^ Name this block parameter: an unused value still means something, and `_` hides what. Name it after what it stands for in the domain (`_previous_owner`), not after its shape (`_value`, `_key`, `_item`) — that tells the next reader nothing.
          RUBY
        end
      end

      context 'and a destructured block parameter is anonymous' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            entries.each { |(_, id)| track(id) }
                             ^ Name this block parameter: [...]
          RUBY
        end
      end

      context 'and a shadowed block variable is anonymous' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            entries.each { |entry; _| track(entry) }
                                   ^ Name this block parameter: [...]
          RUBY
        end
      end

      context 'and a splat block parameter is anonymous' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            entries.each { |*_| track }
                            ^^ Name this block parameter: [...]
          RUBY
        end
      end

      context 'and a lambda parameter is anonymous' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            reserve = ->(_) { shelf.hold }
                         ^ Name this block parameter: [...]
          RUBY
        end
      end

      context 'and a method parameter is anonymous' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def notify(reader, _)
                               ^ Name this method parameter: an unused value still means something, and `_` hides what. Name it after what it stands for in the domain (`_previous_owner`), not after its shape (`_value`, `_key`, `_item`) — that tells the next reader nothing.
              reader.deliver
            end
          RUBY
        end
      end

      context 'and a singleton method parameter is anonymous' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def self.build(_)
                           ^ Name this method parameter: [...]
              new
            end
          RUBY
        end
      end

      context 'and a keyword method parameter is anonymous' do
        it 'registers an offense highlighting only the name' do
          expect_offense(<<~RUBY)
            def notify(_: nil)
                       ^ Name this method parameter: [...]
              deliver
            end
          RUBY
        end
      end

      context 'and an optional method parameter is anonymous' do
        it 'registers an offense highlighting only the name' do
          expect_offense(<<~RUBY)
            def notify(_ = default_channel)
                       ^ Name this method parameter: [...]
              deliver
            end
          RUBY
        end
      end

      context 'and a splat method parameter is anonymous' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            def notify(*_)
                       ^^ Name this method parameter: [...]
              deliver
            end
          RUBY
        end
      end

      context 'and more than one declaration is anonymous' do
        it 'registers an offense for each one' do
          expect_offense(<<~RUBY)
            def notify(_, reader, _)
                                  ^ Name this method parameter: [...]
                       ^ Name this method parameter: [...]
              reader.deliver
            end
          RUBY
        end
      end

      context 'and the name is made only of underscores' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            catalog.each { |__, copies| copies.each(&:reserve) }
                            ^^ Name this block parameter: [...]
          RUBY
        end
      end

      context 'and a multiple assignment discards a value' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            title, _ = line.split(';')
                   ^ Name this discarded value: an unused value still means something, and `_` hides what. Name it after what it stands for in the domain (`_previous_owner`), not after its shape (`_value`, `_key`, `_item`) — that tells the next reader nothing.
          RUBY
        end
      end

      context 'and a multiple assignment discards a splat' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            *_, last = entries
             ^ Name this discarded value: [...]
          RUBY
        end
      end

      context 'and a nested multiple assignment discards a value' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            (title, _), rest = entries
                    ^ Name this discarded value: [...]
          RUBY
        end
      end

      context 'and a rescued error is anonymous' do
        it 'registers an offense' do
          expect_offense(<<~RUBY)
            begin
              shelf.reorder
            rescue ShelfLocked => _
                                  ^ Name this rescued error: an unused value still means something, and `_` hides what. Name it after what it stands for in the domain (`_previous_owner`), not after its shape (`_value`, `_key`, `_item`) — that tells the next reader nothing.
              shelf.skip
            end
          RUBY
        end
      end
    end

    context 'when the code follows style guidelines' do
      context 'and the unused block parameter is named' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            catalog.each { |_isbn, copies| copies.each(&:reserve) }
          RUBY
        end
      end

      context 'and the unused method parameter is named' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def notify(reader, _delivery_channel)
              reader.deliver
            end
          RUBY
        end
      end

      context 'and the discarded value is named' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            title, _author = line.split(';')
          RUBY
        end
      end

      context 'and the rescued error is named' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            begin
              shelf.reorder
            rescue ShelfLocked => _lock_conflict
              shelf.skip
            end
          RUBY
        end
      end

      context 'and the block takes no parameters' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            catalog.each { reserve }
          RUBY
        end
      end

      context 'and the block uses numbered parameters' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            catalog.each { reserve(_1) }
          RUBY
        end
      end

      context 'and the multiple assignment discards an anonymous splat' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            *, last = entries
          RUBY
        end
      end
    end

    context 'when the block uses an implicit parameter' do
      let(:ruby_version) { 3.4 }

      it 'does not register an offense' do
        expect_no_offenses(<<~RUBY)
          catalog.each { reserve(it) }
        RUBY
      end
    end

    context 'when the method forwards anonymous parameters' do
      let(:ruby_version) { 3.4 }

      context 'and it forwards a rest parameter' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def notify(*)
              channel.deliver(*)
            end
          RUBY
        end
      end

      context 'and it forwards a keyword rest parameter' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def notify(**)
              channel.deliver(**)
            end
          RUBY
        end
      end

      context 'and it forwards a block parameter' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def notify(&)
              channel.deliver(&)
            end
          RUBY
        end
      end

      context 'and it forwards every argument' do
        it 'does not register an offense' do
          expect_no_offenses(<<~RUBY)
            def notify(...)
              channel.deliver(...)
            end
          RUBY
        end
      end
    end
  end
end
