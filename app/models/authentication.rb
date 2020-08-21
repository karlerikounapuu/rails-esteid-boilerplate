class Authentication < ApplicationRecord
  belongs_to :user
  validates :authenticator, :state, :channel, presence: true
  validate :channel_is_valid
  include MobileIdAuthenticatable

  def usable?
    return true if state == 'AUTH_SUCCEEDED'

    puts "State was #{state}, which means unusable"
    false
  end

  def mark_as_used!
    update(state: 'LOCKED')
  end

  def channel_is_valid
    %w[Mobile-ID Smart-ID ID-card].each do |ch|
      return true if channel == ch
    end

    errors.add(:channel, :invalid)
  end
end
