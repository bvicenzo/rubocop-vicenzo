# frozen_string_literal: true

RSpec.describe RuboCop::Cop::Vicenzo::RSpec::LeakyDefinition, :rspec_config do
  context 'when defining methods/structures in the global scope' do
    it 'registers an offense for a top-level method' do
      expect_offense(<<~RUBY)
        def my_global_helper
        ^^^^^^^^^^^^^^^^^^^^ Do not define methods, classes, or modules directly in the global scope or within spec blocks. This pollutes the namespace. Move this logic to `spec/support`, use `let`, or encapsulate it within a safe structure (e.g., `Class.new`).
        end

        RSpec.describe MyClass do
        end
      RUBY
    end

    it 'registers an offense for a top-level module' do
      expect_offense(<<~RUBY)
        module GlobalHelpers
        ^^^^^^^^^^^^^^^^^^^^ Do not define methods, classes, or modules directly in the global scope or within spec blocks. [...]
        end
      RUBY
    end
  end

  context 'when defining methods inside RSpec blocks (describe/context)' do
    it 'registers an offense for a method inside a describe block' do
      expect_offense(<<~RUBY)
        describe MyClass do
          def helper_method
          ^^^^^^^^^^^^^^^^^ Do not define methods, classes, or modules directly in the global scope or within spec blocks. [...]
            puts 'dangerous'
          end
        end
      RUBY
    end

    it 'registers an offense for a class definition inside a describe block' do
      expect_offense(<<~RUBY)
        describe MyClass do
          class FakeUser
          ^^^^^^^^^^^^^^ Do not define methods, classes, or modules directly in the global scope or within spec blocks. [...]
          end
        end
      RUBY
    end
  end

  context 'when using dynamic definitions (safe scopes)' do
    it 'does not register an offense for methods inside Class.new (let context)' do
      expect_no_offenses(<<~RUBY)
        RSpec.describe EmbeddedMonetizable do
          let(:model) do
            Class.new do
              include ActiveModel::Model

              def internal_safe_method
                true
              end
            end
          end
        end
      RUBY
    end

    it 'does not register an offense for methods inside Struct.new' do
      expect_no_offenses(<<~RUBY)
        describe 'Structs' do
          let(:struct) do
            Struct.new(:name) do
              def print_name
                puts name
              end
            end
          end
        end
      RUBY
    end
  end

  context 'when defining proper classes/modules (e.g. inside spec/support)' do
    # NOTA: Na prática, excluímos a pasta spec/support no .yml.
    # Mas aqui testamos a lógica pura: O container raiz gera ofensa, mas o método dentro dele NÃO.

    it 'registers offense for the root Module, but ignores the method inside (method is safe)' do
      expect_offense(<<~RUBY)
        module SafeHelpers
        ^^^^^^^^^^^^^^^^^^ Do not define methods, classes, or modules directly in the global scope or within spec blocks. This pollutes the namespace. Move this logic to `spec/support`, use `let`, or encapsulate it within a safe structure (e.g., `Class.new`).
          def safe_method
            # valid logic - Repara que aqui não há sublinhado (^^^^), logo é seguro!
          end
        end
      RUBY
    end

    it 'registers offense for the root Class, but ignores the method inside (method is safe)' do
      expect_offense(<<~RUBY)
        class TestHelper
        ^^^^^^^^^^^^^^^^ Do not define methods, classes, or modules directly in the global scope or within spec blocks. [...]
          def prepare_db
             # valid logic - Sem erro aqui também.
          end
        end
      RUBY
    end
  end
end
