require 'active_model/validations'

class UserWithNoPreQuery
  include ActiveModel::Validations

  attr_accessor :homepage

  validates :homepage, :url => {:no_pre_query => true}
end
