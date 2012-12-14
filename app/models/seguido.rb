class Seguido < ActiveRecord::Base
  belongs_to :user
  belongs_to :topico
  
  validates_uniqueness_of :topico_id, :scope => :user_id


  scope :por_user_ativo, 
              :include => [:user], 
              :conditions => ["users.state = 'active'"]        
end
