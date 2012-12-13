# encoding: utf-8

module ApplicationHelper

  def flash_message
    messages = ""
    [ :notice, :info, :warning, :error ].each do |type|
      messages = content_tag(:p, flash[type], :class => type) if flash[type]
    end
    m1 = content_tag(:div, messages, :id => "flash_message") if (messages and not messages.empty?)
    # m2 = javascript_tag("Effect.Fade('flash_message', { duration: 15 });")
    # return m1 + m2 if (m1 and not m1.empty?)
    m1
  end

  def sexo(dados)
    if dados.sexo == 'm'
      image_tag "icones/male.png"
    elsif dados.sexo == 'f'
      image_tag "icones/female.png"
    end
  end

  def host
    case RAILS_ENV
      when "development"
        "http://192.168.1.109:9999"
      when "production"
        "http://www.cidadedemocratica.com.br"
    end
  end

  # Copy-Paste from plugin's helper
  # When auto-loaded, remove this code bellow:
  def tag_cloud(tags, classes, options = {})
    if tags and not tags.empty?
      if options[:relevancia]
        max_count = tags.sort_by{ |t| t.relevancia.to_i }.last.relevancia.to_f
      else
        max_count = tags.sort_by{ |t| t.total.to_i }.last.total.to_f
      end

      tags.sort{ |b,a| b.name.downcase.remover_acentos <=> a.name.downcase.remover_acentos }.each do |tag|
        if options[:relevancia]
          index = ((tag.relevancia.to_f / max_count.to_f) * (classes.size - 1)).to_i
        else
          index = ((tag.total.to_f / max_count.to_f) * (classes.size - 1)).to_i
        end
        # logger.debug(">>> Max: #{max_count}; tag: #{tag.name}; count: #{tag.total}; class: #{classes[index]}")
        yield tag, classes[index]
      end
    end
  end

  def cidades_cloud(cidades, classes, options = {})
    if cidades and not cidades.empty?
      max_count = cidades.sort_by{ |t| t.total.to_i }.last.total.to_f
      max_count = cidades.sort_by{ |t| t.relevancia.to_i }.last.relevancia.to_f if options[:relevancia]
      cidades.sort_by{ |a| a.nome.remover_acentos }.each do |cidade|
        index = ((cidade.total.to_f / max_count.to_f) * (classes.size - 1)).to_i
        index = ((cidade.relevancia.to_f / max_count.to_f) * (classes.size - 1)).to_i if options[:relevancia]
        yield cidade, classes[index]
      end
    end
  end

  # Cria um link mantendo todos os parâmetros do atual contexto da página,
  # inclusive o controller e o action. Basta fornecer em options os parâmetros
  # que são diferentes.
  def link_to_with_context(name, options = {}, html_options = {})
    contains = true
    # logger.debug("> #{name}")
    options.each do |key, value|
      # logger.debug(">> #{key}: #{value}")
      if value.nil?
        result = !params.key?(key.to_s)
        # logger.debug(">>> Tem #{key} e NIL -> #{result}")
      else
        result = (params.key?(key.to_s) and params[key.to_s] == value.to_s)
        # logger.debug(">>> Tem #{key} e #{value} -> #{result}")
      end
      contains = contains && result
    end

    # HTML: link class
    class_names = []
    class_names << "selected" if contains
    class_names << html_options[:class] if html_options[:class]

    options = params.merge(options)

    link_to name, options, html_options.merge(:class => class_names.join(" "))
  end

  # Cria um link, marcando com a class "selecionado"
  # quando a aba do menu principal do site estiver selecionada.
  def link_to_aba_selecionada(name, options = {}, html_options = {})
    class_name= "lapela_menu"
    case name
      when "Propostas e problemas"
        class_name += " selecionado" if request.request_uri.index(/(topicos|propostas|problemas|topico|nova_proposta|novo_problema)/)
      when "Pessoas e entidades"
        class_name += " selecionado" if request.request_uri.index(/(usuarios|perfil|login|cadastrar)/)
      when /(Meu )\w+/
        class_name += " selecionado" if request.request_uri.index(/(observatorio)/)
      when "Tour"
        class_name += " selecionado" if request.request_uri.index(/(tour)/)
      else
        class_name += " selecionado" if request.request_uri == "/#{@cidade_corrente.slug}"
    end
    link_to name, options, html_options.merge(:class => class_name)
  end

  def link_to_em_construcao(name, options = {})
    link_to_function(name, "alert('Desculpe, mas este recurso ainda não está disponível. Mesmo assim, preferimos deixar esta opção visível para que você conheça tudo o que o Cidade Democrática irá oferecer.')", options)
  end

  def filtro(nome_do_filtro, links, options = {})
    options = {
      :numero_de_links => 10,
      :expandido => false
    }.merge(options)
    render :partial => "/shared/filtro",
           :locals => {
             :nome_do_filtro => nome_do_filtro,
             :links => links,
             :url_para_ver_mais => "",
             :options => options
           }
  end

  def criando_nova_proposta?
    params[:topico_type] == "proposta"
  end

  def criando_novo_problema?
    params[:topico_type] == "problema"
  end

  def descrevendo_topico?
    controller.controller_name == "topicos" and controller.action_name == "new"
  end

  def localizando_topico?
    controller.controller_name == "topicos" and controller.action_name == "localizar"
  end

end
