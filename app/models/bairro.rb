class Bairro < ActiveRecord::Base
  belongs_to :cidade
  has_many :locais
  #set_default_order "name ASC"

  #============================================================#
  #                        VALIDATIONS                         #
  #============================================================#
  validates_presence_of :nome, :cidade_id

  #============================================================#
  #                         NAMED Scopes                       #
  #============================================================#
  scope :da_cidade, lambda { |cidade_id| 
    if cidade_id.blank?
      { }
    else
      { :conditions => [ "bairros.cidade_id = ?", cidade_id ], 
        :order => "bairros.nome ASC" }
    end
  }
  scope :com_nome, lambda { |nome|
    if nome.blank?
      {}
    else
      {
        :conditions => [ "bairros.nome LIKE ?", '%' + nome + '%' ]
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
    SELECT a.bairro_id, count(*) as total
    FROM (
      SELECT DISTINCT topicos.id, locais.bairro_id
      FROM locais JOIN topicos JOIN users JOIN taggings
      ON (locais.responsavel_type = 'Topico') AND
         (locais.responsavel_id = topicos.id) AND
         (taggings.taggable_type = 'Topico') AND
         (taggings.taggable_id = topicos.id) AND
         (topicos.user_id = users.id)
      WHERE #{condicoes.join(' AND ')}
    ) a GROUP BY a.bairro_id
MYSTRING
    { 
      :joins => "JOIN (#{sql_string}) z ON (bairros.id = z.bairro_id)",
      :select => "bairros.*, z.total",
      :conditions => "z.total > 0"
    }
  }

  scope :com_usuarios_do_contexto, lambda { |options|
    condicoes = []
    condicoes << "1=1"
    condicoes << "users.type = '#{options[:user_type].singularize.camelize}'" if options[:user_type] and (options[:user_type]!="usuarios")

    sql_string = <<MYSTRING.gsub(/\s+|\t+/, " ").strip
    SELECT a.bairro_id, count(*) as total
    FROM (
      SELECT DISTINCT users.id, locais.bairro_id
      FROM locais JOIN users
      ON (locais.responsavel_id = users.id) AND
         (locais.responsavel_type = 'User')
      WHERE #{condicoes.join(' AND ')}
    ) a GROUP BY a.bairro_id
MYSTRING
    { 
      :joins => "JOIN (#{sql_string}) z ON (bairros.id = z.bairro_id)",
      :select => "bairros.*, z.total",
      :conditions => "z.total > 0"
    }
  }

  
  #============================================================#
  #                          CLASS Methods                     #
  #============================================================#
  
  # Faz a busca pelos bairros mais "ativos"
  def self.mais_ativos(options={})
    options = {
      :limit => 50,
      :order => "total DESC",
      :cidade => nil # Caso venha uma cidade, usá-la na query
    }.merge!(options)
    
    if options[:cidade]
      join_str  = "JOIN locais ON (locais.bairro_id = bairros.id) AND " +
                  "               (locais.responsavel_type = 'Topico') AND " +
                  "               (locais.cidade_id = #{options[:cidade].id}) " +
                  "JOIN topicos ON (locais.responsavel_id = topicos.id) "
    else
      join_str =  "JOIN locais ON (locais.bairro_id = bairros.id) AND " +
                  "               (locais.responsavel_type = 'Topico') " +
                  "JOIN topicos ON (locais.responsavel_id = topicos.id) "
    end
    
    find(:all,
         :select => " bairros.*, COUNT(*) AS total",
         :conditions => [], 
         :joins => join_str,
         :group => "bairros.id",
         :limit => options[:limit], 
         :order => options[:order])
  end
  
  # Lista de bairros (de uma dada cidade),
  # com counts( = total!) de problemas/propostas
  def self.de_topicos(cidade_id, options = {})
    # Strings a parte...
    sql_string_topico_type = options[:topico_type].nil? ? "" : " AND topicos.type = '#{options[:topico_type].to_s.singularize.camelize}' "
    sql_string_user_type = options[:user_type].nil? ? "" : " AND users.type = '#{options[:user_type].to_s.singularize.camelize}' "
    sql_string_date = options[:ultimos_dias].nil? ? "" : " AND topicos.created_at >= '#{options[:ultimos_dias].to_i.days.ago.to_s(:db)}' "

    sql_string = <<MYSTRING.gsub(/\s+/, " ").strip
    SELECT b.id, b.nome, a.total FROM bairros b INNER JOIN (
      SELECT l.bairro_id, count(*) AS total FROM locais l
        WHERE l.cidade_id = #{cidade_id}
        AND l.responsavel_type = 'Topico'
        AND l.responsavel_id IN (
          SELECT topicos.id 
          FROM topicos JOIN users
          ON (topicos.user_id = users.id)
          WHERE topicos.id > 0
          #{sql_string_topico_type}
          #{sql_string_user_type}
          #{sql_string_date}
        )
        GROUP BY l.bairro_id
    ) a ON (b.id = a.bairro_id)
MYSTRING
    return Bairro.find_by_sql(sql_string)
  end
  
  # Lista de bairros (de uma dada cidade) 
  # cujos tópicos possuem a tag (ID!) forncecida,
  # com counts( = total!) de problemas/propostas
  def self.de_topicos_com_tag(tag, cidade_id, options = {})
    # Strings a parte...
    sql_string_topico_type = options[:topico_type].nil? ? "" : " AND topicos.type = '#{options[:topico_type].to_s.singularize.camelize}' "
    sql_string_user_type = options[:user_type].nil? ? "" : " AND users.type = '#{options[:user_type].to_s.singularize.camelize}' "
    sql_string_date = options[:ultimos_dias].nil? ? "" : " AND topicos.created_at >= '#{options[:ultimos_dias].to_i.days.ago.to_s(:db)}' "
    
    # String para consulta
    sql_string = <<MYSTRING.gsub(/\s+/, " ").strip
    SELECT b.id, b.nome, a.total 
    FROM bairros b INNER JOIN (
      SELECT l.bairro_id, count(*) AS total 
      FROM locais l 
      WHERE l.cidade_id = #{cidade_id} 
        AND l.responsavel_type = 'Topico'
        AND l.responsavel_id IN (
          SELECT topicos.id 
          FROM topicos JOIN users JOIN taggings topicos_taggings 
                     ON (topicos.user_id = users.id)
                        AND (topicos_taggings.taggable_id = topicos.id) 
                        AND (topicos_taggings.taggable_type = 'Topico')
                     JOIN tags topicos_tags 
                     ON (topicos_tags.id = topicos_taggings.tag_id)
        WHERE context = 'tags' 
          AND topicos_tags.id LIKE '#{tag}'
          #{sql_string_topico_type}
          #{sql_string_user_type}
          #{sql_string_date}
      )
      GROUP BY l.bairro_id
    ) a ON (b.id = a.bairro_id)
    ORDER BY a.total DESC
MYSTRING
    return Bairro.find_by_sql(sql_string)
  end
  
  #============================================================#
  #                       OBJECT Methods                       #
  #============================================================#
  
  # Atualizacoes dos contadores
  def atualiza_contadores
    topicos_count = 0
    topicos_count = Topico.do_bairro(self).count(:all)

    topicos_relevancias_sum = 0
    Topico.do_bairro(self).find(:all).each { |t| topicos_relevancias_sum += t.relevancia }

    users_count = 0
    users_count = User.do_bairro(self).count(:all)
    
    users_relevancias_sum = 0
    User.do_bairro(self).find(:all).each { |u| users_relevancias_sum += u.relevancia }
    
    self.relevancia = (eval(Settings.localizacao_formula_relevancia)).to_i
    self.save(false)
  end

end
