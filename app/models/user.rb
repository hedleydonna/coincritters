class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  # Ensure display_name attribute is accessible
  def display_name
    self[:display_name]
  end

  def display_name=(value)
    self[:display_name] = value
  end
end
