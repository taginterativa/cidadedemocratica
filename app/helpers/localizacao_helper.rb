# encoding: utf-8

module LocalizacaoHelper
  def select_estado(local, my_options = {})
    options = {
      :dom_id => "estado_id"
    }.merge!(my_options)
    #select_tag "estado_id", options_for_select(Estado.find(:all, :order => "abrev ASC").collect { |c| [ c.abrev, c.id ] }, cidade_escolhida(local, options).estado_id), :id => options[:dom_id]
    select_tag("local[estado_id]", options_for_select(Estado.find(:all, :order => "abrev ASC").collect { |c| [ c.abrev, c.id ] }, cidade_escolhida(local, options).estado_id), :id => options[:dom_id])
  end

  def select_bairro(local, options = {})
    options = {
      :first_option => nil,
      :class => "filtro",
      :style => "_width:200px"
    }.merge!(options)

    bairro_escolhido_id = local ? local.bairro_id : nil

    lista_de_opcoes = ""
    lista_de_opcoes += "<option value=null>#{options[:first_option]}</option>" if options[:first_option]
    lista_de_opcoes += options_for_select(Bairro.find(:all, :conditions => { :cidade_id => cidade_escolhida(local, options).id }, :order => "nome ASC").collect{ |b| [ b.nome, b.id ] }, bairro_escolhido_id)

    select_tag("local[bairro_id]", lista_de_opcoes, options.delete_if { |k,v|  k.to_s == "cidade_corrente" }) + content_tag(:span, " opcional", :class => "ajuda")
  end

  # def select_cidade(local, options = {})
  #   estado_escolhido = local.cidade_id.nil? ? nil : Cidade.find(local.cidade_id).estado_id
  #   select_tag "local[cidade_id]", options_for_select(Cidade.find(:all, :conditions => [ "estado_id = ?", estado_escolhido ], :order => "nome asc").collect { |c| [ c.nome, c.id ] }, qual_cidade)
  # end

  def select_cidade(local, options = {})
    options = {
      :first_option => nil,
      :class => "filtro"
    }.merge!(options)

    lista_de_opcoes = ""
    lista_de_opcoes += "<option value=null>#{options[:first_option]}</option>" if options[:first_option]
    lista_de_opcoes += options_for_select(Cidade.find(:all, :conditions => { :estado_id => cidade_escolhida(local, options).estado_id }, :order => "nome ASC").collect { |c| [ c.nome, c.id ] }, cidade_escolhida(local, options).id)

    select_tag "local[cidade_id]", lista_de_opcoes, options.delete_if { |k,v|  k.to_s == "cidade_corrente" }
  end

  def cidade_escolhida(local, options = {})
    if local and local.cidade_id
      Cidade.find(local.cidade_id)
    elsif options[:cidade_corrente]
      options[:cidade_corrente]
    else
      Cidade.find_by_slug("sao-paulo")
    end
  end

  def descrever_locais(locais, options = {})
    options = {
      :modo => :resumido
    }.merge(options)

    descricao_dos_locais = []
    if locais and (locais.size > 0)
      locais.each do |local|
        if local and local.tem_bairro? and local.tem_cidade? and local.tem_estado?
          descricao_dos_locais << link_to("#{local.bairro.nome}, #{local.bairro.cidade.nome} - #{local.bairro.cidade.estado.abrev}", {
                                            :controller => "topicos",
                                            :action => "index",
                                            :topico_type => "topicos",
                                            :estado_abrev => "#{local.bairro.cidade.estado.abrev.downcase}",
                                            :cidade_slug => "#{local.bairro.cidade.slug}",
                                            :bairro_id => "#{local.bairro.id}" })
        elsif local and local.tem_cidade? and local.tem_estado?
          descricao_dos_locais << link_to("#{local.cidade.nome} - #{local.cidade.estado.abrev}", {
                                            :controller => "topicos",
                                            :action => "index",
                                            :topico_type => "topicos",
                                            :estado_abrev => "#{local.cidade.estado.abrev.downcase}",
                                            :cidade_slug => "#{local.cidade.slug}" })
        elsif local and local.tem_estado?
          descricao_dos_locais << link_to("#{local.estado.abrev}", {
                                            :controller => "topicos",
                                            :action => "index",
                                            :topico_type => "topicos",
                                            :estado_abrev => "#{local.estado.abrev.downcase}" })
        else
          descricao_dos_locais << link_to("Em todo o país", {
                                            :controller => "topicos",
                                            :action => "index",
                                            :topico_type => "topicos" })
        end
      end
    end
    descricao_dos_locais.join(" - ")
  end

  def defineAmbito(ambito, locais, two_classes)
    off = two_classes[0]
    on  = two_classes[1]
    case ambito
      when "nacional"
        return off if locais.empty?
        return on  if (locais.first.ambito == "nacional")
        return off
      when "estadual"
        return off if locais.empty?
        return on  if (locais.first.ambito == "estadual")
        return off
      when "municipal"
        return on if locais.empty? # Se estiver vazio, padrao = municipal
        return on if (locais.first.ambito == "municipal")
        return off
      when "local"
        return off if locais.empty?
        return on  if (locais.first.ambito == "local")
        return off
    end
  end
end
