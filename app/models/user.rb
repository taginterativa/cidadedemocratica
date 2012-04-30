require "digest/sha1"

class User < ActiveRecord::Base
  include Authentication
  include Authentication::ByPassword
  include Authentication::ByCookieToken
  include Authorization::StatefulRoles

  # Fix para warning "object#type is deprecated" ao chamar o atributo type
  def type
    read_attribute(:type)
  end

  # Fix para warning "object#type is deprecated" ao chamar o atributo type
  def type=(type)
    write_attribute(:type, type)
  end

  # Tanto pessoas físicas quanto jurídicas são usuários, e portanto têm login
  # e senha para criar propostas e editar seus perfis. Algumas pessoas físicas
  # - cidadãos, gestores pub. - podem pertencer a uma pessoa jurídica - empresa,
  # ONG, poder público -, e isso se dá na forma de uma árvore de usuários.
  #
  # Por exemplo:
  #
  # Empresa 1 -> Cidadão 3, Cidadão 5
  # ONG 2 -> Cidadão 6, Cidadão 7
  acts_as_tree

  # Contém nome, telefone, sexo, site, etc.
  has_one :dado, :class_name => "UserDado", :dependent => :delete
  delegate :nome, :to => :dado

  # Usuários possuem problemas e propostas
  has_many :topicos, :dependent => :destroy

  # Usuários aderem (se solidarizam) aos tópicos
  has_many :adesoes, :dependent => :destroy
  has_many :topicos_aderidos, :through => :adesoes, :source => :topico

  # Usuários seguem os tópicos
  has_many :seguidos, :dependent => :destroy

  # Usuários seguem tópicos
  # has_many :acompanhamentos

  # Guarda cada vez q o usuario fez login
  has_many :historico_de_logins, :dependent => :destroy, :class_name => 'HistoricoDeLogin'

  # Observatorios
  has_many :observatorios, :dependent => :destroy

  # Associa com a conta do ning (model NING)
  has_many :nings, :dependent => :destroy

  # O usuário pode incluir tags em tópicos.
  acts_as_tagger

  # O usuário tem uma imagem, seu avatar.
  has_many :imagens, :as => :responsavel, :dependent => :destroy
  def imagem
    imagem = self.imagens.first
    imagem ? imagem : nil
  end

  # O usuário tem uma localização: cidade, bairro, ponto no mapa...
  has_one :local, :as => :responsavel, :dependent => :destroy

  #========================================================#
  #                 MODEL Validations                      #
  #========================================================#
  validates_format_of :name,
                      :with => Authentication.name_regex,
                      :message => Authentication.bad_name_message,
                      :allow_nil => true
  validates_length_of :name,
                      :maximum => 100
  validates_presence_of :email
  validates_length_of :email,
                      :within => 6..100
  validates_uniqueness_of :email
  validates_format_of :email,
                      :with => Authentication.email_regex,
                      :message => "deve ter o formato de um e-mail"

  #=============================================================#
  #                    NAMED Scopes                             #
  #=============================================================#
  named_scope :com_nome, lambda { |nome|
    if nome.blank?
      {}
    else
      {
        :conditions => [ "user_dados.nome LIKE ?", '%' + nome + '%' ],
        :include => [ :dado ]
      }
    end
  }

  named_scope :com_email, lambda { |email|
    if email.blank?
      {}
    else
      { :conditions => [ "users.email LIKE ?", '%' + email + '%' ] }
    end
  }

  named_scope :com_status, lambda { |status|
    if status.blank?
      {}
    else
      { :conditions => [ "users.state = ?", status ] }
    end
  }

  named_scope :do_tipo, lambda { |user_type|
    if user_type and not user_type.blank? and user_type != "usuarios"
      {
        :conditions => { :type => user_type.to_s.singularize.camelize },
        :include => [ :local ]
      }
    else
      {}
    end
  }

  named_scope :por_idade, lambda { |idade|
    if idade.blank?
      {}
    else
      idade_min, idade_max = idade.split('-')
      condicao = "DATE(CONCAT( YEAR(NOW()), '-', MONTH(user_dados.aniversario), '-', DAY(user_dados.aniversario) )) < DATE( NOW() )"
      calc_idade_min = "IF ( #{condicao}, (YEAR(NOW()) - YEAR(user_dados.aniversario)) >= ?, (YEAR(NOW()) - YEAR(user_dados.aniversario) - 1) >= ?)"
      calc_idade_max = "IF ( #{condicao}, (YEAR(NOW()) - YEAR(user_dados.aniversario)) <= ?, (YEAR(NOW()) - YEAR(user_dados.aniversario) - 1) <= ?)"
      {
        :conditions => [ "(#{calc_idade_min} AND #{calc_idade_max})", idade_min, idade_min, idade_max, idade_max ],
        :include => [ :dado ]
      }
    end
  }

  named_scope :do_sexo, lambda { |sexo|
    if sexo.blank?
      {}
    else
      {
        :conditions => [ "user_dados.sexo = ?", sexo ],
        :include => [ :dado ]
      }
    end
  }

  named_scope :do_pais, lambda { |pais|
    if pais.nil? or not pais.kind_of?(Pais)
      {}
    else
      {
        #:select => "DISTINCT users.*",
        :conditions => [ "locais.pais_id = ?", pais.id ],
        :include => [ :local ]
      }
    end
  }

  named_scope :do_estado, lambda { |estado|
    if estado.blank?
      {}
    else
      if estado.kind_of?(Estado)
        estado_id = estado.id
      elsif estado.kind_of?(String)
        if (estado.size == "2") and (estado.to_i == 0) #eh uma abreviacao...
          estado_id = Estado.find_by_abrev(estado).id
        else
          estado_id = Estado.find(estado).id
        end
      else
        estado_id = estado
      end
      {
        :conditions => [ "locais.estado_id = ?", estado_id ],
        :include => [ :local ]
      }
    end
  }

  named_scope :da_cidade, lambda { |cidade|
    if cidade.kind_of?(Cidade)
      cidade_id = cidade.id
    elsif (cidade.to_i > 0)
      cidade_id = cidade.to_i
    else
      cidade_id = nil
    end
    if cidade_id and not cidade_id.blank?
      { 
        :conditions => [ "locais.cidade_id = ?", cidade_id ], 
        :include => [ :local ] 
      }
    else
      {}
    end
  }

  named_scope :do_bairro, lambda { |bairro|
    if bairro.nil? or not bairro.kind_of?(Bairro)
      {}
    else
      {
        #:select => "DISTINCT users.*",
        :conditions => [ "locais.bairro_id = ?", bairro.id ],
        :include => [ :local ]
      }
    end
  }

  named_scope :cadastrado_em, lambda { |dia| 
    if dia.nil?
      {}
    else 
      { :conditions => [ "DATE(users.created_at) = '#{dia.strftime('%Y-%m-%d')}' " ] } 
    end
  }

  named_scope :nao_admin,
              :conditions => [ "users.type <> ?", "Admin" ]
  named_scope :nao_confirmados,
              :conditions => { :state => "pending" }
  named_scope :ativos,
              :conditions => { :state => "active" }
  named_scope :aleatorios,
              :order => "rand()"
  named_scope :com_avatar,
              :conditions => [ "imagens.responsavel_id IS NOT NULL AND
                               (imagens.responsavel_type = 'User') AND
                               imagens.filename IS NOT NULL AND
                               (imagens.size > 0)" ],
              :include => [ :imagens ]
  named_scope :com_observatorio_ativo,
              :include => [ :observatorios ],
              :conditions => [ "observatorios.receber_email = ?", true ]

  #================================================================#
  #                     CLASS Methods                              #
  #================================================================#

  def self.que_criaram_comentaram_ou_apoiaram_topicos(topicos)
    topico_ids = topicos.map(&:id)
    scoped(:select => "DISTINCT users.id", 
           :conditions => [ "users.id IN (SELECT DISTINCT a.user_id FROM adesoes a WHERE a.topico_id IN (?)) OR users.id IN (SELECT DISTINCT t.user_id FROM topicos t WHERE t.id IN (?)) OR users.id IN (SELECT DISTINCT c.user_id FROM comments c WHERE c.commentable_type = 'Topico' AND c.commentable_id IN (?))", topico_ids, topico_ids, topico_ids ])
  end

  def self.que_criaram_comentaram_ou_apoiaram_um_topico(topico)
    topico_ids = topico.id
    scoped(:select => "DISTINCT users.id", 
           :conditions => [ "users.id IN (SELECT DISTINCT a.user_id FROM adesoes a WHERE a.topico_id IN (?)) OR users.id IN (SELECT DISTINCT t.user_id FROM topicos t WHERE t.id IN (?)) OR users.id IN (SELECT DISTINCT c.user_id FROM comments c WHERE c.commentable_type = 'Topico' AND c.commentable_id IN (?))", topico_ids, topico_ids, topico_ids ])
  end

  def self.find_by_id_criptografado(crypted_id)
    begin
      User.find(User.decrypt(crypted_id))
    rescue ActiveRecord::RecordNotFound
      return false
    end
  end
  
  # Dada as opcoes, selecionar quantos usuarios
  # existem de cada tipo (Cidadao, ONG, PoderPublico etc.)
  def self.total_por_tipo(options = {})
    # Strings a parte...
    sql_string  = []
    sql_string << "users.type <> 'admin'"
    sql_string << "users.state = 'active'"
    #sql_string << "taggings.tag_id = #{options[:tag_id]}" if options[:tag_id]
    sql_string << "locais.pais_id = #{options[:pais].id}" if options[:pais] and options[:pais].kind_of?(Pais)
    sql_string << "locais.estado_id = #{options[:estado].id} " if options[:estado] and options[:estado].kind_of?(Estado)
    sql_string << "locais.cidade_id = #{options[:cidade].id} " if options[:cidade] and options[:cidade].kind_of?(Cidade)
    sql_string << "locais.bairro_id = #{options[:bairro].id} " if options[:bairro] and options[:bairro].kind_of?(Bairro)

    sql_string = <<MYSTRING.gsub(/\s+/, " ").strip
    SELECT a.type, count(*) as total
    FROM (
      SELECT DISTINCT users.id, users.type
      FROM locais JOIN users
      ON (locais.responsavel_type = 'User') AND
         (locais.responsavel_id = users.id)
      WHERE #{sql_string.join(' AND ').to_s}
    ) a GROUP BY a.type
MYSTRING
    return User.find_by_sql(sql_string)
  end

  #================================================================#
  #                    OBJECT Methods                              #
  #================================================================#

  # Apaga os comentarios do usuario
  # antes de apaga-lo dos dados.
  def before_destroy
    Comment.find_comments_by_user(self).each{ |c| c.destroy }
  end

  # Metodo abstrato:
  # i.e. os filhos implementam.
  def nome_do_tipo
  end
  
  # Metodo abstrato:
  def nome_da_classe
  end

  def admin?
    self.class == Admin
  end

  def pessoa?
    self.class == Cidadao or
    self.class == GestorPublico or
    self.class == Parlamentar
  end

  def organizacao?
    self.class == Organizacao or
    self.class == Empresa or
    self.class == Ong or
    self.class == PoderPublico or
    self.class == Universidade or
    self.class == Igreja or
    self.class == Conferencia
  end

  def poder_publico?
    self.class == PoderPublico
  end

  def id_criptografado
    return User.encrypt(self.id.to_s)
  end

  # User tem bairro?
  def tem_bairro?
    self.local and self.local.bairro
  end

  # User tem cidade?
  def tem_cidade?
    self.local and self.local.cidade
  end

  # Atualizacoes dos contadores
  def atualiza_contadores
    if self.active?
      self.topicos_count = Topico.count(:conditions => [ "user_id = ?", self.id ])
      self.comments_count = Comment.count(:conditions => [ "user_id = ?", self.id ])
      self.adesoes_count = Adesao.count(:conditions => ["user_id = ?", self.id])
      self.relevancia = (100 * (Settings.user_relevancia_peso_topicos.to_f * self.topicos_count + Settings.user_relevancia_peso_comentarios.to_f * self.comments_count + Settings.user_relevancia_peso_apoios.to_f * self.adesoes_count)).to_i

      self.save(false)
    end
  end

  # Retorna Array com lista de atividades do usuario
  def atividades
    atividades = []
    # Topicos criados
    self.topicos.each { |t| atividades << t }
    # Comentarios feitos
    Comment.find_comments_by_user(self).each { |c| atividades << c }
    # Apoios/Adesoes
    self.adesoes.each { |a| atividades << a }
    # Seguidos
    self.seguidos.each { |s| atividades << s }
    return atividades.sort!{ |x, y| x.created_at <=> y.created_at }.reverse!
  end

  # Enviar email para usuario com instrucoes para trocar a senha.
  # Alem do id criptografado, seria bom enviar o salt e a criptedpass
  # para evitar que o link de troca de senha fique habilitado eternamente.
  def solicita_alteracao_de_senha
    UserMailer.deliver_instrucoes_reset_senha(self)
  end

  #================================================================#
  #                    Code from PLUGIN                            #
  #================================================================#

  # HACK HACK HACK -- how to do attr_accessible from here?
  # prevents a user from submitting a crafted form that bypasses activation
  # anything else you want your user to change should be added here.
  attr_accessible :login, :email, :name, :password, :password_confirmation, :type
  attr_accessor :old_password

  # Authenticates a user by their login name and unencrypted password.  Returns the user or nil.
  #
  # uff.  this is really an authorization, not authentication routine.
  # We really need a Dispatch Chain here or something.
  # This will also let us return a human error message.
  #
  def self.authenticate(login, password)
    return nil if login.blank? || password.blank?
    u = find_in_state :first, :active, :conditions => {:login => login} # need to get the salt
    u && u.authenticated?(password) ? u : nil
  end

  def login=(value)
    write_attribute :login, (value ? value.downcase : nil)
  end

  def email=(value)
    write_attribute :email, (value ? value.downcase : nil)
  end

  # used only here...
  protected

  def make_activation_code
    self.deleted_at = nil
    self.activation_code = self.class.make_token
  end

  def self.decrypt(str)
    Base64.decode64(CGI::unescape(str))
  end

  def self.encrypt(str)
    CGI::escape(Base64.encode64(str))
  end

end
