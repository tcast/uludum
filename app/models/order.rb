class Order < ActiveRecord::Base
  require 'queue_helpers'
  include MixpanelHelpers
  validates_presence_of :user_id, :orderable_type, :orderable_id, :price
  belongs_to :orderable, polymorphic: true
  belongs_to :user

  scope :completed, -> { where("token != ? OR token != ?", "", nil) }
  scope :grouped, -> { group("user_id").select("sum(price) as sum").select("user_id") }

  APPLICATION_FEE = 0.05
  FAIL_FEE = 0.04

  # If order is for a fund, default to fund.price.
  before_validation do
    if orderable.class == Fund
      self.price ||= orderable.price
    end
  end

  after_save do
    if paid == true && (paid_changed? || self.id_changed?)
      autoenroll
      job = Afterparty::MailerJob.new UserMailer, :order_complete , self
    elsif self.id_changed?
      job = Afterparty::MailerJob.new UserMailer, :order_processing, self
    end
    Rails.configuration.queue << job
  end

  after_create do
    if orderable_type == "Course"
      complete
    end
  end

  # If fund is newly finished, trigger fund completion
  after_create do
    return true unless orderable.is_a?(Fund)
    return true unless orderable.progress + price >= orderable.goal
    return true unless orderable.course_id && orderable.course.ready?
    return true unless orderable.finished?
    if orderable.progress - self.price < orderable.goal
      orderable.finish_orders
    else
      complete
    end
  end

  # set extra_fee = true if unsuccessful fund
  # to charge extra 4%
  def complete extra_fee=false
    return true if self.paid == true
    begin
      #use our own api key only in testing curcumstances
      test_mode = Rails.env.test? && orderable.user.stripe_key.blank?
      oauth_key = test_mode ? "sk_test_XF2SctReftg7417qgx56Iy6R" : orderable.user.stripe_key
      charge = Stripe::Charge.create({
        amount: (price * 100).to_i,
        currency: "usd",
        customer: user.stripe_customer_id,
        description: "Order for #{orderable.title.titleize}",
        application_fee: order_fee(extra_fee)
      }, oauth_key)
      self.paid = true
      save!
    rescue Stripe::CardError => e
      # Since it's a decline, Stripe::CardError will be caught
      body = e.json_body
      err  = body[:error]

      logger.fatal "Status is: #{e.http_status}"
      logger.fatal "Type is: #{err[:type]}"
      logger.fatal "Code is: #{err[:code]}"
      # param is '' in this case
      logger.fatal "Param is: #{err[:param]}"
      logger.fatal "Message is: #{err[:message]}"
      # if Rails.env.development? || Rails.env.production?
      #   raise e
      # end
    rescue Stripe::InvalidRequestError => e
      # Invalid parameters were supplied to Stripe's API
      raise e
    rescue Stripe::AuthenticationError => e
      # Authentication with Stripe's API failed
      # (maybe you changed API keys recently)
      raise e
    rescue Stripe::APIConnectionError => e
      # Network communication with Stripe failed
      raise e
    rescue Stripe::StripeError => e
      # Display a very generic error to the user, and maybe send
      # yourself an email
      raise e
    rescue => e
      # Something else happened, completely unrelated to Stripe
      raise e
    end
    self
  end

  def status
    if Fund === orderable && paid != true
      return "waiting for fund completion"
    end
    if paid != true
      return "processing"
    elsif paid == true
      return "completed"
    end
  end

  def order_fee extra_fee=false
    fee = APPLICATION_FEE
    fee += FAIL_FEE if extra_fee
    ((price * fee) * 100).to_i
  end

  private

  def autoenroll
    if orderable.class == Course && price >= orderable.price
      user.enroll orderable
    elsif orderable.class == Fund && orderable.course && orderable.course.ready? && price >= orderable.price
      user.enroll orderable.course
    end
  end

end
