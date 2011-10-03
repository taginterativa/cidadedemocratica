class Imagem < ActiveRecord::Base
  belongs_to :responsavel, :polymorphic => true

  # Taken from: http://svn.techno-weenie.net/projects/plugins/attachment_fu/README
  has_attachment(
    :content_type => :image,
    :max_size => 2.megabytes,
    :resize_to => '640x480>',
    :thumbnails => { :thumb => [75, 75],
                     :small => '50x50',
                     :mini  => '30x30' },
    :storage => :file_system,
    :path_prefix => 'public/images/uploaded'
  )
  
  validates_as_attachment
  
  acts_as_list :scope => :responsavel
end