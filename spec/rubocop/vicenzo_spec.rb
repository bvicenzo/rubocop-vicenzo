# frozen_string_literal: true

RSpec.describe Rubocop::Vicenzo do
  describe 'version' do
    it 'has a version number' do
      expect(Rubocop::Vicenzo::VERSION).not_to be_nil
    end
  end
end
