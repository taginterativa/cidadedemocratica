module UsersHelper

  #
  # Use this to wrap view elements that the user can't access.
  # !! Note: this is an *interface*, not *security* feature !!
  # You need to do all access control at the controller level.
  #
  # Example:
  # <%= if_authorized?(:index,   User)  do link_to('List all users', users_path) end %> |
  # <%= if_authorized?(:edit,    @user) do link_to('Edit this user', edit_user_path) end %> |
  # <%= if_authorized?(:destroy, @user) do link_to 'Destroy', @user, :confirm => 'Are you sure?', :method => :delete end %>
  #
  #
  def if_authorized?(action, resource, &block)
    if authorized?(action, resource)
      yield action, resource
    end
  end

  #
  # Link to user's page ('users/1')
  #
  # By default, their login is used as link text and link title (tooltip)
  #
  # Takes options
  # * :content_text => 'Content text in place of user.login', escaped with
  #   the standard h() function.
  # * :content_method => :user_instance_method_to_call_for_content_text
  # * :title_method => :user_instance_method_to_call_for_title_attribute
  # * as well as link_to()'s standard options
  #
  # Examples:
  #   link_to_user @user
  #   # => <a href="/users/3" title="barmy">barmy</a>
  #
  #   # if you've added a .name attribute:
  #  content_tag :span, :class => :vcard do
  #    (link_to_user user, :class => 'fn n', :title_method => :login, :content_method => :name) +
  #          ': ' + (content_tag :span, user.email, :class => 'email')
  #   end
  #   # => <span class="vcard"><a href="/users/3" title="barmy" class="fn n">Cyril Fotheringay-Phipps</a>: <span class="email">barmy@blandings.com</span></span>
  #
  #   link_to_user @user, :content_text => 'Your user page'
  #   # => <a href="/users/3" title="barmy" class="nickname">Your user page</a>
  #
  def link_to_user(user, options={})
    raise "Invalid user" unless user
    options.reverse_merge! :content_method => :login, :title_method => :login, :class => :nickname
    content_text      = options.delete(:content_text)
    content_text    ||= user.send(options.delete(:content_method))
    options[:title] ||= user.send(options.delete(:title_method))
    link_to h(content_text), user_path(user), options
  end

  #
  # Link to login page using remote ip address as link content
  #
  # The :title (and thus, tooltip) is set to the IP address
  #
  # Examples:
  #   link_to_login_with_IP
  #   # => <a href="/login" title="169.69.69.69">169.69.69.69</a>
  #
  #   link_to_login_with_IP :content_text => 'not signed in'
  #   # => <a href="/login" title="169.69.69.69">not signed in</a>
  #
  def link_to_login_with_IP content_text=nil, options={}
    ip_addr           = request.remote_ip
    content_text    ||= ip_addr
    options.reverse_merge! :title => ip_addr
    if tag = options.delete(:tag)
      content_tag tag, h(content_text), options
    else
      link_to h(content_text), login_path, options
    end
  end

  #
  # Link to the current user's page (using link_to_user) or to the login page
  # (using link_to_login_with_IP).
  #
  def link_to_current_user(options={})
    if current_user
      link_to_user current_user, options
    else
      content_text = options.delete(:content_text) || 'not signed in'
      # kill ignored options from link_to_user
      [:content_method, :title_method].each{|opt| options.delete(opt)}
      link_to_login_with_IP content_text, options
    end
  end

  def ficha_do_usuario(usuario, options = {})
    options = {
      :badge => "", #opcoes: _mini, 
      :with_tags => true,
      :with_summary => false
    }.merge(options)
    render :partial => "users/ficha_do_usuario#{options[:badge]}",
           :locals => {
             :usuario => usuario,
             :options => options
           }
  end

  # Lista de usuários
  def usuarios(usuarios, options = {})
    options = {
      :vazio => "Não há usuários",
      :ficha_do_usuario_options => {}
    }.merge(options)
    render :partial => "users/usuarios",
           :locals => {
             :usuarios => usuarios,
             :options => options
           }
  end

  # Escreve link para editar infos do usuario
  def user_dados_editar(html_options = {})
    my_options = {
      :class => "edit_area rounded"
    }
    html_options = my_options.merge!(html_options)
    link = content_tag(:p, link_to(image_tag("icones/pencil.png"), :action => "edit"))
    return content_tag(:div, link, html_options)
  end

  # Dado um objeto de atividade (topico, comentario, adesao etc.),
  # retornar um <li>...</li> que descreva sucintamente a atividade
  # realizada pelo usuario, com link para mais informacoes.
  def descreve(obj, user, target = nil, my_options = {})
    options = {
      :truncate_comentario => false
    }.merge!(my_options)

    case obj.class.to_s
      when /(Proposta|Problema)/
        str  = "<li class=\"#{obj.class.to_s.downcase}\">"
        str += ficha_do_usuario(obj.user, :badge => "_mini", :with_tags => false) if user.nil?
        str += descreve_proposta(obj, user, target) if (obj.class == Proposta)
        str += descreve_problema(obj, user, target) if (obj.class == Problema)
      when /(Comment|Comentario)/
        str  = "<li class=\"comment #{obj.tipo}\">"
        if obj.commentable_type and (obj.commentable_type.to_s == 'Topico')
          topico_comentado = Comment.find_commentable(obj.commentable_type, obj.commentable_id)
          str += ficha_do_usuario(obj.user, :badge => "_mini", :with_tags => false) if user.nil?
          str += descreve_comentario(obj, user, topico_comentado, target, options) if (obj.tipo=="comentario")
          str += descreve_pergunta(obj, user, topico_comentado, target, options) if (obj.tipo=="pergunta")
          str += descreve_resposta(obj, user, topico_comentado, target, options) if (obj.tipo=="resposta")
          str += descreve_ideia(obj, user, topico_comentado, target, options) if (obj.tipo=="ideia")
        end
      when /(Adesao)/
        str  = "<li class=\"adesao\">"
        str += ficha_do_usuario(obj.user, :badge => "_mini", :with_tags => false) if user.nil?
        str += descreve_adesao(obj, user, target)
      when /(Seguido)/
        str  = "<li class=\"seguido\">"
        str += ficha_do_usuario(obj.user, :badge => "_mini", :with_tags => false) if user.nil?
        str += descreve_seguido(obj, user, target)
    end
    str += "<span class=\"quando\">Há #{distance_of_time_in_words_to_now(obj.created_at)}.</span>"
    str += "</li>"
    return str
  end

  private

  def descreve_problema(obj, user, target)
    str = "<div class='icon'>#{image_tag('icones/atividades_novo_problema.png')}</div>"
    str += "<div class='detalhes'><b>Apontou</b> um <span class=\"topico_type problema\">problema</span><br />"
    str += link_to(obj.titulo, topico_url(:topico_slug => obj.to_param))
    str += "</div>"
  end

  def descreve_proposta(obj, user, target)
    str = "<div class='icon'>#{image_tag('icones/atividades_nova_proposta.png')}</div>"
    str += "<div class='detalhes'><b>Criou</b> uma <span class=\"topico_type proposta\">proposta</span><br />"
    str += link_to(obj.titulo, topico_url(:topico_slug => obj.to_param))
    str += "</div>"
  end

  def descreve_comentario(obj, user, topico_comentado, target, options)
    str  = "<div class='icon'>#{link_to(image_tag('icones/atividades_comentou.png'), topico_url(:topico_slug => topico_comentado.to_param, :anchor => obj.id), :title => "Leia a discussão completa...")}</div>"
    str += "<div class='detalhes'><p class=\"descricao\"><b>Comentou</b>, sobre "
    str += descreve_comentario_qualquer(obj, user, topico_comentado, target, options)
    str += "</div>"
  end

  def descreve_pergunta(obj, user, topico_comentado, target, options)
    str = "<div class='icon'>#{link_to(image_tag('icones/atividades_perguntou.png'), topico_url(:topico_slug => topico_comentado.to_param, :anchor => obj.id), :title => "Leia a discussão completa...")}</div>"
    str += "<div class='detalhes'><p class=\"descricao\"><b>Perguntou</b>, sobre "
    str += descreve_comentario_qualquer(obj, user, topico_comentado, target, options)
    str += "</div>"
  end

  def descreve_resposta(obj, user, topico_comentado, target, options)
    str = "<div class='icon'>#{link_to(image_tag('icones/atividades_respondeu.png'), topico_url(:topico_slug => topico_comentado.to_param, :anchor => obj.id), :title => "Leia a discussão completa...")}</div>"
    str += "<div class='detalhes'><p class=\"descricao\"><b>Respondeu</b>, sobre "
    str += descreve_comentario_qualquer(obj, user, topico_comentado, target, options)
    str += "</div>"
  end

  def descreve_ideia(obj, user, topico_comentado, target, options)
    str = "<div class='icon'>#{link_to(image_tag('icones/atividades_ideia.png'), topico_url(:topico_slug => topico_comentado.to_param, :anchor => obj.id), :title => "Leia a discussão completa...")}</div>"
    str += "<div class='detalhes'><p class=\"descricao\">Deu uma <b>ideia</b> para "
    str += descreve_comentario_qualquer(obj, user, topico_comentado, target, options)
    str += "</div>"
  end

  def descreve_comentario_qualquer(obj, user, topico_comentado, target, options)
    str  = ""
    str += descreve_tipo_do_topico_e_seu_autor(topico_comentado, target)
    str += ":</p>"
    if options[:truncate_comentario]
      str += "<div class=\"o_comentario rounded\">#{simple_format(truncate(obj.body, options[:truncate_comentario]))}</div>" 
    else
      str += "<div class=\"o_comentario rounded\">#{simple_format(obj.body)}</div>" 
    end
  end

  def descreve_adesao(obj, user, target)
    str = "<div class='icon'>#{image_tag('icones/atividades_adesoes.png')}</div>"
    str += "<div class='detalhes'>"
    str += "<p class=\"descricao\"><b>Apoiou</b> "
    str += descreve_tipo_do_topico_e_seu_autor(obj.topico, target)
    str += "</p>"
    str += "</div>"
  end

  def descreve_seguido(obj, user, target)
    str = "<div class='icon'>#{image_tag('icones/atividades_seguidos.png')}</div>"
    str += "<div class='detalhes'>"
    str += "<p class=\"descricao\"><b>Seguindo</b> "
    str += descreve_tipo_do_topico_e_seu_autor(obj.topico, target)
    str += "</p>"
    str += "</div>"
  end

  def descreve_tipo_do_topico_e_seu_autor(topico, target)
    str  = "<span class=\"#{topico.class.to_s.downcase}\">#{topico.nome_do_tipo(:artigo => :definido)}</span> "
    str += "&#8220;#{link_to(topico.titulo, topico_url(:topico_slug => topico.to_param), :target => target)}"
    str += "&#8221; "
    str += "de "
    str += "#{link_to(topico.user.nome, perfil_url(:id => topico.user.id), :target => target ) }"
  end

  def vetor_de_tipos_de_usuario
    [
      [ "Cidadão", "cidadao" ],
      [ "Gestor público", "gestor_publico" ],
      [ "Parlamentar", "parlamentar"],
      [ "ONG", "ong" ],
      [ "Movimento", "movimento"],
      [ "Conferência", "conferencia"],
      [ "Empresa", "empresa" ],
      [ "Poder público", "poder_publico" ],
      [ "Igreja", "igreja"],
      [ "Universidade", "universidade"],
      [ "Outro tipo de organização", "organizacao" ],
      [ "Administrador (no Cidade Democrática)", "admin" ]
    ]
  end

  def select_tipo_de_usuario(options = {})
    options = {
      :name => "user[type]",
      :include_blank => false
    }.merge(options)

    selected_value = options[:name].to_s == "user[type]" ? params[:user][:type] : params[options[:name].to_sym]

    select_options = ""
    select_options += "<option></option>" if options[:include_blank]
    select_options += options_for_select(vetor_de_tipos_de_usuario, selected_value)

    select_tag(options[:name], select_options)
  end

end