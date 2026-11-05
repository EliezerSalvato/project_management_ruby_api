class ApplicationForm
  include ActiveModel::Model
  include ActiveModel::Attributes
  include ActiveModel::Validations::Callbacks

  def initialize(attributes = {})
    super()
    assign_attributes(attributes) if attributes
  end

  def save
    return false unless valid?

    ApplicationRecord.transaction do
      persist
    end

    return false if errors.any?

    after_persist
    true
  end

  private

  def persist
    raise NotImplementedError
  end

  def after_persist
  end

  def halt!
    raise ActiveRecord::Rollback
  end

  def import_errors(record)
    record.errors.each do |error|
      errors.add(error.attribute, error.message)
    end
  end
end
