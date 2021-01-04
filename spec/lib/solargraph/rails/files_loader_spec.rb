require 'solargraph/rails/files_loader'

RSpec.describe Solargraph::Rails::FilesLoader do
  it 'passes file contents to block' do
    file_fixture('test.txt')
    loader = Solargraph::Rails::FilesLoader.new(['test.txt'])
    blk = lambda do |file_name, content|
      expect(file_name).to eq('test.txt')
      expect(content).to eq(file_contents)
    end
    loader.each(&blk)
  end

  it 'calls block once for each file name' do
    file_fixture('test1.txt')
    file_fixture('test2.txt')
    file_fixture('test3.txt')
    blk = lambda {}
    expect(blk).to receive(:call).exactly(3).times
    loader = Solargraph::Rails::FilesLoader.new(
      ['test1.txt', 'test2.txt', 'test3.txt']
    ).each(&blk)
  end

  def file_fixture(filename='test.txt')
    File.write(filename, file_contents)
  end

  def file_contents
    <<-FILE
      a file indeed
    FILE
  end
end
