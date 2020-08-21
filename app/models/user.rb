class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable, :rememberable
  has_many :authentications
  has_many :documents
  before_create :set_strong_password

  def set_strong_password
    self.password = SecureRandom.hex(32)
  end
  # attr_ass :first_name, :last_name, :mid_number, :personal_id, :email, :country_alpha3
end
