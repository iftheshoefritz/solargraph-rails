RSpec.describe SolargraphRails::DynamicAttributes do
  it 'adds pins' do
    files = [
      [
        'app/models/model1.rb',
        <<-FILE
          # id    :integer
          # name  :string
          class MyModel < ApplicationRecord
        FILE
      ],
      [
        'app/models/model2.rb',
        <<-FILE
          # id    :integer
          # name  :string
          # created_at :date
          class MyModel < ApplicationRecord
        FILE
      ]
    ]
    allow_any_instance_of(SolargraphRails::FilesLoader).to receive(:each) do |&blk|
      blk.call(*files[0])
      blk.call(*files[1])
    end

    environ = SolargraphRails::DynamicAttributes
                .new
                .global(double('Solargraph::YardMap'))

    expect(environ.pins.count).to eq(5)
  end
end
