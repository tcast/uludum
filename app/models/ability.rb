class Ability
  include CanCan::Ability

  def initialize(user)
    user ||= User.new
    can :manage, Course, teacher_id: user.id
    can :read, Section do |section|
      !section.course.enrollments.find(:first, conditions: ["user_id = ?", user.id]).nil?
    end
    can :read, Subsection do |subsection|
      !subsection.course.enrollments.find(:first, conditions: ["user_id = ?", user.id]).nil?
    end
    can :manage, User, id: user.id
    can :create, Wish unless user.new_record?
    can :manage, Wish, user_id: user.id
    can :manage, Order, user_id: user.id
    can :manage, Fund, user_id: user.id
    can :manage, Enrollment, user_id: user.id
    can :manage, Section, course: { teacher_id: user.id }
    can :manage, Subsection, course: { teacher_id: user.id }
    can :manage, Question, course: { teacher_id: user.id }
    can :manage, Discussion, user_id: user.id
    can :read, Order, user_id: user.id
    can :read, Order, orderable: { user: user }
    can :read, Course, hidden: false
    can :read, Course, enrollments: { user_id: user.id }
    can :read, Fund, hidden: false
    can :read, Fund, user_id: user.id
    can :manage, :all if user.is_admin?
    can :manage, WishVote, user_id: user.id

    # https://github.com/ryanb/cancan/wiki/Defining-Abilities
  end
end
