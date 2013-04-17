class UserMailer < ActionMailer::Base
  default from: "info@uludum.org"
  add_template_helper(ApplicationHelper)

  def welcome_email(user)
    @user = user
    mail(to: user.email, subject: "Welcome to Uludum!", cc: "info@uludum.org")
  end

  def order_complete(order)
    self.class.seller_order_complete(order).deliver
    @user = order.user
    @order = order
    mail(subject: "Your Uludum order is complete.", to: @user.email)
  end

  def order_processing(order)
    self.class.new_seller_order(order).deliver
    @user = order.user
    @order = order
    mail(subject: "Your Uludum order is processing.", to: @user.email)
  end

  def new_seller_order(order)
    @user = order.orderable.user
    @order = order
    mail(subject: "You have a new payment processing for #{@order.orderable.title}", to: @user.email)
  end

  def seller_order_complete(order)
    @user = order.orderable.user
    @order = order
    mail(subject: "Payment complete for #{@order.orderable.title}", to: @user.email)
  end

  def request_skills(user, email, wish, note=nil)
    @note = note
    @email = email
    @from_user = user
    @wish = wish
    mail(subject: "Your skills have been requested on uludum.org", to: @email)
  end

end
