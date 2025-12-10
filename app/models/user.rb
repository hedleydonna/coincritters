class User < ApplicationRecord
  # Include default devise modules. Others available are:
  # :confirmable, :lockable, :timeoutable, :trackable and :omniauthable
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable

  has_many :incomes, dependent: :destroy
  has_many :income_events, dependent: :destroy
  has_many :monthly_budgets, dependent: :destroy

  # Admin methods
  def admin?
    admin == true
  end

  has_many :monthly_budgets, dependent: :destroy

  def current_budget
    monthly_budgets.current || create_default_budget
  end

  private

  def create_default_budget
    monthly_budgets.create!(month_year: Time.current.strftime("%Y-%m"))
  end
end
