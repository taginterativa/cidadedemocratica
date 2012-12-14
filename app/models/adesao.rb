class Adesao < ActiveRecord::Base
  belongs_to :user
  belongs_to :topico

  #========================================================#
  #                 MODEL Validations                      #
  #========================================================#
  validates_uniqueness_of :topico_id, :scope => :user_id


  #=============================================================#
  #                    NAMED Scopes                             #
  #=============================================================#
  scope :por_user_ativo, 
              :include => [:user], 
              :conditions => ["users.state = 'active'"]
  scope :dos_topicos, lambda { |topico_ids|
    if topico_ids.nil?
      { }
    else 
      { 
        :conditions => [ "topico_id IN (?)", topico_ids ]
      }
    end
  }
  scope :depois_de, lambda { |data|
    if data.nil?
      { :order => "created_at DESC" }
    else
      { :conditions => [ "created_at >= ?", data ],
        :order => "created_at DESC" }
    end
  }
  scope :no_intervalo, lambda { |data_de, data_ate|
    if data_de and data_ate and data_de.kind_of?(Date) and data_ate.kind_of?(Date)
      {
        :conditions => "DATE(adesoes.created_at) >= '#{data_de.strftime('%Y-%m-%d')}' AND DATE(adesoes.created_at) <= '#{data_ate.strftime('%Y-%m-%d')}'"
      }
    else
      {}
    end
  }
  scope :agrupados_por_dia_de_criacao, 
  {
    :select => "count(*) AS total, DATE(adesoes.created_at) AS dia",
    :group  => "DAY(adesoes.created_at), MONTH(adesoes.created_at), YEAR(adesoes.created_at)"
  }
  
  # Dada uma cidade (e outros params), retornar
  # contagem de comentarios
  def self.total(options = {})
    condicoes = []
    condicoes << "1=1"
    condicoes << "locais.pais_id = #{options[:pais].id}" if options[:pais]
    condicoes << "locais.estado_id = #{options[:estado].id}" if options[:estado]
    condicoes << "locais.cidade_id = #{options[:cidade].id}" if options[:cidade]
    condicoes << "locais.bairro_id = #{options[:bairro].id}" if options[:bairro]
    condicoes << "taggings.tag_id = #{options[:tag].id}" if options[:tag]
    condicoes << "topicos.created_at >= '#{options[:ultimos_dias].to_i.days.ago.to_s(:db)}'" if options[:ultimos_dias]
    condicoes << "users.type = '#{options[:user_type].singularize.camelize}'" if options[:user_type] and (options[:user_type]!="usuarios")
    condicoes << "topicos.type = '#{options[:topico_type].singularize.camelize}'" if options[:topico_type] and (options[:topico_type]!="topicos")

    sql_string = <<MYSTRING.gsub(/\s+/, " ").strip
    SELECT count(*) as total
    FROM adesoes
    WHERE adesoes.topico_id IN (
      SELECT DISTINCT topicos.id
      FROM locais JOIN topicos JOIN users JOIN taggings
      ON (locais.responsavel_type = 'Topico') AND
         (locais.responsavel_id = topicos.id) AND
         (taggings.taggable_type = 'Topico') AND
         (taggings.taggable_id = topicos.id) AND
         (topicos.user_id = users.id)
      WHERE #{condicoes.join(' AND ')}
    )
MYSTRING
    return Adesao.find_by_sql(sql_string)
  end

end
