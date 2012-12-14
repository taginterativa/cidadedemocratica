class Topico < ActiveRecord::Base
  # 1 usuário é responsável pelo problema.
  belongs_to :user, :include => :imagens

  # Se topico tem filhos
  acts_as_tree

  # O tópico tem TAGS!
  acts_as_taggable_on :tags

  # O tópico pode/deve ser mapeável (cidade, bairro, ponto no mapa...)
  #has_one :local, :as => :responsavel, :dependent => :destroy
  has_many :locais, :as => :responsavel, :dependent => :destroy

  # O tópico pode ter N imagens
  has_many :imagens, :as => :responsavel, :dependent => :destroy

  # O tópico pode ter N usuários que lhe são solidários
  has_many :adesoes, :dependent => :destroy
  has_many :usuarios_que_aderem, :through => :adesoes, :source => :user, :order => "created_at ASC"

  # O tópico pode ter N usuários que lhe seguem
  has_many :seguidos, :dependent => :destroy
  has_many :usuarios_que_seguem, :through => :seguidos, :source => :user

  # O tópico tem N pode ter links associados
  has_many :links, :dependent => :destroy

  # O tópico tem N comentários!
  acts_as_commentable

  # A slug do tópico (topico_slug!)
  has_slug :source_column => :titulo,
           :sync_slug => true # e se mudar o título?

  attr_accessor :tags_com_virgula, :editando_locais

  #========================================================#
  #                 MODEL Validations                      #
  #========================================================#
  validates_presence_of :titulo, :descricao
  validate :must_have_tags, :if => Proc.new { |t| t.tags.empty? }
  validate :must_have_locais, :if => Proc.new { |t| t.editando_locais }
  validate :must_have_locais_of_the_same_level, :if => Proc.new { |t| t.editando_locais }
  validate :cant_have_identical_locais, :if => Proc.new { |t| t.editando_locais }
  validate :cant_exceed_locais_limit, :if => Proc.new { |t| t.editando_locais }

  # Validação de tags: o tópico deve ter ao menos uma tag 
  # (e não pode ter: só espaço em brancos, nem só ",")
  def must_have_tags
    if tags_com_virgula.nil? or tags_com_virgula.empty?
      errors.add_to_base("Precisa de ao menos uma tag")
    elsif tags_com_virgula.strip.empty?
      errors.add_to_base("Precisa de ao menos uma tag (não vazia!)")
    elsif tags_com_virgula.strip.gsub(/\,+/, ' ').strip.empty?
      errors.add_to_base("Tags, por favor...")
    elsif tags_com_virgula =~ /\"+|\'+|\t+/
      errors.add_to_base("Use palavras apenas com letras, números e espaços em branco")
    end
  end
  
  # Validação de locais: tem q ter ao menos um.
  def must_have_locais
    if (self.locais.size == 0)
      errors.add_to_base("É preciso especificar ao menos uma localização")
    end
  end
  
  # Validação de locais: todos devem ser do mesmo nível:
  # Não pode haver um nacional, outro estadual, um municipal etc.
  def must_have_locais_of_the_same_level
    if (self.locais.size > 0)
      tmp = []
      self.locais.each do |local|
        tmp << local.ambito
      end
      if (tmp.uniq.size != 1)
        errors.add_to_base("As localizações especificadas precisam ter todas a mesma abrangência")
      end
    end
  end
  
  # Validação de locais: nao pode haver 2 locais iguais
  def cant_have_identical_locais
    if (self.locais.size > 0)
      tem_iguais = false
      0.upto(self.locais.size-2) do |i|
        (i+1).upto(self.locais.size-1) do |j|
          tem_iguais = true if (self.locais[i]==self.locais[j])
        end
      end
      errors.add_to_base("Duas ou mais localizações especificadas são idênticas") if tem_iguais
    end
  end
  
  # Validação de locais: nao pode exceder o limite estabelecido pelo sistema.
  def cant_exceed_locais_limit
    limit = 10
    if (self.locais.size > limit)
      errors.add_to_base("Não é possível especificar mais de #{limit} locais")
    end
  end

  #=============================================================#
  #                    NAMED Scopes                             #
  #=============================================================#
  scope :de_user_ativo, 
              :include => [:user], 
              :conditions => ["users.state = 'active'"]
  scope :do_tipo, lambda { |topico_type|
    if topico_type.nil? or topico_type.to_s.downcase == "topicos"
      {}
    else
      {
        :conditions => { :type => topico_type.to_s.singularize.camelize },
        :include => [ :locais ]
      }
    end
  }
  scope :do_proponente, lambda { |user_type| 
    if user_type.nil? 
      {} 
    else 
      { :conditions => [ "users.type = ?", user_type.to_s.singularize.camelize ], 
        :include => [ :user ] 
      } 
    end
  }
  scope :do_pais, lambda { |pais|
    if pais.nil? or not pais.kind_of?(Pais)
      {}
    else
      {
        :select => "DISTINCT topicos.*",
        :conditions => [ "locais.pais_id = ?", pais.id ],
        :include => [ :locais ]
      }
    end
  }
  scope :join_do_pais,
              :joins => "INNER JOIN locais ON (locais.responsavel_id = topicos.id AND locais.responsavel_type = 'Topico')"
              
  scope :do_estado, lambda { |estado|
    if estado.nil? or not estado.kind_of?(Estado)
      {}
    else
      {
        :select => "DISTINCT topicos.*",
        :conditions => [ "locais.estado_id = ?", estado.id ],
        :include => [ :locais ]
      }
    end
  }
  scope :join_do_estado, lambda { |estado|
    if estado and estado.kind_of?(Estado)
      {
        :joins => "INNER JOIN locais ON (locais.responsavel_id = topicos.id AND locais.responsavel_type = 'Topico' AND locais.estado_id = #{estado.id})"
      }
    end
  }
  scope :da_cidade, lambda { |cidade|
    if cidade.nil? or not cidade.kind_of?(Cidade)
      {}
    else
      {
        :select => "DISTINCT topicos.*",
        :conditions => [ "locais.cidade_id = ?", cidade.id ],
        :include => [ :locais ]
      }
    end
  }
  scope :join_da_cidade, lambda { |cidade|
    if cidade.nil? or not cidade.kind_of?(Cidade)
      {}
    else
      {
        :joins => "INNER JOIN locais ON (locais.responsavel_id = topicos.id AND locais.responsavel_type = 'Topico' AND locais.cidade_id = #{cidade.id})"
      }
    end
  }
  scope :do_bairro, lambda { |bairro|
    if bairro.nil? or not bairro.kind_of?(Bairro)
      {}
    else
      {
        :select => "DISTINCT topicos.*",
        :conditions => [ "locais.bairro_id = ?", bairro.id ],
        :include => [ :locais ]
      }
    end
  }
  scope :join_do_bairro, lambda { |bairro|
    if bairro
      {
        :joins => "INNER JOIN locais ON (locais.responsavel_id = topicos.id AND locais.responsavel_type = 'Topico' AND locais.bairro_id = #{bairro.id})"
      }
    end
  }
  scope :apos_o_dia, lambda { |inicio| 
    if inicio.nil?
      {}
    else 
      { :conditions => [ "topicos.created_at >= ?", inicio ] } 
    end
  }
  scope :nos_ultimos_dias, lambda { |dias| 
    if dias.nil?
      {}
    else 
      { :conditions => [ "topicos.created_at >= ?", dias.to_i.days.ago ] } 
    end
  }
  scope :com_tags, lambda { |tag_ids|
    if (tag_ids.nil? or tag_ids.empty?)
      {}
    else
      {
        :conditions => [ "taggings.tag_id IN (?)", tag_ids ],
        :include => [ :taggings ]
      }
    end
  }
  scope :com_tag, lambda { |tag|
    if tag.nil? or not tag.kind_of?(Tag)
      {}
    else
      { :conditions => [ "tags.id = ?", tag.id ],
        :include => [ :tags ]
      }
    end
  }
  scope :join_da_tag, lambda { |tag|
    if tag.nil? or not tag.kind_of?(Tag)
      {}
    else
      {
        :joins => "JOIN taggings t1 ON (t1.taggable_id = topicos.id AND t1.taggable_type = 'Topico' AND t1.tag_id = #{tag.id})"
      }
    end
  }
  scope :join_das_tags, lambda { |tags_ids|
    if tags_ids.nil?
      {}
    else
      {
        :joins => "JOIN taggings t1 ON (t1.taggable_id = topicos.id AND t1.taggable_type = 'Topico' AND t1.tag_id IN (#{tags_ids.join(',')}))"
      }
    end
  }
  scope :que_tem_as_tags, lambda { |tags_ids|
    unless tags_ids.nil?
      t_ids = Tagging.find(:all, :select => "DISTINCT taggable_id", :conditions => "taggable_type = 'Topico' AND tag_id IN (#{tags_ids.join(',')})").map(&:taggable_id)
      unless t_ids.empty?
        {
          :conditions => "topicos.id IN (#{t_ids.join(',')})"
        }
      end
    end
  }
  scope :do_pai, lambda { |parent_id| 
    if parent_id.nil? 
      {}
    else 
      { :conditions => { :parent_id => parent_id } }
    end
  }
  scope :exceto, lambda { |id| 
    if id.nil?
      {}
    else 
      { :conditions => ["topicos.id <> ?", id] }
    end
  }
  scope :nos_locais, lambda { |locais|
    if locais.nil?
      {}
    else
      tmp = []
      locais.each do |a|
        if a.cidade_id 
          aux  = "(locais.cidade_id = #{a.cidade_id} "
          aux += "AND locais.bairro_id = #{a.bairro_id}" if a.bairro_id
          aux += ")"
          tmp << aux
        end
      end
      {
        :conditions => [ tmp.join(' OR ') ],
        :include => [ :locais ]
        #:joins => "INNER JOIN locais ON (locais.responsavel_id = topicos.id AND locais.responsavel_type = 'Topico')"
      }
    end
  }
  scope :no_intervalo, lambda { |data_de, data_ate|
    if data_de and data_ate and data_de.kind_of?(Date) and data_ate.kind_of?(Date)
      {
        :conditions => "DATE(topicos.created_at) >= '#{data_de.strftime('%Y-%m-%d')}' AND DATE(topicos.created_at) <= '#{data_ate.strftime('%Y-%m-%d')}'"
      }
    else
      {}
    end
  }
  scope :agrupados_por_dia_de_criacao, 
  {
    :select => "count(*) AS total, DATE(topicos.created_at) AS dia",
    :group  => "DATE(topicos.created_at)" #"DAY(topicos.created_at), MONTH(topicos.created_at), YEAR(topicos.created_at)"
  }
  scope :agrupados_por_tipo, 
  {
    :select => "count(*) AS total, topicos.type",
    :group  => "topicos.type"
  }
  scope :agrupados_por_tags, 
  {
    :select => "count(*) AS total, tags.name, tags.id",
    :joins => "INNER JOIN taggings ON (taggings.taggable_id = topicos.id AND taggings.taggable_type = 'Topico') INNER JOIN tags ON (taggings.tag_id = tags.id)",
    :group  => "taggings.tag_id",
  }
  scope :agrupados_pelo_pais,
  {
    :select => "count(*) AS total, locais.pais_id",
    :joins => "INNER JOIN locais ON (locais.responsavel_id = topicos.id AND locais.responsavel_type = 'Topico' AND locais.pais_id IS NOT NULL)",
    :conditions => "locais.estado_id IS NULL AND locais.cidade_id IS NULL AND locais.bairro_id IS NULL",
    :group  => "locais.pais_id"
  }
  scope :agrupados_por_estados,
  {
    :select => "count(*) AS total, estados.abrev, estados.id",
    :joins => "INNER JOIN locais ON (locais.responsavel_id = topicos.id AND locais.responsavel_type = 'Topico') INNER JOIN estados ON (locais.estado_id = estados.id)",
    :group  => "locais.estado_id"
  }
  scope :agrupados_por_cidades, 
  {
    :select => "count(*) AS total, cidades.nome, cidades.id",
    :joins => "INNER JOIN locais ON (locais.responsavel_id = topicos.id AND locais.responsavel_type = 'Topico') INNER JOIN cidades ON (locais.cidade_id = cidades.id)",
    :conditions => "locais.cidade_id IS NOT NULL",
    :group  => "locais.cidade_id"
  }
  scope :agrupados_por_cidades_do_estado, lambda { |estado|
    if estado and estado.kind_of?(Estado)
      {
        :select => "count(*) AS total, cidades.nome, cidades.id",
        :joins => "INNER JOIN locais ON (locais.responsavel_id = topicos.id AND locais.responsavel_type = 'Topico' AND locais.estado_id = #{estado.id}) INNER JOIN cidades ON (locais.cidade_id = cidades.id)",
        :conditions => "locais.cidade_id IS NOT NULL",
        :group  => "locais.cidade_id"
      }
    end
  }
  scope :agrupados_por_bairros, 
  {
    :select => "count(*) AS total, bairros.nome, bairros.id",
    :joins => "INNER JOIN locais ON (locais.responsavel_id = topicos.id AND locais.responsavel_type = 'Topico') INNER JOIN bairros ON (locais.bairro_id = bairros.id)",
    :conditions => "locais.bairro_id IS NOT NULL",
    :group  => "locais.bairro_id"
  }  
  scope :agrupados_por_bairros_da_cidade, lambda { |cidade|
    if cidade and cidade.kind_of?(Cidade)
    {
      :select => "count(*) AS total, bairros.nome, bairros.id",
      :joins => "INNER JOIN locais ON (locais.responsavel_id = topicos.id AND locais.responsavel_type = 'Topico' AND locais.cidade_id = #{cidade.id}) INNER JOIN bairros ON (locais.bairro_id = bairros.id) ",
      :conditions => "locais.bairro_id IS NOT NULL",
      :group  => "locais.bairro_id"
    }
    else
      {}
    end
  }



  #==========================================================#
  #                  OBJECT Methods                          #
  #==========================================================#  
  # Se o topico nao teve nenhuma atividade
  # (= comentario, adesao) ainda, pode ser editado.
  def pode_editar?
    return (self.comment_threads and
            self.comment_threads.empty? and
            self.adesoes and
            self.adesoes.empty?)
  end

  def artigo_definido
    return "a" if self.type.to_s.downcase == "proposta"
    return "o" #o problema, o tópico...
  end

  def nome_do_tipo(options = {})
    str = ""
    my_options = {
      :artigo => false, # pode ser :definido, :indefinido
      :possessivo => false, #se true, "seu", "sua"
      :demonstrativo => false, #se true, "esse", "essa"
      :plural => false
    }.merge!(options)
    if my_options[:demonstrativo]
      str += "esse" if self.type.to_s == "Problema"
      str += "essa" if self.type.to_s == "Proposta"
    end
    if my_options[:artigo] == :indefinido
      str += "um" if self.type.to_s == "Problema"
      str += "uma" if self.type.to_s == "Proposta"
    elsif my_options[:artigo] == :definido
      str += "o" if self.type.to_s == "Problema"
      str += "a" if self.type.to_s == "Proposta"
    end
    if my_options[:possessivo]
      str += "seu" if self.type.to_s == "Problema"
      str += "sua" if self.type.to_s == "Proposta"
    end
    return "#{str} #{self.type.to_s.downcase}"
  end

  # Retorna o objeto da última atividade
  # TODO: melhorar
  def ultima_atividade
    if not self.comment_threads.empty?
      return self.comment_threads.last
    elsif not self.adesoes.empty?
      return self.adesoes.last
    else
      return nil
    end
  end

  # Retorna um vetor com
  # topicos relacionados.
  def relacionados
    relacionados = []
    # Se é filho de alguem, relacionar o pai
    relacionados << Topico.find(self.parent_id) if self.parent_id
    # Se tem filhos, relacionar os filhos
    Topico.do_pai(self.id).each{|t| relacionados << t }
    # Relacionar os demais topicos da cidade (e do bairro) com as mesmas tags
    Topico.da_cidade(self.locais.first.cidade).do_bairro(self.locais.first.bairro).exceto(self.id).find_tagged_with(self.tags).each{|t| relacionados << t }
    if (relacionados.size == 0)
      # Relacionar os demais topicos da cidade (apenas...) com as mesmas tags
      Topico.da_cidade(self.locais.first.cidade).exceto(self.id).find_tagged_with(self.tags).each{|t| relacionados << t }
    end
    return relacionados
  end

  # Atualizacoes dos contadores
  def atualiza_contadores
    self.comments_count = Comment.count(:conditions => [ "commentable_id = ? AND commentable_type = ?", self.id, "Topico" ])
    self.adesoes_count  = self.usuarios_que_aderem.size
    self.seguidores_count  = self.usuarios_que_seguem.size
    self.relevancia     = (100 * (Settings.topicos_relevancia_peso_comentarios.to_f * comments_count + Settings.topicos_relevancia_peso_apoios.to_f * adesoes_count + Settings.topicos_relevancia_peso_seguidores.to_f * seguidores_count)).to_i

    # FIXME: Salva sem validar. Ao testarmos, o tópico retornava um erro de validação, dizendo que precisava de tag.
    self.save(false)
  end
  
  def n_atividades
    return (self.comments_count + self.adesoes_count)
  end

  def notificar_novo_comentario(comentario)
    # Enviar e-mail para o criador do tópico.
    TopicoMailer.deliver_novo_comentario(self.user, self, comentario) if self.user.active?

    # Enviar e-mail para os usuários que seguem esta proposta.
    usuarios_que_seguem = self.usuarios_que_seguem.find(:all)
    if usuarios_que_seguem.size > 0
      usuarios_que_seguem.each do |u|
        TopicoMailer.deliver_novo_comentario(u, self, comentario) if u.active?
        # TopicoMailer.deliver_envia_seguidor(topico, verbo, objeto, u) if u.active?
      end
    end
  end

  # Retorna true se o usuário apoia o tópico;
  # caso contrário, retorna false.
  def is_apoiado(user)
    user ? user.adesoes.find_by_topico_id(self.id) : false
  end

  # Retorna true se o usuário segue o tópico;
  # caso contrário, retorna false.
  def is_seguido(user)
    user ? user.seguidos.find_by_topico_id(self.id) : false
  end

  #==========================================================#
  #                   CLASS Methods                          #
  #==========================================================#

  # Dado um usuario, retornar todos topicos (distintos)
  # em que o usuario atuou (criou, comentou, aderiu etc.)
  def self.trabalhados_pelo_usuario(user)
    topicos = user.topico_ids
    adesoes = user.adesoes.collect{|a| a.topico_id}
    comentarios = Comment.find_comments_by_user(user).collect{|c| c.commentable_id}
    t = topicos + adesoes + comentarios
    return Topico.find(t.uniq)
  end

  # Dado um topico e um objeto de divulgacao (vide modelo)
  # enviar emails para cada destinatario avisando do topico.
  def self.divulgar(topico, divulgacao)
    i = 0
    for para_email in divulgacao.emails do
      TopicoMailer.deliver_divulgacao(topico,
                                      divulgacao.de_nome,
                                      divulgacao.de_email,
                                      para_email,
                                      divulgacao.dica)
      i += 1
    end
    return i
  end

  # Dada uma cidade, retornar contagem de
  # propostas e problemas. => BETTER SELECT
  def self.total_por_tipo(options = {})
    condicoes = []
    condicoes << "1=1"
    condicoes << "locais.pais_id = #{options[:pais].id}" if options[:pais]
    condicoes << "locais.estado_id = #{options[:estado].id}" if options[:estado]
    condicoes << "locais.cidade_id = #{options[:cidade].id}" if options[:cidade]
    condicoes << "locais.bairro_id = #{options[:bairro].id}" if options[:bairro]
    condicoes << "taggings.tag_id = #{options[:tag].id}" if options[:tag]
    condicoes << "users.type = '#{options[:user_type].singularize.camelize}'" if options[:user_type] and (options[:user_type]!="usuarios")
    condicoes << "topicos.created_at >= '#{options[:ultimos_dias].to_i.days.ago.to_s(:db)}'" if options[:ultimos_dias]

    sql_string = <<MYSTRING.gsub(/\s+/, " ").strip
    SELECT a.type, count(*) as total
    FROM (
      SELECT DISTINCT topicos.id, topicos.type
      FROM locais JOIN topicos JOIN users JOIN taggings
      ON (locais.responsavel_type = 'Topico') AND
         (locais.responsavel_id = topicos.id) AND
         (taggings.taggable_type = 'Topico') AND
         (taggings.taggable_id = topicos.id) AND
         (topicos.user_id = users.id)
      WHERE #{condicoes.join(" AND ")}
    ) a GROUP BY a.type
MYSTRING
    return Topico.find_by_sql(sql_string)
  end

  # Dada uma cidade (e outros params), retornar
  # contagem de topicos por tipo de USUARIO. => BETTER SELECT
  def self.total_criados_por(options = {})
    condicoes = []
    condicoes << "1=1"
    condicoes << "locais.pais_id = #{options[:pais].id}" if options[:pais]
    condicoes << "locais.estado_id = #{options[:estado].id}" if options[:estado]
    condicoes << "locais.cidade_id = #{options[:cidade].id}" if options[:cidade]
    condicoes << "locais.bairro_id = #{options[:bairro].id}" if options[:bairro]
    condicoes << "taggings.tag_id = #{options[:tag].id}" if options[:tag]
    condicoes << "topicos.created_at >= '#{options[:ultimos_dias].to_i.days.ago.to_s(:db)}'" if options[:ultimos_dias]
    condicoes << "topicos.type = '#{options[:topico_type].singularize.camelize}'" if options[:topico_type] and (options[:topico_type]!="topicos")

    sql_string = <<MYSTRING.gsub(/\s+/, " ").strip
    SELECT a.type, count(*) as total
    FROM (
      SELECT DISTINCT topicos.id, users.type
      FROM locais JOIN topicos JOIN users JOIN taggings
      ON (locais.responsavel_type = 'Topico') AND
         (locais.responsavel_id = topicos.id) AND
         (taggings.taggable_type = 'Topico') AND
         (taggings.taggable_id = topicos.id) AND
         (topicos.user_id = users.id)
      WHERE #{condicoes.join(' AND ')}
    ) a GROUP BY a.type
MYSTRING
    return Topico.find_by_sql(sql_string)
  end
  
  # Dada uma cidade (e outros params), retornar
  # contagem de comentarios
  def self.total_comentarios(options = {})
    condicoes = []
    condicoes << "commentable_type = 'Topico'"
    condicoes << "commentable_id = topicos.id"
    condicoes << "locais.pais_id = #{options[:pais].id}" if options[:pais]
    condicoes << "locais.estado_id = #{options[:estado].id}" if options[:estado]
    condicoes << "locais.cidade_id = #{options[:cidade].id}" if options[:cidade]
    condicoes << "locais.bairro_id = #{options[:bairro].id}" if options[:bairro]
    condicoes << "taggings.tag_id = #{options[:tag].id}" if options[:tag]
    condicoes << "topicos.created_at >= '#{options[:ultimos_dias].to_i.days.ago.to_s(:db)}'" if options[:ultimos_dias]
    condicoes << "users.type = '#{options[:user_type].singularize.camelize}'" if options[:user_type] and (options[:user_type]!="usuarios")
    condicoes << "topicos.type = '#{options[:topico_type].singularize.camelize}'" if options[:topico_type] and (options[:topico_type]!="topicos")

    sql_string = <<MYSTRING.gsub(/\s+/, " ").strip
    SELECT count(comments.id) as total
    FROM comments
    WHERE commentable_id IN (
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
    return Topico.find_by_sql(sql_string)
  end

  alias :usuario_segue? :is_seguido
end
