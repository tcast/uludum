class User < ActiveRecord::Base
  has_many :courses, foreign_key: 'teacher_id'
  has_many :enrolled_courses, through: :enrollments, source: :course
  has_many :enrollments
  # new columns need to be added here to be writable through mass assignment
  attr_accessible :username, :email, :password, :password_confirmation, :about_me, :teacher_description, :avatar_url  

  attr_accessor :password
  before_save :prepare_password
  before_validation :clear_blank_avatar_url

  validates_presence_of :username, :email
  validates_uniqueness_of :username, :email, :allow_blank => true, case_sensitive: false
  validates_format_of :username, :with => /^[-\w\._@]+$/i, :allow_blank => true, :message => "should only contain letters, numbers, or .-_@"
  validates_format_of :email, :with => /^[-a-z0-9_+\.]+\@([-a-z0-9]+\.)+[a-z0-9]{2,4}$/i
  validates_presence_of :password, :on => :create
  validates_confirmation_of :password
  validates_length_of :password, :minimum => 4, :allow_blank => true

  # login can be either username or email address
  def self.authenticate(login, pass)
    user = find(:first, :conditions => ['lower(username) = ?', login.downcase]) || find(:first, :conditions => ['lower(email) = ?', login.downcase])
    return user if user && user.password_hash == user.encrypt_password(pass)
  end

  def encrypt_password(pass)
    BCrypt::Engine.hash_secret(pass, password_salt)
  end

  def enroll course_id
    self.enrollments.create(course_id: course_id)
  end

  def enrollment_in course
    self.enrollments.where(course_id: course.id)
  end

  def points
    points = 0
    enrolled_courses.each do |course|
      points += course.percent_complete(self) * 10
    end
    courses.each do |course|
      points += 500
    end
    points
  end

  private

  def prepare_password
    unless password.blank?
      self.password_salt = BCrypt::Engine.generate_salt
      self.password_hash = encrypt_password(password)
    end
  end

  def clear_blank_avatar_url
    if avatar_url.blank?
      self.avatar_url = nil
    end
  end
end
