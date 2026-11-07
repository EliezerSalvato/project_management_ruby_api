module Project::Validations
  extend ActiveSupport::Concern

  included do
    attribute :name, :string
    attribute :client_name, :string
    attribute :start_date, :date
    attribute :end_date, :date
    attribute :cover_image

    before_validation :normalize_names

    validates :name, :client_name, :start_date, :end_date, presence: true
    validates :name, :client_name, length: { maximum: 255 }
    validate :name_has_two_words
    validate :dates_not_before_today
    validate :end_date_not_before_start_date
    validate :cover_image_type_and_size, if: -> { cover_image.present? }
  end

  private

  def normalize_names
    self.name = Project::Text.strip(name)
    self.client_name = Project::Text.strip(client_name)
  end

  def name_has_two_words
    return if name.blank? || name.split(Project::Text::WHITESPACE).size >= 2

    errors.add(:name, :two_words)
  end

  def dates_not_before_today
    errors.add(:start_date, :before_today) if before_today?(:start_date)
    errors.add(:end_date, :before_today) if before_today?(:end_date)
  end

  def before_today?(field)
    date = public_send(field)

    date.present? && date_checked?(field) && date < Date.current
  end

  def end_date_not_before_start_date
    return unless start_date && end_date && end_date < start_date

    errors.add(:end_date, :before_start_date)
  end

  def cover_image_type_and_size
    unless cover_image.is_a?(ActionDispatch::Http::UploadedFile) && Project::CoverImage::CONTENT_TYPES.include?(sniffed_content_type)
      return errors.add(:cover_image, :content_type)
    end

    errors.add(:cover_image, :file_size) if cover_image.size > Project::CoverImage::MAX_SIZE
  end

  def sniffed_content_type
    Marcel::MimeType.for(cover_image.tempfile)
  ensure
    cover_image.tempfile.rewind
  end
end
