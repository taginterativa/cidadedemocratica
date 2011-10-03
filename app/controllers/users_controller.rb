class UsersController < ApplicationController
  # Protect these actions behind an admin login
  # before_filter :admin_required, :only => [:suspend, :unsuspend, :destroy, :purge]
  before_filter :find_user, :only => [ :suspend, :unsuspend, :destroy, :purge ]
  before_filter :login_required, :only => [ :solicitar_vinculacao, :vincular, :edit, :save, :trocar_senha, :descadastrar, :confirma_descadastro ]
  before_filter :obter_ordenacao, :only => [ :index ]
  before_filter :obter_localizacao, :only => [ :index ]

  # Maybe later, we should try...
  #in_place_edit_for :user_dado, :descricao

  def index
    # Filtros
    filtro_de_localizacao

    @users = User.ativos.nao_admin.do_tipo(params[:user_type]).do_pais(@pais).do_estado(@estado).da_cidade(@cidade).do_bairro(@bairro).paginate(:all, :page => params[:page], :per_page => 16, :order => @order, :include => :dado)
    @total_por_tipo = User.total_por_tipo(:pais => @pais,
                                          :estado => @estado,
                                          :cidade => @cidade,
                                          :bairro => @bairro) unless params[:user_type]
  end

  # render new.rhtml
  def new
    @user = User.new

    if request.post?
      # Faz logout, exceto se o usuário for administrador.
      logout_keeping_session! if logged_in? and current_user and not current_user.admin?

      # Que tipo de usuário criar?
      if params[:user][:type] and logged_in? and current_user.admin?
        @user = params[:user][:type].camelize.constantize.new(params[:user])
      else
        @user = Cidadao.new(params[:user])
      end

      # O login é o e-mail indicado.
      @user.login = @user.email
      @user.register! if @user && @user.valid?
      success = @user && @user.valid?
      if success && @user.errors.empty?
        redirect_to :action => "aguardando_confirmacao", :id => @user.id
        #redirect_back_or_default("/")
        flash[:notice] = "Obrigado pelo interesse! Nós lhe enviamos um e-mail com instruções para completar seu cadastro."
      end
    end
  end

  def activate
    logout_keeping_session!
    user = User.find_by_activation_code(params[:activation_code]) unless params[:activation_code].blank?
    case
      when (!params[:activation_code].blank?) && user && !user.active?
        session[:uncomplete_user] = user
        redirect_to completar_cadastro_url
      when params[:activation_code].blank?
        flash[:error] = "O código de ativação não foi informado. Por favor, clique no link enviado por e-mail."
        redirect_back_or_default("/")
      else
        flash[:error]  = "Não há um usuário com este código de ativação. Verifique o link em seu e-mail."
        redirect_back_or_default("/")
    end
  end

  verify :session => :uncomplete_user,
         :only => :complete
  def complete
    @user_dado = UserDado.new(params[:user_dado])
    @user = session[:uncomplete_user]
    @user_dado.user = @user
    @user_dado.sexo = "m" if ((params[:user_dado] and !params[:user_dado][:sexo]) or !params[:user_dado])

    @local = @user.local = Local.new(params[:local])

    if @user.pending?
      if request.post?
        if @user_dado.save
          @user.activate!
          session[:uncomplete_user] = nil

          # Faz o login.
          self.current_user = @user

          if session[:novo_topico]
            redirect_to :controller => "topicos", :action => "create"
          elsif session[:novo_comentario]
            redirect_to :controller => "comments", :action => "create"
          else
            flash[:notice] = "Pronto! Você agora é parte do Cidade Democrática e pode apontar problemas, criar propostas e colaborar com outras pessoas e entidades."
            redirect_to perfil_url(:id => @user.id)
          end
        end
      end
    else
      redirect_back_or_default("/")
    end
  end

  verify :params => :id,
         :only => :show
  def show
    @user = User.find(params[:id])
    @user_dado = @user.dado
    @tags = Tag.do_usuario(@user.id, :order => "total DESC", :limit => 30).sort { |a, b| a.name <=> b.name }
    @atividades = @user.atividades
    
    # Evita mostrar perfil do admin
    if @user.admin?
      redirect_to :controller => "topicos", :action => "index" and return# false
    elsif !@user.active?
      flash[:warning] = "Usuário inativo, banido ou removido do sistema."
      redirect_to :controller => "topicos", :action => "index" and return# false
    end

    respond_to do |wants|
      wants.html do
        # customizacao para HTML
      end
      #wants.js do
        # customizacao para JSON
        #render :json => { :topicos => @user.atividades[0..7] } #@user.topicos.to_json
      #end
      wants.rss do 
        # customizacao para RSS        
        @atividades = @user.atividades[0..100] #teste
        render :layout => false
      end
    end
  end

  verify :params => :id,
         :only => :show_ning
  def show_ning
    @user = User.find(params[:id])
    @user_dado = @user.dado
    @tags = Tag.do_usuario(@user.id, :order => "total DESC", :limit => 30).sort { |a, b| a.name <=> b.name }
    @atividades = @user.atividades
    
    # Evita mostrar perfil do admin
    if @user.admin? or !@user.active?
      redirect_to :controller => "topicos", :action => "index"
    end

    respond_to do |wants|
      wants.html do
        render :layout => 'ning'
      end
    end
  end

  def edit
    @user = current_user
    @user_dado = @user.dado
    @local = @user.local
    @imagem = Imagem.new
  end

  verify :method => :post,
         :only => :save
  def save
    if current_user
      @user = current_user

      # Atualiza os dados básicos do usuário.
      @user_dado = @user.dado
      @user_dado.update_attributes(params[:user_dado])
      @user_dado.save

      # Atualiza o local.
      @local = @user.local ? @user.local : Local.new(:responsavel => @user)
      @local.estado_id = params[:local][:estado_id]
      @local.cidade_id = params[:local][:cidade_id]
      @local.bairro_id = params[:local][:bairro_id]
      @local.cep = params[:local][:cep]
      @local.save

      # Atribui o local atualizado ao usuário.
      @user.local = @local
      @user.save

      redirect_to :action => "show", :id => @user.id
    else
      flash[:error] = "Não há usuário corrente"
      redirect_to :back
    end
  end

  def selos
    @user = current_user
    @local = Local.new(:cidade => @cidade_corrente)
    
    @script_perfil = '<a href="' + perfil_url(current_user) + '" target="_blank"><img src="http://cidadedemocratica.org.br/images/selo_perfil.gif"></a>'
    # Monta os ultimos 5 itens do perfil
    
    # O usuario setou algumas opcoes do selo
    if request.post?  
      
      @local = Local.new(params[:local])
      tipo = 'tema' # Selo padrao é o TEMA
      tipo = params[:banner] 
      tamanho = '120' # Tamanho padrao é 120px
      tamanho = params[:tamanho] 
      
      #Monta cidade e banner principal
      @script_cidade = '<p style="font-family: Verdana; font-size: 0.9em; background-color: #b4e0e3; width:' + tamanho + 'px; padding: 5px;">'
      @script_cidade << @local.cidade.nome
      @script_cidade << '<a href="' + topicos_url(@local.cidade) + '" target="_blank"><img src="http://cidadedemocratica.org.br/images/selo_melhore-' + tamanho + '.gif"></a>'
      
      #monta banner secundário
      case tipo
        when "tema"
            @script_cidade << '<a href="' + topicos_url(@local.cidade) + '" target="_blank"><img src="http://cidadedemocratica.org.br/images/selo_temas-' + tamanho + '.gif"></a>'
            # Monta os ultimos 5 itens da cidade
        when "proposta"
            @script_cidade << '<a href="' + nova_proposta_url(@local.cidade) + '" target="_blank"><img src="http://cidadedemocratica.org.br/images/selo_proposta-' + tamanho + '.gif"></a>'
        when "problema"
            @script_cidade << '<a href="' + novo_problema_url(@local.cidade) + '" target="_blank"><img src="http://cidadedemocratica.org.br/images/selo_problema-' + tamanho + '.gif"></a>'          
      end        
      @script_cidade << '</p>'
    end
    
  end
  
  def localizacao
    @user = current_user
    @local = @user.local ? @user.local : Local.new
    @user.local = @local
    @local.attributes = params[:local]

    if request.post? or request.put?
      if @local.save
        flash[:notice] = "Localização atualizada com sucesso."
        redirect_to perfil_url(@user.id)
      end
    end
  end
  
  # Tela que avisa sobre o descadastro;
  # apenas para usuarios logados.
  def descadastrar
    @user = current_user
  end

  def suspend
    @user.suspend!
    redirect_to users_path
  end

  def unsuspend
    @user.unsuspend!
    redirect_to users_path
  end

  def confirma_descadastro
    current_user.delete!
    logout_killing_session!
    redirect_to usuarios_url
  end

  def purge
    #@user.destroy
    @user.delete! #usando os estados do assm...
    redirect_to users_path
  end

  def solicitar_vinculacao
    organizacao = User.find(params[:organizacao_id])
    UserMailer.deliver_solicitar_vinculacao(organizacao, current_user)
    flash[:notice] = "Enviamos sua solicitação. A organização vai analisar sua solicitação e em breve responderá."
    redirect_to perfil_url(organizacao.id)
  end

  def vincular
    # O usuário logado é uma organização? Então pode vincular usuários.
    if current_user.organizacao?
      if user = User.find_by_id_criptografado(params[:user_id_criptografado])
        user.parent = current_user
        user.save

        # O usuário foi vinculado.
        # TODO: Notificar usuário vinculado por e-mail.
        flash[:notice] = "Usuário vinculado com sucesso."
        redirect_to perfil_url(current_user.id)
      end
    end
  end

  # There's no page here to update or destroy a user. If you add those, be
  # smart -- make sure you check that the visitor is authorized to do so, that they
  # supply their old password along with a new one to update it, etc.
  def trocar_senha
    @user = current_user
    @user.crypted_password = nil
    # se chegaram dados do form...
    if request.post?
      if (@user == User.authenticate(@user.email, params[:user][:old_password]))
        @user.password = params[:user][:password]
        @user.password_confirmation = params[:user][:password_confirmation]
        if @user.valid?
          @user.save
          flash[:notice] = "Senha alterada com sucesso."
          redirect_to perfil_url(@user.id)
        else
          @user.password = nil
          @user.password_confirmation = nil
        end
      else
        @user.password = nil
        @user.password_confirmation = nil
        flash[:error] = "Senha atual inválida."
      end
    end
  end
  
  # Dado um email, consultar se ele é usuario e se já confirmou.
  # Se sim, enviar email com link para RESET da senha.
  # Se nao, alert reportando erro.
  def solicitar_alteracao_de_senha
    unless params[:email].strip.blank?
      @user = User.find_by_email(params[:email])
      if @user
        if @user.active?
          @user.solicita_alteracao_de_senha
          render :update do |page|
            page.alert("Enviamos instruções para #{@user.email} a fim de alterar usa senha.\nConfira sua caixa de mensagens.")
          end
        else
          render :update do |page|
            page.alert('Usuário ainda não confirmado. Complete seu cadastro primeiro.')
          end
        end
      else
        render :update do |page|
          page.alert('Usuário não existente. Cadastre-se!')
        end
      end
    else
      render :update do |page|
        page.alert('Por favor, digite seu email no campo acima.')
      end      
    end
  end
  
  # Empresas, ongs e outros solicitando cadastros.
  def solicitar_cadastro_entidade
    if params[:solicitante][:email].strip.blank?
      render :update do |page|
        page.alert('Por favor, preencha corretamente seu email.')
      end
    elsif params[:solicitante][:nome].strip.blank?
      render :update do |page|
        page.alert('Por favor, preencha corretamente seu nome.')
      end
    elsif params[:solicitante][:entidade].strip.blank?
      render :update do |page|
        page.alert('Por favor, preencha corretamente o nome da entidade.')
      end
    else
      AdminMailer.deliver_pedido_cadastro_entidade(params[:solicitante])
      render :update do |page|
        page.alert('Obrigado. Seu contato foi recebido, em breve entraremos em contato por email.')
        page.hide("form_solicitacao")
      end      
    end
  end
  
  # URL para iniciar reset de senha
  # Se params ok, setar session e mandar
  # para action seguinte (reset_password)
  verify :params => [:id_criptografado, :crypted_password, :salt],
         :only => [:pwdrst],
         :redirect_to => :root_url
  def pwdrst
    user = User.find_by_id_criptografado(params[:id_criptografado])
    if (user.crypted_password == params[:crypted_password]) and (user.salt == params[:salt])
      session[:change_pwd] = user.id
      redirect_to :action => "reset_password"
    else
      flash[:error] = "Erro na URL para trocar de senha."
      redirect_to root_url
    end
  end
  
  # Action para trocar de senha.
  # No post, guardar nova senha e redirecionar.
  verify :session => :change_pwd,
         :only => :reset_password
  def reset_password
    @user = User.find(session[:change_pwd])
    if request.post?
      @user.crypted_password = '' #força a troca de senha
      @user.password = params[:user][:password]
      @user.password_confirmation = params[:user][:password_confirmation]
      if @user.valid?
        @user.save(false)
        session[:change_pwd] = nil
        flash[:notice] = "Sua senha foi alterada! Faça seu login!"
        redirect_to login_url
      end      
    end
  end
  
  # Tela que mostra o passo a passo
  # do que o usuario deve fazer
  def aguardando_confirmacao
      @user = User.find(params[:id])
      @link_ativacao = "#{@user.activation_code}"
  end
  
  # Envia uma mensagem para a caixa de email do usuário
  # Para prevenir de scans pegarem o email do usuário
  def mensagem
    @user = User.find(params[:id])
    @contato = Contato.new
    
    if logged_in?
      @contato.nome = current_user.nome
      @contato.email = current_user.email
    end
    
    if request.post?
      @contato.attributes = params[:contato]
      if @contato.valid?
        @contato.enviar(@user, @contato)
        flash[:notice] = "Mensagem enviada com sucesso!"
        redirect_to perfil_url(@user)
      end
    end
  end
  
private

  def obter_ordenacao
    case params[:user_order]
      when "relevancia"
        @order = "users.relevancia DESC"
      when "recentes"
        @order = "users.id DESC"
      when "mais_topicos"
        @order = "users.topicos_count DESC"
      when "mais_comentarios"
        @order = "users.comments_count DESC"
      when "mais_apoios"
        @order = "users.adesoes_count DESC"
      when "a-z"
        @order = "user_dados.nome ASC"
      when "z-a"
        @order = "user_dados.nome DESC"
      else
        params[:user_order] = "relevancia"
        @order = "users.relevancia DESC"
    end
  end

  def filtro_de_localizacao
    if !@estado
      @estados = Estado.com_usuarios_do_contexto(:user_type => params[:user_type]).all(:order => "abrev ASC")
    end
    if @estado and !@cidade
      @cidades = @estado.cidades.com_usuarios_do_contexto(:user_type => params[:user_type]).all(:order => "nome ASC")
    end
    if @estado and @cidade and !@bairro
      @bairros = @cidade.bairros.com_usuarios_do_contexto(:user_type => params[:user_type]).all(:order => "nome ASC")
    end
    # temporario... para campanha CIDADONOS
    @eh_de_jundiai = false 
    @eh_de_jundiai = true if (@cidade and @cidade.id == 85)
  end
  
protected

  def find_user
    @user = User.find(params[:id])
  end
end