# frozen_string_literal: true

require_relative 'skip_list'

RSpec.describe SkipList do
  let(:matrix) { %w[7.0 7.1 7.2 8.0] }

  describe '.applies?' do
    it 'treats a bare version as every Rails version' do
      expect(described_class.applies?(['0.57.0'], '0.57.0', '8.0')).to be(true)
    end

    it 'limits a Rails-scoped item to its Rails versions' do
      skip = [{ 'solargraph' => '0.57.0', 'rails' => %w[7.0 7.1] }]

      expect([described_class.applies?(skip, '0.57.0', '7.1'),
              described_class.applies?(skip, '0.57.0', '7.2'),
              described_class.applies?(skip, '0.58.2', '7.1')]).to eq([true, false, false])
    end

    it 'reads Rails versions written as YAML floats' do
      skip = YAML.safe_load("- solargraph: 0.57.0\n  rails: [7.0]\n")

      expect(described_class.applies?(skip, '0.57.0', '7.0')).to be(true)
    end

    it 'keeps the existing true, scalar and branch forms' do
      expect([described_class.applies?(true, '0.57.0', '8.0'),
              described_class.applies?(false, '0.57.0', '8.0'),
              described_class.applies?('0.57.0', '0.57.0', '8.0'),
              described_class.applies?(['branch-castwide-master'], 'branch-foo', '8.0')])
        .to eq([true, false, true, true])
    end

    it 'accepts a Rails-scoped item only for Solargraph releases below 0.60' do
      allowed = [{ 'solargraph' => '0.58.2', 'rails' => ['7.0'] }]

      expect(described_class.applies?(allowed, '0.58.2', '7.0')).to be(true)
    end

    it 'raises on a Rails-scoped item for Solargraph 0.60 or later' do
      skip = ['0.48.0', { 'solargraph' => '0.60.0', 'rails' => ['7.0'] }]

      expect { described_class.applies?(skip, '0.57.0', '8.0') }
        .to raise_error(SkipList::ScopedSkipError, /annotation/)
    end

    it 'raises on a Rails-scoped item for a Solargraph branch' do
      skip = [{ 'solargraph' => 'branch-castwide-master', 'rails' => ['7.0'] }]

      expect { described_class.applies?(skip, 'branch-castwide-master', '7.0') }
        .to raise_error(SkipList::ScopedSkipError, /annotation/)
    end
  end

  describe '.add' do
    it 'skips only the failing Rails version below Solargraph 0.60' do
      data = { 'skip' => false }
      described_class.add(data, '0.57.0', '7.0', matrix)

      expect(data['skip']).to eq([{ 'solargraph' => '0.57.0', 'rails' => ['7.0'] }])
    end

    it 'adds a bare version on Solargraph 0.60 or later' do
      data = { 'skip' => false }
      described_class.add(data, '0.61.0', '8.0', %w[7.2 8.0])

      expect(data['skip']).to eq(['0.61.0'])
    end

    it 'leaves a bare version alone' do
      data = { 'skip' => ['0.57.0'] }
      described_class.add(data, '0.57.0', '7.0', matrix)

      expect(data['skip']).to eq(['0.57.0'])
    end

    it 'extends a Rails-scoped item for the version' do
      data = { 'skip' => ['0.48.0', { 'solargraph' => '0.57.0', 'rails' => ['7.0'] }] }
      described_class.add(data, '0.57.0', '7.1', matrix)

      expect(data['skip']).to eq(['0.48.0', { 'solargraph' => '0.57.0', 'rails' => %w[7.0 7.1] }])
    end

    it 'collapses a Rails-scoped item that covers every matrix Rails version' do
      data = { 'skip' => [{ 'solargraph' => '0.58.2', 'rails' => ['7.2'] }] }
      described_class.add(data, '0.58.2', '8.0', %w[7.2 8.0])

      expect(data['skip']).to eq(['0.58.2'])
    end
  end

  describe '.remove' do
    it 'scopes a bare version to the other matrix Rails versions' do
      data = { 'skip' => ['0.48.0', '0.57.0'] }
      described_class.remove(data, '0.57.0', '7.2', matrix)

      expect(data['skip']).to eq(['0.48.0', { 'solargraph' => '0.57.0', 'rails' => %w[7.0 7.1 8.0] }])
    end

    it 'drops the current Rails version from a scoped item, then the item' do
      data = { 'skip' => [{ 'solargraph' => '0.57.0', 'rails' => %w[7.0 7.1] }] }
      described_class.remove(data, '0.57.0', '7.0', matrix)
      after_first = Marshal.load(Marshal.dump(data['skip']))
      described_class.remove(data, '0.57.0', '7.1', matrix)

      expect([after_first, data['skip']])
        .to eq([[{ 'solargraph' => '0.57.0', 'rails' => ['7.1'] }], false])
    end

    it 'collapses a scoped item covering every matrix Rails version' do
      data = { 'skip' => ['0.57.0'] }
      described_class.remove(data, '0.57.0', '6.1', matrix)

      expect(data['skip']).to eq(['0.57.0'])
    end

    it 'removes a bare version outright on Solargraph 0.60 or later' do
      data = { 'skip' => ['0.48.0', '0.61.0'] }
      described_class.remove(data, '0.61.0', '7.2', %w[7.2 8.0])

      expect(data['skip']).to eq(['0.48.0'])
    end

    it 'removes a bare version outright when it is the only matrix Rails version' do
      data = { 'skip' => ['0.61.0'] }
      described_class.remove(data, '0.61.0', '8.0', ['8.0'])

      expect(data['skip']).to be(false)
    end
  end

  describe '.matrix_rails_versions' do
    it 'leaves out Rails versions the CI matrix excludes for a Solargraph version' do
      expect([described_class.matrix_rails_versions('0.57.0'),
              described_class.matrix_rails_versions('0.61.0')])
        .to eq([%w[7.0 7.1 7.2 8.0], %w[7.2 8.0]])
    end
  end
end
