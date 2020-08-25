class AuthSession < ApplicationRecord
  ENABLED_METHODS = %w[AuthSessions::MobileId AuthSessions::SmartId AuthSessions::IdCard].freeze

  belongs_to :user
  validates :authenticator, :state, :channel, presence: true
  validates :type, inclusion: { in: ENABLED_METHODS }
  before_validation :populate_authenticator
  validate :validate_authenticator_validity

  def populate_authenticator
    return unless channel == 'IdCard'

    self.authenticator = user.personal_id
  end

  def usable?
    return true if state == 'AUTH_SUCCEEDED'

    puts "State was #{state}, which means unusable"
    false
  end

  def mark_as_used!
    update(state: 'LOCKED')
  end

  def self.supported_method?(some_class)
    unless some_class < AuthSession
      raise(Errors::ExpectedAuthSession, some_class)
    end

    if ENABLED_METHODS.include?(some_class.name)
      true
    else
      false
    end
  end

  def channel
    type.gsub('AuthSessions::', '')
  end

  def validate_authenticator_validity
    first_char = authenticator[0]
    auth_length = authenticator.length
    return true if channel == 'IdCard' # ID validatation done in User model
    return true if auth_length == 7 && first_char == '5'
    return true if auth_length == 8 && %w[5 8].include?(first_char)

    errors.add(:authenticator, :invalid)
  end

  def self.supported_methods
    enabled = []

    ENABLED_METHODS.each do |method|
      class_name = method.constantize
      unless class_name < AuthSession
        raise(Errors::ExpectedAuthSession, class_name)
      end

      enabled << class_name
    end

    enabled
  end
end
