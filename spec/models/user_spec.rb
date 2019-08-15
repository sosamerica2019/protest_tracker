# encoding: UTF-8
require 'rails_helper'
 
describe User, '#name' do
  it 'returns the concatenated first and last name' do
    user = build(:user, personal_name: 'Judith', family_name: 'Meyer')
    expect(user.name).to eq 'Judith Meyer'
  end
  
  it 'checks against non-names' do
    ["Judith http://www.learnlangs.com", "Judith www.learnlangs.com/new", "iuhuhiuh@localhost", "Michael!!!"].each do |e|
      user = build(:user, personal_name: e)
      expect(user.valid?).to eq false
      expect(user.errors.messages[:personal_name]).to include "only allows letters"
    end
    ["Judith", "Chuck Sterling S. Smith", "Γιάννης", "Michaέl", "Mäßen"].each do |e|
      user = build(:user, personal_name: e)
      expect(user.valid?).to eq true
    end
  end
end

describe User, '#email' do
  it 'checks against email addresses that are none' do
    ["not telling you", "hihuh@", "iuhuhiuh@localhost", "tttt@eo.", "tttt@eo.i"].each do |e|
      user = build(:user, email: e)
      expect(user.valid?).to eq false
      expect(user.errors.messages[:email]).to include "is not a valid email"
    end
    user = build(:user, email: "tttttttttttttt@testingthisjustnow.com")
    expect(user.valid?).to eq true
  end
  
  it 'checks against disposable email addresses' do
    ["nottelling@spamfree24.com", "hihuh@willselfdestruct.com", "iuhuhiuh@whyspam.me"].each do |e|
      user = build(:user, email: e)
      expect(user.valid?).to eq false
      expect(user.errors.messages[:email]).to include "cannot be a temporary email"
    end
  end
end

describe User, "temp_user" do
  it 'ensures temp users are not yet confirmed' do
    user = User.create_temp_user(personal_name: "Test", family_name: "Tester", email: "yutian.mei+temp#{rand(2000)}@gmail.com", mera25: "member")
    expect(user.verification_state).to eq(-1)
    expect(user.confirmed?).to be false
  end
end
