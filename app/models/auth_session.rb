class AuthSession < ApplicationRecord
  ENABLED_METHODS = %w[AuthSessions::MobileId AuthSessions::SmartId AuthSessions::IdCard].freeze

  belongs_to :user
  validates :authenticator, :state, :channel, presence: true
  validates :type, inclusion: { in: ENABLED_METHODS }

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
