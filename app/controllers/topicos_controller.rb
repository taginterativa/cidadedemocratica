class TopicosController < ApplicationController
  before_filter :verificar_se_pode_editar, :only => [ :edit, :update, :localizacao, :tags ]
  before_filter :obter_ordenacao, :only => [ :index, :usuarios_relacionados ]
  before_filter :obter_localizacao, :only => [ :index, :usuarios_relacionados ]
  before_filter :obter_tag, :only => [ :index, :usuarios_relacionados ]
  before_filter :obter_tags_populares, :only => [:new, :novo_problema, :nova_proposta, :create, :tags]

  # Metodos que não precisam de authenticity token
  protect_from_forgery :except => [ :auto_complete_for_topico_tags_com_virgula, :tags_by_link ]

  caches_action :index, :expires_in => 1.minute, :cache_path => Proc.new { |c| c.params }
  caches_action :show, :expires_in => 1.minute, :cache_path => Proc.new { |c| c.params }
    

  # Lista os tópicos de acordo com os filtros e ordenações escolhidas pelo
  # usuário.
  #
  # Filtra por:
  # * Cidade
  # * Bairro
  # * Tags
  # * Tempo (últimos 7, 30 ou todos)
  # * Tipo (proposta ou problema)
  #
  # Ordena por:
  # * Mais ativos (relevância)
  # * Mais recentes
  def index
    # Se está na home...
    params[:topico_type] = params[:topico_type] ? params[:topico_type] : "topicos"

    # Lista de tópicos
    @topicos = Topico.de_user_ativo.do_tipo(params[:topico_type]).do_proponente(params[:user_type]).do_pais(@pais).do_estado(@estado).da_cidade(@cidade).do_bairro(@bairro).com_tag(@tag).nos_ultimos_dias(params[:ultimos_dias]).paginate(:all, :order => @order, :page => params[:page], :include => [ { :user => :imagens }, :locais ])

    # Filtros
    filtro_de_tags
    filtro_de_tipos_de_topico
    filtro_de_tipos_de_usuario
    filtro_de_localizacao

    if params[:rss] and (params[:rss] == "rss")
      params[:format] = "xml"
      
    else # apenas para o HTML...
      topicos_so_com_id = Topico.de_user_ativo.do_tipo(params[:topico_type]).do_proponente(params[:user_type]).do_pais(@pais).do_estado(@estado).da_cidade(@cidade).do_bairro(@bairro).com_tag(@tag).nos_ultimos_dias(params[:ultimos_dias]).all(:select => :id)
      @users = User.ativos.nao_admin.que_criaram_comentaram_ou_apoiaram_topicos(topicos_so_com_id).paginate(:per_page => 25, :page => 1, :order => "users.relevancia DESC, users.topicos_count DESC, users.adesoes_count DESC")

      # Contadores
      calcular_contadores
    end
  end

  def usuarios_relacionados
    topicos_so_com_id = Topico.de_user_ativo.do_tipo(params[:topico_type]).do_proponente(params[:user_type]).do_pais(@pais).do_estado(@estado).da_cidade(@cidade).do_bairro(@bairro).com_tag(@tag).nos_ultimos_dias(params[:ultimos_dias]).all(:select => :id)
    @users = User.ativos.nao_admin.que_criaram_comentaram_ou_apoiaram_topicos(topicos_so_com_id).all(:order => "users.relevancia DESC, users.topicos_count DESC, users.adesoes_count DESC")
    render :partial => "topicos/lista_de_usuarios_relacionados",
           :locals => { :users => @users }
  end

  verify :params => :topico_type,
         :only => :new
  def new
    if params[:topico_type] == "problema"
      @topico = Problema.new(params[:topico])
      session[:type] = "Problema"
    elsif params[:topico_type] == "proposta"
      @problema = Problema.find(params[:parent_id]) if params[:parent_id]
      @topico = Proposta.new(params[:topico])
      session[:type] = "Proposta"
    end

    novo_topico
  end

  # Mostra o formulário para incluir um novo problema.
  def novo_problema
    @topico = Problema.new(params[:topico])
    if request.post?
      novo_topico
    else
      session[:type] = "Problema"
    end
  end

  # Mostra o formulário para incluir uma nova proposta.
  def nova_proposta
    @problema = Problema.find(params[:parent_id]) if params[:parent_id]
    @topico = Proposta.new(params[:topico])
    if request.post?
      novo_topico
    else
      session[:type] = "Proposta"
    end
  end

  verify :session => [ :novo_topico ],
         :only => "create"
  # Cria a nova proposta se o usuário estiver logado. Se não, redireciona
  # para formulário de login ou cadastro.
  def create
    @topico = session[:novo_topico]
    if logged_in?
      @topico.user = current_user
      if @topico.save
        current_user.tag(@topico, :with => @topico.tags_com_virgula, :on => :tags)
        session[:novo_topico] = nil

        # Atualiza os contadores do tópico e do usuário
        @topico.atualiza_contadores
        @topico.user.atualiza_contadores

        flash[:notice] = "Congratulações: #{@topico.nome_do_tipo} cadastrad#{@topico.artigo_definido} com sucesso no Cidade Democrática."
        redirect_to :action => "show", :topico_slug => @topico.to_param
      else
        render :action => "novo_problema" if session[:type] == "Problema"
        render :action => "novo_proposta" if session[:type] == "Proposta"
      end
    else
      # Se o user nao estiver logado, o que fazer?
      flash[:notice] = "Faça seu login ou cadastre-se"
      redirect_to login_url
    end
  end

  verify :params => :topico_slug,
         :only => :show
  def show
    @topico = Topico.de_user_ativo.slugged_find(params[:topico_slug])
    if @topico
      @links = @topico.links.find(:all, :limit => 5, :order => "id DESC")
      @comentarios = @topico.comment_threads.find(:all, :include => [:user], :order => "id DESC")
      @topicos_relacionados = @topico.relacionados
      @divulgacao = Divulgacao.new(:de_nome => current_user.nome,
                                   :de_email => current_user.email) if logged_in?
      @usar_splash = false 
      @topico.locais.each { |l| @usar_splash = true if [85,119].include?(l.cidade_id) }
    else
      redirect_to topicos_path and return false
    end
  end

  verify :session => [ :novo_topico ],
         :only => "localizar"
  def localizar
    @topico = session[:novo_topico]
    @topico.locais.clear # evita acumular locais, caso haja erros.
    @topico.editando_locais = true
    if request.post?
      if params[:locais]
        params[:locais].each do |local|
          tmp = Local.new(converter_params_to_hash(local))
          @topico.locais << tmp if tmp.valid?
        end
      end
      # Se passou na validacao de locais...
      if @topico.valid?
        session[:novo_topico] = @topico
        redirect_to :action => "create"
      end
    end
  end

  def localizacao
    @topico = Topico.slugged_find(params[:topico_slug])
    if request.post? or request.put?
      if params[:locais]
        @topico.locais.clear # evita acumular locais, caso haja erros.
        @topico.editando_locais = true
        params[:locais].each do |local|
          tmp = Local.new(converter_params_to_hash(local))
          @topico.locais << tmp if tmp.valid?
        end
      end
      # Se passou na validacao de locais...
      if @topico.valid?
        flash[:notice] = "Localização atualizada com sucesso."
        redirect_to topico_url(:topico_slug => @topico.to_param)
      end
    end
  end

  def tags
    @topico = Topico.slugged_find(params[:topico_slug])
    
    # Insere mais tags na lista: apenas visual
    if request.xhr?
      insere_html_para_tags(params['topico']['tags_com_virgula'], :clear_field => true)
    end #xhr?

    # Post para salvar...
    if request.post? and not request.xhr?
      @topico.tags.clear
      str_tags  = params['tag']['name'].join(",") if params['tag'] and params['tag']['name']
      str_tags += ",#{params[:topico][:tags_com_virgula]}" unless params[:topico][:tags_com_virgula].blank?
      @topico.tags_com_virgula = str_tags
      current_user.tag(@topico, :with => str_tags, :on => :tags)
      if @topico.save
        flash[:notice] = "Tags alteradas com sucesso!"
        redirect_to topico_url(:topico_slug => @topico.to_param)
      end
      @topico.reload
      @topico.tags_com_virgula = "" #limpa o campo...
    end
  end

  def tags_by_link
    insere_html_para_tags(params["tag_name"])
  end

  verify :params => [ :id ],
         :only => :processar_aderir
  def processar_aderir
    session[:topico_aderir] = Topico.find(params[:id])
    redirect_to :action => "aderir" if session[:topico_aderir]
  end

  verify :session => [ :topico_aderir ],
         :only => :aderir
  def aderir
    @topico = session[:topico_aderir]
    if logged_in?
      if @topico.user != current_user
        # Usuário já aderiu ao topico, remover adesao.
        aderiu = current_user.adesoes.find_by_topico_id(@topico.id)
        if aderiu
          aderiu.destroy
          flash[:notice] = "Deixou de apoiar!"
        else
          # Usuário ainda não aderiu, incluí-lo.
          current_user.adesoes.create(:topico_id => @topico.id, :user_id => current_user.id) unless current_user.adesao_ids.include?(@topico.id)
          flash[:notice] = "Apoiou!"
        end
      end

      # Tira o topico da session
      session[:topico_aderir] = nil
      redirect_to topico_url(:topico_slug => @topico.to_param)
    else
      # Se o user nao estiver logado, o que fazer?
      flash[:notice] = "Faça seu login ou cadastre-se para concretizar seu apoio!"
      redirect_to login_url
    end
  end

  # Envia emails para as pessoas
  verify :method => :post,
         :params => [:topico_id, :divulgacao],
         :only => :divulgar
  def divulgar
    @topico     = Topico.find(params[:topico_id])
    @divulgacao = Divulgacao.new(params[:divulgacao]) if @topico and params[:divulgacao]
    if @divulgacao and @divulgacao.valid?
      total = Topico.divulgar(@topico, @divulgacao)
      render :update do |page|
        page.alert("#{@topico.type} divulgad#{@topico.artigo_definido} para #{total} emails!")
      end
    else
      render :update do |page|
        page.alert("Confira os campos.")
      end
    end
  end
  
  # Divulgar com AddThis
  # http://www.addthis.com/help/api-spec
  def divulgue_para_todos
    @topico = Topico.slugged_find(params[:topico_slug])
  end

  def denunciar
    @topico = Topico.de_user_ativo.slugged_find(params[:topico_slug])
    if @topico
      if request.post?
        if params['denuncia'] #Enviar o email com a denuncia
          AdminMailer.deliver_denuncia_em_topico(@topico, params[:denuncia])
          flash[:notice] = "Denúncia enviada. Sua mensagem será lida, analisada e, em breve, respondida."
        end
        redirect_to topico_url(:topico_slug => @topico.to_param)
      else
        render :partial => "form_denuncie"
      end
    else
      redirect_to topicos_url
    end
  end

  protect_from_forgery :except => [:auto_complete_for_topico_tags_com_virgula]
  # Oferece a busca inteligente
  def auto_complete_for_topico_tags_com_virgula
    if params[:topico] and params[:topico][:tags_com_virgula]
      words = params[:topico][:tags_com_virgula].split(',')
      auto_complete_responder_for_tags words.last.strip
    end
  end

  def logado_e_criador_do_topico?
    logged_in? && @topico.user == current_user
  end

  # Dado o titulo que o usuario digitou
  # mostrar os topicos similares para
  # evitar criar "duplicatas". APROVEITA
  # e sugere ao menos 3 TAGS relacionadas.
  def mostrar_similares
    used_words = []
    maybe_tags = []
    all_words  = params[:titulo].split(" ").each{ |w| used_words << "'%#{w}%'" if (w.size > 3) and not @settings['relatorios_termos_excluidos'].include?(w) }
    conditions_sql = (used_words.size > 0) ? "titulo LIKE #{used_words.join(' OR ')}" : nil
    model = session[:type] ? session[:type].constantize : Topico

    topicos = model.find(:all, :conditions => conditions_sql, :limit => 5, :include => [:locais => :cidade])
    topicos.each do |top| 
      top.tag_list.split(",") do |tag| 
        maybe_tags << tag.strip if (not maybe_tags.include?(tag) and 
                                    not used_words.include?(tag) and 
                                    not @settings['relatorios_termos_excluidos'].include?(tag))
      end
    end
    render :update do |page|
      page.replace_html "similares",
                        :partial => "topicos/similares",
                        :locals => { :topicos => topicos }
      page.replace_html "tags_possiveis",
                        :partial => "topicos/sugerir_tags",
                        :locals => {
                          :palavras => used_words,
                          :tags => maybe_tags
                        }
    end
  end

  # Edita um tópico
  def edit
    @topico = Topico.slugged_find(params[:topico_slug])
    @topico.tags_com_virgula = @topico.tags.collect { |t| t.name }.join(", ")
  end

  def update
    @topico = Topico.slugged_find(params[:topico_slug])
    if @topico.update_attributes(params[:topico])
      flash[:notice] = "Atualizamos #{@topico.nome_do_tipo(:artigo => :definido)} com sucesso!"
      redirect_to topico_url(:topico_slug => @topico.to_param)
    else
      render :action => "edit"
    end
  end

  verify :params => [ :topico_slug ],
         :only => :processar_seguir
  def processar_seguir
    session[:topico_seguir] = Topico.slugged_find(params[:topico_slug])
    redirect_to :action => "seguir" if session[:topico_seguir]
  end

  verify :session => [ :topico_seguir ],
         :only => :seguir
  def seguir
    @topico = session[:topico_seguir]
    if logged_in?
      if @topico.user != current_user
        # Usuário já aderiu ao topico, remover adesao.
        seguiu = current_user.seguidos.find_by_topico_id(@topico.id)
        if seguiu
          seguiu.destroy
          flash[:notice] = "Deixou de seguir!"
        else
          # Usuário ainda não aderiu, incluí-lo.
          current_user.seguidos.create(:topico_id => @topico.id, :user_id => current_user.id)
          flash[:notice] = "Seguiu!"
        end
      end
      # Tira o topico da session
      session[:topico_seguir] = nil
      redirect_to topico_url(:topico_slug => @topico.to_param)
    else
      # Se o user nao estiver logado, o que fazer?
      flash[:notice] = "Faça seu login ou cadastre-se para seguir este tópico!"
      redirect_to login_url
    end
  end

  protected

  # Processa o envio do novo problema ou da nova proposta. Guarda na sessão
  # e segue para a localizacao. O tópico fica na sessão para unificar o modo como
  # a aplicação cria a proposta de:
  #   * Um usuário logado
  #   * Um usuário não-logado já cadastrado
  #   * Um usuário não-logado sem cadastro
  def novo_topico
    if request.post?
      @topico.tags_com_virgula = @topico.tags_com_virgula.downcase # Força lowercase para as tags
      if @topico.valid?
        session[:novo_topico] = @topico
        redirect_to localizar_novo_topico_url(:topico_type => params[:topico_type])
      end
    end
  end

  # Dado params, nos possíveis formatos: 
  #  - local[pais_id] = xx
  #  - local[pais_id][xx][estado_id] = xx
  #  - local[pais_id][xx][estado_id][xx][cidade_id] = xx
  #  - local[pais_id][xx][estado_id][xx][cidade_id][xx][bairro_id] = xx
  # Retornar o Hash adequado para criar um Local.
  def converter_params_to_hash(local)
    pais_id = estado_id = cidade_id = bairro_id = nil
    if local["pais_id"]
      pais = local["pais_id"]
      pais_id = pais.kind_of?(Hash) ? pais.keys.first : pais
      if pais.kind_of?(Hash) and pais.values.first["estado_id"]
        estado = pais.values.first["estado_id"]
        estado_id = estado.kind_of?(Hash) ? estado.keys.first : estado
        if estado.kind_of?(Hash) and estado.values.first["cidade_id"]
          cidade = estado.values.first["cidade_id"]
          cidade_id = cidade.kind_of?(Hash) ? cidade.keys.first : cidade
          if cidade.kind_of?(Hash) and cidade.values.first["bairro_id"]
            bairro = cidade.values.first["bairro_id"]
            bairro_id = bairro.kind_of?(Hash) ? bairro.keys.first : bairro
          end
        end
      end
    end
    return { :pais_id => pais_id,
             :estado_id => estado_id, 
             :cidade_id => cidade_id,
             :bairro_id => bairro_id }
  end

  private

  def obter_ordenacao
    case params[:order]
      when "relevancia"
        @order = "topicos.relevancia DESC"
      when "recentes"
        @order = "topicos.created_at DESC"
      when "antigos"
        @order = "topicos.created_at ASC"
      when "mais_comentarios"
        @order = "topicos.comments_count DESC"
      when "mais_apoios"
        @order = "topicos.adesoes_count DESC"
      when "a-z"
        @order = "topicos.titulo ASC"
      when "z-a"
        @order = "topicos.titulo DESC"
      else
        params[:order] = "relevancia"
        @order = "topicos.relevancia DESC"
    end
  end

  #def obter_localizacao
  # ATENCAO: movi o metodo que estava aqui para o application_controller
  #          pois o user_controller usa do mesmo metodo.
  #end

  def obter_tag
    if !params[:tag_id].blank?
      if Tag.exists?(params[:tag_id])
        @tag = Tag.find_by_id(params[:tag_id])
      else
        logger.info("  \e[1;31m404: Nao existe tag com ID = #{params[:tag_id]}.\e[0m")
        render :file => "#{RAILS_ROOT}/public/404.html", :layout => false, :status => 404 and return
      end
    end
  end
  
  def obter_tags_populares
    tt = nil,
    tt = @topico.class.to_s if @topico
    tt = params[:topico] unless params[:topico].blank?
    
    @tags = Tag.do_contexto(:topico_type => tt,
                            :limit => 60)
    
  end

  def filtro_de_tags
    if @tag
      @tags = Tag.relacionadas(@tag,
                               :pais => @pais,
                               :estado => @estado,
                               :cidade => @cidade,
                               :bairro => @bairro,
                               :topico_type => params[:topico_type],
                               :ultimos_dias => params[:ultimos_dias],
                               :limit => 60)
    else
      @tags = Tag.do_contexto(:pais => @pais,
                              :estado => @estado,
                              :cidade => @cidade,
                              :bairro => @bairro,
                              :topico_type => params[:topico_type],
                              :ultimos_dias => params[:ultimos_dias],
                              :limit => 60)
    end
  end

  def filtro_de_tipos_de_topico
    # Não precisa somar tópicos por tipo, pois o tipo foi escolhido.
    if !params[:topico_type] or (params[:topico_type] == "topicos")
      @total_por_tipo = Topico.total_por_tipo(:pais => @pais,
                                              :estado => @estado,
                                              :cidade => @cidade,
                                              :bairro => @bairro,
                                              :tag => @tag,
                                              :user_type => params[:user_type],
                                              :ultimos_dias => params[:ultimos_dias])
    end
  end

  def filtro_de_tipos_de_usuario
    # Não precisa contar os tipos de usuario, pois já foi escolhido.
    if !params[:user_type]
      @total_criados_por = Topico.total_criados_por(:pais => @pais,
                                                    :estado => @estado,
                                                    :cidade => @cidade,
                                                    :bairro => @bairro,
                                                    :tag => @tag,
                                                    :topico_type => params[:topico_type],
                                                    :ultimos_dias => params[:ultimos_dias])
    end
  end

  def filtro_de_localizacao
    if !@estado
      @estados = Estado.com_topicos_do_contexto(:tag => @tag,
                                                :user_type => params[:user_type],
                                                :topico_type => params[:topico_type],
                                                :ultimos_dias => params[:ultimos_dias]).all(:order => "abrev ASC")
    end

    if @estado and !@cidade
      @cidades = @estado.cidades.com_topicos_do_contexto(:tag => @tag,
                                                         :user_type => params[:user_type],
                                                         :topico_type => params[:topico_type],
                                                         :ultimos_dias => params[:ultimos_dias]).all(:order => "nome ASC")
    end

    if @estado and @cidade and !@bairro
      @bairros = @cidade.bairros.com_topicos_do_contexto(:tag => @tag,
                        :user_type => params[:user_type],
                        :topico_type => params[:topico_type],
                        :ultimos_dias => params[:ultimos_dias]).all(:order => "nome ASC")
    end
    
    @usar_splash = false 
    @usar_splash = true if (@cidade and [85,119].include?(@cidade.id))
  end

  def calcular_contadores
    # @contadores = Hash.new
    # @contadores[:users] = Topico.do_tipo(params[:topico_type]).do_proponente(params[:user_type]).da_cidade(@cidade.id).do_bairro(params[:bairro_id]).com_tag(params[:tag_id]).nos_ultimos_dias(params[:ultimos_dias]).find(:all, :group => :user_id).size
    # @contadores[:propostas] = Proposta.do_tipo(params[:topico_type]).do_proponente(params[:user_type]).da_cidade(@cidade.id).do_bairro(params[:bairro_id]).com_tag(params[:tag_id]).nos_ultimos_dias(params[:ultimos_dias]).size
    # @contadores[:problemas] = Problema.do_tipo(params[:topico_type]).do_proponente(params[:user_type]).da_cidade(@cidade.id).do_bairro(params[:bairro_id]).com_tag(params[:tag_id]).nos_ultimos_dias(params[:ultimos_dias]).size

    @contadores = Hash.new
    @contadores[:propostas] = Proposta.do_proponente(params[:user_type]).do_pais(@pais).do_estado(@estado).da_cidade(@cidade).do_bairro(@bairro).com_tag(@tag).nos_ultimos_dias(params[:ultimos_dias]).size
    @contadores[:problemas] = Problema.do_proponente(params[:user_type]).do_pais(@pais).do_estado(@estado).da_cidade(@cidade).do_bairro(@bairro).com_tag(@tag).nos_ultimos_dias(params[:ultimos_dias]).size
    @contadores[:comentarios] = Topico.total_comentarios(:topico_type => params[:topico_type], 
                                                         :user_type => params[:user_type], 
                                                         :pais => @pais,
                                                         :estado => @estado,
                                                         :cidade => @cidade,
                                                         :bairro => @bairro,
                                                         :tag => @tag,
                                                         :ultimos_dias => params[:ultimos_dias])[0].total
    @contadores[:adesoes] = Adesao.total(:topico_type => params[:topico_type], 
                                         :user_type => params[:user_type], 
                                         :pais => @pais,
                                         :estado => @estado,
                                         :cidade => @cidade,
                                         :bairro => @bairro,
                                         :tag => @tag,
                                         :ultimos_dias => params[:ultimos_dias])[0].total

  end

  def auto_complete_responder_for_tags(value)
    tags = Tag.find(:all,
                    :conditions => [ 'name LIKE ?', '%' + value + '%'],
                    :order => 'name ASC',
                    :limit => 8)
    if tags
      render :partial => 'form_tags_live_search',
             :locals => {
               :tags => tags,
               :typed => value
             }
    else
      render :nothing => true
    end
  end

  def verificar_se_pode_editar
    @topico = Topico.slugged_find(params[:topico_slug])
    if logged_in? and not current_user.admin?
      if !@topico.pode_editar? or current_user != @topico.user
        flash[:warning] = "Você não tem permissão para editar #{@topico.nome_do_tipo(:artigo => :definido)}."
        redirect_to topico_url(:topico_slug => @topico.to_param) and return false
      end
    end
  end
  
  def insere_html_para_tags(texto, options = {})
    if texto.blank?
      render :nothing => true
    else
      render :update do |page|
        texto.split(",").each do |t|
          page.insert_html :bottom, 
                           "all_tags", 
                           :partial => "tags_hidden", 
                                       :locals => { 
                                         :tag_name => t.strip
                                       }
        end
        # Limpa o campo de insercao
        page['topico_tags_com_virgula'].value = "" if options[:clear_field]
      end
    end
  end

end
