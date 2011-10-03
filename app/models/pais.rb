class Pais < ActiveRecord::Base
  validates_presence_of :iso, :nome
end