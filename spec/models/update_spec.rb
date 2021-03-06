require 'spec_helper'

describe Update do
  describe "after create" do
    let(:updateable) { create :fund }
    let(:user) {
      user = create :user
      order = user.orders.build
      order.orderable = updateable
      order.price = updateable.price
      order.save!
      user
    }
    it "should send an email to all funders when an update is created" do
      update = build :update
      update.updateable = updateable
      UserMailer.should_receive(:new_update).with(update, user).once.and_call_original
      update.save!
    end
  end
end
