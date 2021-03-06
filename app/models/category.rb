class Category < ActiveRecord::Base
  validates_uniqueness_of :name
  # extend FriendlyId
  # friendly_id :name, use: :slugged

  default_scope -> { 
    order('(select count(*) as counted from courses where courses.category_id = categories.id and courses.hidden = false) desc') 
  }

  has_many :courses

  attr_accessible :name
  
end
