require "rails_helper"

RSpec.describe "Rack::Attack throttling", type: :request do
  let(:original_store) { Rack::Attack.cache.store }

  before do
    original_store
    Rack::Attack.cache.store = ActiveSupport::Cache::MemoryStore.new
  end

  after { Rack::Attack.cache.store = original_store }

  def post_authentication
    post "/api/v1/user/authentications", params: { email: "user@example.com", password: "wrong" }, as: :json
  end

  it "throttles sign-in attempts after 10 requests per minute from the same IP" do
    10.times { post_authentication }

    expect(response).not_to have_http_status(:too_many_requests)

    post_authentication

    expect(response).to have_http_status(:too_many_requests)
  end
end
