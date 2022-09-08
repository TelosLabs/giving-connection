# performer represents the block created with the let/let! method that is called between examples

RSpec.shared_examples 'creates a new object through nested attributes' do |referring_model|
    it "should increment the #{referring_model.name} records by 1" do
        expect { performer }.to change {referring_model.count}.by(1)
    end
end

RSpec.shared_examples "doesn't create a new object because nested attributes are blank" do |referring_model|
    it "shouldn't create #{referring_model.name} records" do
        expect { performer_blank }.not_to change { referring_model.count }
    end
end