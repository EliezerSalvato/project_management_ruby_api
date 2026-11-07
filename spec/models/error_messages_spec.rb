require "rails_helper"

# Domain errors are translated through the form i18n key, which follows the class
# namespace. Moving or renaming a form silently orphans its keys in the YAML files,
# and `raise_on_missing_translations` only guards the locale the suite runs in.
RSpec.describe "Domain error messages" do
  let(:model_files) { Rails.root.glob("app/models/**/*.rb") }

  let(:app_locales) do
    Rails.root.glob("config/locales/**/*.yml").flat_map { |path| YAML.load_file(path).keys }.uniq.map(&:to_sym)
  end

  let(:forms) do
    model_files.filter_map { |path| constant_for(path) }.select { |constant| constant.is_a?(Class) && constant < ApplicationForm }
  end

  # A shared module (e.g. Project::Validations) owns its `errors.add` calls on behalf of
  # every form that includes it, so its usages are attributed to each of those forms.
  let(:error_usages) do
    model_files.flat_map do |path|
      usages = path.read.scan(/errors\.add\(:(\w+), :(\w+)\)/).uniq
      owner = constant_for(path)

      next [] if usages.empty? || !owner.is_a?(Module)

      forms.select { |form| form <= owner }.product(usages).map do |form, (attribute, type)|
        [ form, attribute.to_sym, type.to_sym ]
      end
    end
  end

  def constant_for(path)
    path.relative_path_from(Rails.root.join("app/models")).sub_ext("").to_s.camelize.safe_constantize
  end

  def translatable?(form, attribute, type)
    form.new.errors.generate_message(attribute, type)

    true
  rescue I18n::MissingTranslationData
    false
  end

  it "collects the error usages it is meant to check" do
    expect(app_locales).to contain_exactly(:en, :"pt-BR")
    expect(error_usages).to include(
      [ User::Password::Reset::SendInstructions, :email, :not_found ],
      [ Project::Search, :after, :not_found ],
      [ Project::Creation, :start_date, :before_today ],
      [ Project::Update, :cover_image, :file_size ]
    )
  end

  it "translates every domain error in every locale supported by the app" do
    untranslated = app_locales.flat_map do |locale|
      I18n.with_locale(locale) do
        error_usages
          .reject { |form, attribute, type| translatable?(form, attribute, type) }
          .map { |form, attribute, type| "[#{locale}] #{form}: #{attribute}.#{type}" }
      end
    end

    expect(untranslated).to be_empty
  end
end
