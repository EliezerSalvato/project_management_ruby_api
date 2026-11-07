require "rails_helper"

RSpec.describe ApplicationForm do
  let(:form_class) do
    Class.new(described_class) do
      attribute :name, :string

      def self.model_name = ActiveModel::Name.new(self, nil, "ExampleForm")
    end
  end

  it "accepts nil attributes" do
    expect(form_class.new(nil).name).to be_nil
  end

  it "requires subclasses to implement persist" do
    expect { form_class.new(name: "Example").save }.to raise_error(NotImplementedError)
  end
end
