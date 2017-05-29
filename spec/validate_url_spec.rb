# encoding: utf-8
require 'spec_helper'

describe "URL validation" do

  before(:all) do
    ActiveRecord::Schema.define(:version => 1) do

      create_table :users, :force => true do |t|
        t.column :homepage, :string
      end

    end
  end

  after(:all) do
    ActiveRecord::Base.connection.drop_table(:users)
  end

  context "with regular validator" do
    before do
      @user = User.new
    end

    it "should not allow nil as url" do
      @user.homepage = nil
      expect(@user).not_to be_valid
    end

    it "should not allow blank as url" do
      @user.homepage = ""
      expect(@user).not_to be_valid
    end

    it "should not allow an url without scheme" do
      @user.homepage = "www.example.com"
      expect(@user).not_to be_valid
    end

    it "should allow an url with http" do
      @user.homepage = "http://localhost"
      expect(@user).to be_valid
    end

    it "should allow an url with https" do
      @user.homepage = "https://localhost"
      expect(@user).to be_valid
    end

    it "should not allow a url with an invalid scheme" do
      @user.homepage = "ftp://localhost"
      expect(@user).not_to be_valid
    end

    it "should not allow a url with only a scheme" do
      @user.homepage = "http://"
      expect(@user).not_to be_valid
    end

    it "should not allow a url without a host" do
      @user.homepage = "http:/"
      expect(@user).not_to be_valid
    end

    it "should allow a url with an underscore" do
      @user.homepage = "http://foo_bar.com"
      expect(@user).to be_valid
    end

    it "should allow a url with query only if it has a path" do
      @user.homepage = "http://foo_bar.com/?"
      expect(@user).to be_valid
      @user.homepage = "http://foo_bar.com/?a=b"
      expect(@user).to be_valid
      @user.homepage = "http://foo_bar.com?a=b"
      expect(@user).not_to be_valid
    end

    it "should not allow a url with no host but a query" do
       @user.homepage = "http:///?a=b"
       expect(@user).not_to be_valid
       @user.homepage = "http://?"
       expect(@user).not_to be_valid
    end

    it "should return a default error message" do
      @user.homepage = "invalid"
      error_message = "A host and scheme (ex. 'http://adgear.com') are required", "Must begin with 'http://' or 'https://'"
      @user.valid?
      expect(@user.errors[:homepage]).to eq(error_message)
    end

  end

  context "with allow nil" do
    before do
      @user = UserWithNil.new
    end

    it "should allow nil as url" do
      @user.homepage = nil
      expect(@user).to be_valid
    end

    it "should not allow blank as url" do
      @user.homepage = ""
      expect(@user).not_to be_valid
    end

    it "should allow a valid url" do
      @user.homepage = "http://www.example.com"
      expect(@user).to be_valid
    end

    it "should allow a url with an underscore" do
      @user.homepage = "http://foo_bar.com"
      expect(@user).to be_valid
    end
  end

  context "with allow blank" do
    before do
      @user = UserWithBlank.new
    end

    it "should allow nil as url" do
      @user.homepage = nil
      expect(@user).to be_valid
    end

    it "should allow blank as url" do
      @user.homepage = ""
      expect(@user).to be_valid
    end

    it "should allow a valid url" do
      @user.homepage = "http://www.example.com"
      expect(@user).to be_valid
    end

    it "should allow a url with an underscore" do
      @user.homepage = "http://foo_bar.com"
      expect(@user).to be_valid
    end
  end

  context "with no_local" do
    before do
      @user = UserWithNoLocal.new
    end

    it "should allow a valid internet url" do
      @user.homepage = "http://www.example.com"
      expect(@user).to be_valid
    end

    it "should not allow a local hostname" do
      @user.homepage = "http://localhost"
      expect(@user).not_to be_valid
    end

    it "should not allow weird urls that get interpreted as local hostnames" do
      @user.homepage = "http://http://example.com"
      expect(@user).not_to be_valid
    end
  end

  context "with public_suffix" do
    before do
      @user = UserWithPublicSuffix.new
    end

    it "should allow a valid public suffix" do
      @user.homepage = "http://www.example.com"
      @user.should be_valid
    end

    it "should not allow a local hostname" do
      @user.homepage = "http://localhost"
      @user.should_not be_valid
    end

    it "should not allow non public hosts suffixes" do
      @user.homepage = "http://example.not_a_valid_tld"
      @user.should_not be_valid
    end
  end

  context "with legacy syntax" do
    before do
      @user = UserWithLegacySyntax.new
    end

    it "should allow nil as url" do
      @user.homepage = nil
      expect(@user).to be_valid
    end

    it "should allow blank as url" do
      @user.homepage = ""
      expect(@user).to be_valid
    end

    it "should allow a valid url" do
      @user.homepage = "http://www.example.com"
      expect(@user).to be_valid
    end

    it "should not allow invalid url" do
      @user.homepage = "random"
      expect(@user).not_to be_valid
    end

    it "should allow a url with an underscore" do
      @user.homepage = "http://foo_bar.com"
      expect(@user).to be_valid
    end
  end

  context "with ActiveRecord" do
    before do
      @user = UserWithAr.new
    end

    it "should not allow invalid url" do
      @user.homepage = "random"
      expect(@user).not_to be_valid
    end
  end

  context "with ActiveRecord and legacy syntax" do
    before do
      @user = UserWithArLegacy.new
    end

    it "should not allow invalid url" do
      @user.homepage = "random"
      expect(@user).not_to be_valid
    end
  end

  context "with regular validator and custom scheme" do
    before do
      @user = UserWithCustomScheme.new
    end

    it "should allow alternative URI schemes" do
      @user.homepage = "ftp://ftp.example.com"
      expect(@user).to be_valid
    end
  end

  context "with custom message" do
    before do
      @user = UserWithCustomMessage.new
    end

    it "should use custom message" do
      @user.homepage = "invalid"
      @user.valid?
      expect(@user.errors[:homepage]).to eq(["wrong"])
    end
  end
end
