class Cidade < ActiveRecord::Base
  belongs_to :estado
  has_many :bairros, :dependent => :destroy
  has_many :locais, :dependent => :destroy

  has_slug :source_column => :nome,
           :scope => 'estado_id',
           :sync_slug => true,
           :prepend_id => false

  #=============================================================#
  #                     VALIDATIONS                             #
  #=============================================================#
  validates_presence_of :nome, :estado_id
  
  #=============================================================#
  #                     NAMED Scopes                            #
  #=============================================================#
  scope :do_estado, lambda { |estado_id| 
    if estado_id.blank?
      { }
    else 
      { :conditions => [ "cidades.estado_id = ?", estado_id ], 
        :order => "cidades.nome ASC" }
    end
  }
  
  scope :com_nome, lambda { |nome|
    if nome.blank?
      {}
    else
      {
        :conditions => [ "cidades.nome LIKE ?", '%' + nome + '%' ]
      }
    end
  }
  
  scope :com_topicos_do_contexto, lambda { |options|
    condicoes = []
    condicoes << "1=1"
    condicoes << "taggings.tag_id = #{options[:tag].id}" if options[:tag]
    condicoes << "topicos.created_at >= '#{options[:ultimos_dias].to_i.days.ago.to_s(:db)}'" if options[:ultimos_dias]
    condicoes << "topicos.type = '#{options[:topico_type].singularize.camelize}'" if options[:topico_type] and (options[:topico_type]!="topicos")
    condicoes << "users.type = '#{options[:user_type].singularize.camelize}'" if options[:user_type] and (options[:user_type]!="usuarios")

    sql_string = <<MYSTRING.gsub(/\s+|\t+/, " ").strip
    SELECT a.cidade_id, count(*) as total
    FROM (
      SELECT DISTINCT topicos.id, locais.cidade_id
      FROM locais JOIN topicos JOIN users JOIN taggings
      ON (locais.responsavel_type = 'Topico') AND
         (locais.responsavel_id = topicos.id) AND
         (taggings.taggable_type = 'Topico') AND
         (taggings.taggable_id = topicos.id) AND
         (topicos.user_id = users.id)
      WHERE #{condicoes.join(' AND ')}
    ) a GROUP BY a.cidade_id
MYSTRING
    { 
      :joins => "JOIN (#{sql_string}) z ON (cidades.id = z.cidade_id)",
      :select => "cidades.*, z.total",
      :conditions => "z.total > 0"
    }
  }
    
  scope :com_usuarios_do_contexto, lambda { |options|
    condicoes = []
    condicoes << "1=1"
    condicoes << "users.type = '#{options[:user_type].singularize.camelize}'" if options[:user_type] and (options[:user_type]!="usuarios")

    sql_string = <<MYSTRING.gsub(/\s+|\t+/, " ").strip
    SELECT a.cidade_id, count(*) as total
    FROM (
      SELECT DISTINCT users.id, locais.cidade_id
      FROM locais JOIN users
      ON (locais.responsavel_id = users.id) AND
         (locais.responsavel_type = 'User')
      WHERE #{condicoes.join(' AND ')}
    ) a GROUP BY a.cidade_id
MYSTRING
    { 
      :joins => "JOIN (#{sql_string}) z ON (cidades.id = z.cidade_id)",
      :select => "cidades.*, z.total",
      :conditions => "z.total > 0"
    }
  }
  
  #=============================================================#
  #                     Class METHODS                           #
  #=============================================================#

  # Faz a busca pelas cidades mais "ativas"
  def self.mais_ativas(options={})
    options = {
      :limit => 50,
      :order => "total DESC"
    }.merge!(options)
    find(:all,
         :select => " cidades.*, COUNT(*) AS total",
         :conditions => [], 
         :joins => "JOIN locais ON (locais.cidade_id = cidades.id) AND " +
                   "               (locais.responsavel_type = 'Topico') " +
                   "JOIN topicos ON (locais.responsavel_id = topicos.id) ",
         :group => "cidades.id",
         :limit => options[:limit], 
         :order => options[:order])
  end


  #=============================================================#
  #                     Object METHODS                          #
  #=============================================================#
  
  # Atualizacoes dos contadores
  def atualiza_contadores
    topicos_count = 0
    topicos_count = Topico.da_cidade(self).count(:all)

    topicos_relevancias_sum = 0
    Topico.da_cidade(self).find(:all).each { |t| topicos_relevancias_sum += t.relevancia }

    users_count = 0
    users_count = User.da_cidade(self).count(:all)
    
    users_relevancias_sum = 0
    User.da_cidade(self).find(:all).each { |u| users_relevancias_sum += u.relevancia }
    
    self.relevancia = (eval(Settings.localizacao_formula_relevancia)).to_i
    self.save(false)
  end
  
end
