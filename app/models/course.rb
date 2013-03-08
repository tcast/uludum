class Course < ActiveRecord::Base
  has_many :sections
  has_many :subsections
  has_many :questions
  has_many :enrollments
  has_many :enrolled_students, through: :enrollments, source: :user
  belongs_to :teacher, class_name: 'User', foreign_key: 'teacher_id'

  scope :visible, where(hidden: false)
  scope :best, joins(:questions).select("courses.*, count(questions.id) as question_count").order('question_count desc').group('courses.id')

  validates_presence_of :title, :description, :category, :teacher_id
  attr_accessible :category, :description, :teacher_id, :title, :hidden

  def self.categories hidden=false
    self.visible.select("DISTINCT(category) , count(*) as count").group("category").order('category').all
  end

  def percent_complete(user)
    completion = 0
    count = 0
    self.subsections.each do |s|
      if s.questions.count == 0
        completion += 100 if s.complete?(user)
        count += 1
      else
        completion += s.percent_complete(user)
        count += 1
      end        
    end
    (completion / count).to_i
  end
end
