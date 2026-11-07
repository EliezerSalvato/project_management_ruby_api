require "rails_helper"

RSpec.describe UUID do
  describe ".generate" do
    it "returns a valid UUID v7" do
      expect(described_class.valid?(described_class.generate)).to be(true)
    end
  end

  describe ".valid?" do
    it "rejects a UUID of another version" do
      expect(described_class.valid?(SecureRandom.uuid)).to be(false)
    end

    it "rejects a malformed string" do
      expect(described_class.valid?("not-a-uuid")).to be(false)
    end

    it "raises when given something other than a String" do
      expect { described_class.valid?(nil) }.to raise_error(NoMatchingPatternError)
    end
  end
end
