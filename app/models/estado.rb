class Estado < ActiveRecord::Base
  has_many :cidades, :dependent => :destroy

  #=======================================================#
  #                     VALIDATIONS                       #
  #=======================================================#
  validates_presence_of :nome

  #=======================================================#
  #                     NAMED Scopes                      #
  #=======================================================#
  named_scope :com_topicos_do_contexto, lambda { |options|
    condicoes = []
    condicoes << "1=1"
    condicoes << "taggings.tag_id = #{options[:tag].id}" if options[:tag]
    condicoes << "topicos.created_at >= '#{options[:ultimos_dias].to_i.days.ago.to_s(:db)}'" if options[:ultimos_dias]
    condicoes << "topicos.type = '#{options[:topico_type].singularize.camelize}'" if options[:topico_type] and (options[:topico_type]!="topicos")
    condicoes << "users.type = '#{options[:user_type].singularize.camelize}'" if options[:user_type] and (options[:user_type]!="usuarios")

    sql_string = <<MYSTRING.gsub(/\s+|\t+/, " ").strip
    SELECT a.estado_id, count(*) as total
    FROM (
      SELECT DISTINCT topicos.id, locais.estado_id
      FROM locais JOIN topicos JOIN users JOIN taggings
      ON (locais.responsavel_type = 'Topico') AND
         (locais.responsavel_id = topicos.id) AND
         (taggings.taggable_type = 'Topico') AND
         (taggings.taggable_id = topicos.id) AND
         (topicos.user_id = users.id)
      WHERE #{condicoes.join(' AND ')}
    ) a GROUP BY a.estado_id
MYSTRING
    { 
      :joins => "JOIN (#{sql_string}) z ON (estados.id = z.estado_id)",
      :select => "estados.*, z.total",
      :conditions => "z.total > 0"
    }
  }
  named_scope :com_usuarios_do_contexto, lambda { |options|
    condicoes = []
    condicoes << "1=1"
    condicoes << "users.type = '#{options[:user_type].singularize.camelize}'" if options[:user_type] and (options[:user_type]!="usuarios")

    sql_string = <<MYSTRING.gsub(/\s+|\t+/, " ").strip
    SELECT a.estado_id, count(*) as total
    FROM (
      SELECT DISTINCT users.id, locais.estado_id
      FROM locais JOIN users
      ON (locais.responsavel_id = users.id) AND
         (locais.responsavel_type = 'User')
      WHERE #{condicoes.join(' AND ')}
    ) a GROUP BY a.estado_id
MYSTRING
    { 
      :joins => "JOIN (#{sql_string}) z ON (estados.id = z.estado_id)",
      :select => "estados.*, z.total",
      :conditions => "z.total > 0"
    }
  }
  
  #=======================================================#
  #                   Object METHODS                      #
  #=======================================================#
  def slug
    self.abrev.to_s.downcase
  end
  
  # Atualizacoes dos contadores
  def atualiza_contadores
    topicos_count = 0
    topicos_count = Topico.do_estado(self).count(:all)

    topicos_relevancias_sum = 0
    Topico.do_estado(self).find(:all).each { |t| topicos_relevancias_sum += t.relevancia }

    users_count = 0
    users_count = User.do_estado(self).count(:all)
    
    users_relevancias_sum = 0
    User.do_estado(self).find(:all).each { |u| users_relevancias_sum += u.relevancia }
    
    self.relevancia = (eval(Settings.localizacao_formula_relevancia)).to_i
    self.save(false)
  end
  
end