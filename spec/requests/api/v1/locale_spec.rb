require "rails_helper"

RSpec.describe "API locale selection", type: :request do
  let(:user) { create(:user, :verified) }

  def get_missing_project(headers = {})
    get "/api/v1/projects/#{SecureRandom.uuid}", headers: auth_headers_for(user).merge(headers)
  end

  def message_in(locale)
    I18n.t("api.errors.not_found", locale:)
  end

  it "answers in the default locale without a cookie or Accept-Language" do
    get_missing_project

    expect(response.parsed_body["message"]).to eq(message_in(:"pt-BR"))
  end

  it "answers in the locale from Accept-Language when no cookie reaches the API" do
    get_missing_project("Accept-Language" => "en")

    expect(response.parsed_body["message"]).to eq(message_in(:en))
  end

  it "picks the highest-weighted supported language from Accept-Language" do
    get_missing_project("Accept-Language" => "fr;q=1.0, pt;q=0.5, en-US;q=0.8")

    expect(response.parsed_body["message"]).to eq(message_in(:en))
  end

  it "matches a bare language or a lowercase tag to the supported locale" do
    [ "pt", "pt-br", "pt-PT" ].each do |accept_language|
      get_missing_project("Accept-Language" => accept_language)

      expect(response.parsed_body["message"]).to eq(message_in(:"pt-BR")), "#{accept_language} was not answered in pt-BR"
    end
  end

  it "falls back to the default locale for an unsupported Accept-Language" do
    get_missing_project("Accept-Language" => "fr-FR, de;q=0.9")

    expect(response.parsed_body["message"]).to eq(message_in(:"pt-BR"))
  end

  it "skips empty entries in Accept-Language" do
    get_missing_project("Accept-Language" => ", ;q=0.9, en")

    expect(response.parsed_body["message"]).to eq(message_in(:en))
  end

  it "prefers the locale cookie over Accept-Language" do
    cookies[:locale] = "en"

    get_missing_project("Accept-Language" => "pt-BR")

    expect(response.parsed_body["message"]).to eq(message_in(:en))
  end
end
