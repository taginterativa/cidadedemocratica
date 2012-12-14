class Local < ActiveRecord::Base
  belongs_to :responsavel, :polymorphic => true#, :dependent => :destroy # bug no cadastro de pessoas
  belongs_to :estado
  belongs_to :cidade
  belongs_to :bairro
  
  #default_scope :include => [ :estado, :cidade, :bairro ]

  #================================================================#
  #                  MODEL Validations                             #
  #================================================================#
  validates_presence_of :pais_id
  validates_presence_of :estado_id,             :if => :tem_cidade?
  validates_presence_of :estado_id, :cidade_id, :if => :tem_bairro?

  validate :cidade_pertence_ao_estado,          :if => :tem_cidade?
  validate :bairro_pertence_a_cidade,           :if => :tem_bairro?

  #===============================================================#
  #                    NAMED Scopes                               #
  #===============================================================#
  scope :de_usuario, :conditions => [ "responsavel_type = 'User'" ]
  scope :de_topicos, :conditions => [ "responsavel_type = 'Topico'" ]
  scope :join_das_tags, lambda { |tags_ids|
    if tags_ids
      {
        :joins => "INNER JOIN taggings t1 ON (t1.taggable_id = locais.responsavel_id AND t1.taggable_type = 'Topico' AND locais.responsavel_type = 'Topico' AND t1.tag_id IN (#{tags_ids.join(',')}))"
      }
    end
  }
  scope :que_tem_as_tags, lambda { |tags_ids|
    unless tags_ids.nil?
      t_ids = Tagging.find(:all, :select => "DISTINCT taggable_id", :conditions => "taggable_type = 'Topico' AND tag_id IN (#{tags_ids.join(',')})").map(&:taggable_id)
      unless t_ids.empty?
        {
          :conditions => "locais.responsavel_id IN (#{t_ids.join(',')}) and locais.responsavel_type = 'Topico'"
        }
      end
    end
  }
  scope :no_intervalo, lambda { |data_de, data_ate|
    if data_de and data_ate and data_de.kind_of?(Date) and data_ate.kind_of?(Date)
      {
        :conditions => "DATE(locais.created_at) >= '#{data_de.strftime('%Y-%m-%d')}' AND DATE(locais.created_at) <= '#{data_ate.strftime('%Y-%m-%d')}'"
      }
    end
  }
  scope :agrupados_por_bairros_da_cidade, lambda { |cidade|
    if cidade and cidade.kind_of?(Cidade)
    {
      :select => "count(*) AS total, locais.bairro_id",
      :conditions => "locais.cidade_id = #{cidade.id}",
      :group  => "locais.bairro_id"
    }
    end
  }
  scope :agrupados_por_cidades_do_estado, lambda { |estado|
    if estado and estado.kind_of?(Estado)
    {
      :select => "count(*) AS total, locais.cidade_id",
      :conditions => "locais.estado_id = #{estado.id}",
      :group  => "locais.cidade_id"
    }
    end
  }
  scope :agrupados_por_estados_do_pais,
  {
    :select => "count(*) AS total, locais.estado_id",
    :group  => "locais.estado_id"
  }


  #================================================================#
  #                  CLASS Methods                                 #
  #================================================================#

  # Dado um usuario, retorna locais em que ele atua/atuou
  # (i.e. criou topico, comentou, aderiu)
  def self.em_que_usuario_atuou(user)
    topico_ids = Topico.trabalhados_pelo_usuario(user).map(&:id)
    scoped(#:select => "DISTINCT locais.id", 
           :conditions => [ "responsavel_type = 'Topico' AND responsavel_id IN (?)", topico_ids ])
  end
  
#  def self.conta_propostas_no_ambito_e_abaixo(local, de, ate)
#    self.conta_topico_no_ambito_e_abaixo('Proposta', local, de, ate)
#  end
#  
#  def self.conta_problemas_no_ambito_e_abaixo(local, de, ate)
#    self.conta_topico_no_ambito_e_abaixo('Problema', local, de, ate)
#  end
#  
#  def self.conta_topico_no_ambito_e_abaixo(type, local, de=nil, ate=nil)
#    condicoes = []
#    condicoes << "DATE(topicos.created_at) >= '#{de}'" if (de and de.kind_of?(Date))
#    condicoes << "DATE(topicos.created_at) <= '#{ate}'" if (ate and ate.kind_of?(Date))
#    condicoes << "topicos.type = '#{type}'" if (type != 'Topico')
#
#    abaixo = self.qual_abaixo(local)
#    sql_string = <<MYSTRING.gsub(/\s+/, " ").strip
#    SELECT #{abaixo}, COUNT(*) AS total
#    FROM locais INNER JOIN topicos 
#      ON (locais.responsavel_id = topicos.id AND 
#          locais.responsavel_type = 'Topico' AND 
#          locais.#{local.class.to_s.downcase}_id = #{local.id}) 
#      WHERE #{condicoes.join(' AND ')} 
#      GROUP BY #{abaixo}
#MYSTRING
#    return Local.find_by_sql(sql_string)
#  end
#  
#  def self.conta_adesoes_no_ambito_e_abaixo(local, de=nil, ate=nil)
#    condicoes = []
#    condicoes << "DATE(topicos.created_at) >= '#{de}'" if (de and de.kind_of?(Date))
#    condicoes << "DATE(topicos.created_at) <= '#{ate}'" if (ate and ate.kind_of?(Date))
#
#    abaixo = self.qual_abaixo(local)
#    sql_string = <<MYSTRING.gsub(/\s+/, " ").strip
#    SELECT #{abaixo}, COUNT(*) AS total
#    FROM locais JOIN topicos
#      ON (locais.responsavel_id = topicos.id AND 
#          locais.responsavel_type = 'Topico' AND
#          locais.#{local.class.to_s.downcase}_id = #{local.id})
#      JOIN adesoes
#      ON (locais.responsavel_id = adesoes.topico_id AND 
#          topicos.id = adesoes.topico_id)
#      WHERE #{condicoes.join(' AND ')} 
#      GROUP BY #{abaixo}
#MYSTRING
#    return Local.find_by_sql(sql_string)
#  end
#  
#  def self.conta_comentarios_no_ambito_e_abaixo(local, de=nil, ate=nil)
#    condicoes = []
#    condicoes << "DATE(topicos.created_at) >= '#{de}'" if (de and de.kind_of?(Date))
#    condicoes << "DATE(topicos.created_at) <= '#{ate}'" if (ate and ate.kind_of?(Date))
#
#    abaixo = self.qual_abaixo(local)
#    sql_string = <<MYSTRING.gsub(/\s+/, " ").strip
#    SELECT #{abaixo}, COUNT(*) AS total
#    FROM locais JOIN topicos
#      ON (locais.responsavel_id = topicos.id AND 
#          locais.responsavel_type = 'Topico' AND
#          locais.#{local.class.to_s.downcase}_id = #{local.id})
#      JOIN comments
#      ON (locais.responsavel_id = comments.commentable_id AND
#          topicos.id = comments.commentable_id AND
#          comments.commentable_type = 'Topico')
#      WHERE #{condicoes.join(' AND ')} 
#      GROUP BY #{abaixo}
#MYSTRING
#    return Local.find_by_sql(sql_string)
#  end
#  
#  def self.qual_abaixo(local)
#    case local.class.to_s.downcase
#      when "pais"
#        return "estado_id"
#      when "estado"
#        return "cidade_id"
#      when "cidade", "bairro"
#        return "bairro_id"
#    end
#  end

  #================================================================#
  #                  MODEL Methods                                 #
  #================================================================#

  # Define um pais padrao, 
  # nem sempre enviado pelo form.
  def pais_id
    read_attribute(:pais_id) or 1 # Default value for "Brasil"
  end

  def ==(object)
    return (object.instance_of?(Local) and
            self.pais_id == object.pais_id and
            self.estado_id == object.estado_id and
            self.cidade_id == object.cidade_id and
            self.bairro_id == object.bairro_id and
            self.responsavel_id == object.responsavel_id and
            self.responsavel_type == object.responsavel_type and
            self.cep == object.cep and
            self.lat == object.lat and
            self.lng == object.lng)
  end

  # Retorna uma string com o âmbito da localizacao:
  # - nacional (apenas pais_id setado)
  # - estadual (pais_id e estado_id setados)
  # - municipal (pais_id, estado_id e cidade_id setados)
  # - local (pais_id, estado_id, cidade_id e bairro_id setados)
  def ambito
    if self.pais_id and self.estado_id and self.cidade_id and self.bairro_id
      return "local"
    elsif self.pais_id and self.estado_id and self.cidade_id
      return "municipal"
    elsif self.pais_id and self.estado_id
      return "estadual"
    elsif self.pais_id
      return "nacional"
    end
  end
  
  def tem_pais?
    !self.pais_id.blank?
  end
  
  def tem_estado?
    !self.estado_id.blank?
  end
  
  def tem_cidade?
    !self.cidade_id.blank?
  end
  
  def tem_bairro?
    !self.bairro_id.blank?
  end
  
  def descricao
    case self.ambito
      when "local"
        tmp = ""
        tmp += self.bairro.nome 
        tmp += "de #{self.cidade.nome}" if self.tem_cidade?
        tmp += "-#{self.estado.abrev}" if self.tem_estado?
      when "municipal"
        tmp  = ""
        tmp += self.cidade.nome 
        tmp += "-#{self.estado.abrev}" if self.tem_estado?
      when "estadual"
        tmp = self.estado.abrev
      when "nacional"
        tmp = "Todo o país"
    end
    return tmp
  end
  
  # Retorna TRUE para obj local ok; otherwise, FALSE.
  # Se o parametro vier TRUE, faz a correcao no objeto.
  def ok?(corrigir=false)
    if tem_bairro?
      if tem_cidade?
        if tem_estado?
          if tem_pais?
            return true
          else
            puts "ERRO: TEM bairro, cidade e estado; FALTA pais_id ==> Resp_type: #{self.responsavel_type}; Resp_id: #{self.responsavel_id}"
            self.update_attributes(:pais_id => 1) if corrigir
            return false
          end
        else
          puts "ERRO: TEM bairro, cidade; FALTA estado_id ==> Resp_type: #{self.responsavel_type}; Resp_id: #{self.responsavel_id}"
          self.update_attributes(:cidade_id => self.bairro.cidade_id, :estado_id => self.bairro.cidade.estado_id, :pais_id => 1) if corrigir
          return false          
        end
      else
        puts "ERRO: TEM bairro; FALTA cidade_id ==> Resp_type: #{self.responsavel_type}; Resp_id: #{self.responsavel_id}"
        self.update_attributes(:cidade_id => self.bairro.cidade_id, :estado_id => self.bairro.cidade.estado_id, :pais_id => 1) if corrigir
        return false
      end
    elsif tem_cidade?
        if tem_estado?
          if tem_pais?
            return true
          else
            puts "ERRO: TEM cidade e estado; FALTA pais_id ==> Resp_type: #{self.responsavel_type}; Resp_id: #{self.responsavel_id}"
            self.update_attributes(:pais_id => 1) if corrigir
            return false
          end
        else
          puts "ERRO: TEM cidade; FALTA estado_id ==> Resp_type: #{self.responsavel_type}; Resp_id: #{self.responsavel_id}"
          self.update_attributes(:estado_id => self.cidade.estado_id, :pais_id => 1) if corrigir
          return false
        end
    elsif tem_estado?
      if tem_pais?
        return true
      else
        puts "ERRO: TEM estado; FALTA pais_id ==> Resp_type: #{self.responsavel_type}; Resp_id: #{self.responsavel_id}"
        self.update_attributes(:pais_id => 1) if corrigir
        return false        
      end
    elsif tem_pais?
      return true
    else
      puts "ERRO: VAZIO == Falta pais_id (e todo o resto...) ==> Resp_type: #{self.responsavel_type}; Resp_id: #{self.responsavel_id}"
      self.update_attributes(:pais_id => 1) if corrigir
      return false
    end
  end
  
  private
  
  def cidade_pertence_ao_estado
    if self.cidade and (self.cidade.estado_id != self.estado_id)
      self.errors.add(:cidade_id, :invalid, :default => "não pertence ao estado informado", :value => self.cidade_id) 
    end
  end
  
  def bairro_pertence_a_cidade
    if self.bairro and (self.bairro.cidade_id != self.cidade_id)
      self.errors.add(:bairro_id, :invalid, :default => "não pertence à cidade informada", :value => self.bairro_id) 
    end
  end
  
end
