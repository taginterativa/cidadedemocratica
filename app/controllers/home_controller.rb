class HomeController < ApplicationController

  # Ante sala do site
  def index
    if params[:site]=="cidadonos" or request.host.include?("cidadonos")
      cidadonos
    elsif params[:site]=="varzea2022" or request.host.include?("varzea2022")
      varzea2022
    else
      @estados = Estado.find(:all, :order => "abrev ASC")
      @cidades = Cidade.mais_ativas(:order => "cidades.relevancia DESC",
                                    :limit => @settings["home_cloud_items"].to_i).sort_by { |c| c.nome }
      @tags = Tag.do_contexto(:pais => nil,
                              :estado => nil,
                              :cidade => nil,
                              :bairro => nil,
                              :topico_type => nil,
                              :ultimos_dias => nil,
                              :order => "tags.relevancia DESC",
                              :limit => @settings["home_cloud_items"].to_i)
      @usuarios = User.nao_admin.ativos.com_avatar.aleatorios.find(:all, :limit => 8)
    
      @topicos = Topico.de_user_ativo.find(:all, :include => [:locais], :order => "topicos.id DESC", :limit => @settings["home_numero_topicos"].to_i)
      @topicos_mais_comentados = Topico.de_user_ativo.find(:all, :include => [:locais], :order => "topicos.comments_count DESC", :limit => @settings["home_numero_topicos"].to_i)
      @topicos_mais_apoiados   = Topico.de_user_ativo.find(:all, :include => [:locais], :order => "topicos.adesoes_count DESC", :limit => @settings["home_numero_topicos"].to_i)
    
      @apoios = Adesao.por_user_ativo.find(:all, :include => [:user, :topico], :order => "adesoes.created_at DESC", :limit => @settings["home_numero_apoios"].to_i)
      @seguidores = Seguido.por_user_ativo.find(:all, :include => [:topico], :order => "seguidos.created_at DESC", :limit => @settings["home_numero_seguidores"].to_i)
      @comentarios = Comentario.de_user_ativo.find(:all, :order => "comments.id DESC", :limit => @settings["home_numero_comentarios"].to_i)
      render :action => "index", :layout => "ante_sala"
    end
  end
  
  # REMENDO (ATENÇÃO: esse método aqui abaixo é um remendo, não prosseguir o desenvolvimento assim... 
  # um novo projeto DEVE ser pensado aqui!) não recomendo prosseguir o desenvolvimento tentando tapar o sol com a peneira...
  def cidadonos
    @jundiai = Cidade.find_by_slug('jundiai', :include => :estado)
    @estados = Estado.find(:all, :order => "abrev ASC")
    # atencão ao remendo abaixo...
    @cidades = Bairro.mais_ativos(:cidade => @jundiai,
                                  :order => "bairros.relevancia DESC",
                                  :limit => @settings["home_cloud_items"].to_i).sort_by { |c| c.nome }
    @tags = Tag.do_contexto(:pais => Pais.find(1),
                            :estado => Estado.find_by_abrev('sp'),
                            :cidade => @jundiai,
                            :bairro => nil,
                            :topico_type => nil,
                            :ultimos_dias => nil,
                            :order => "tags.relevancia DESC",
                            :limit => @settings["home_cloud_items"].to_i)
    @usuarios = User.nao_admin.ativos.com_avatar.da_cidade(@jundiai).aleatorios.find(:all, :limit => 8)
    
    @topicos = Topico.da_cidade(@jundiai).de_user_ativo.find(:all, :include => [:locais], :order => "topicos.id DESC", :limit => @settings["home_numero_topicos"].to_i)
    @topicos_mais_comentados = Topico.da_cidade(@jundiai).de_user_ativo.find(:all, :include => [:locais], :order => "topicos.comments_count DESC", :limit => @settings["home_numero_topicos"].to_i)
    @topicos_mais_apoiados   = Topico.da_cidade(@jundiai).de_user_ativo.find(:all, :include => [:locais], :order => "topicos.adesoes_count DESC", :limit => @settings["home_numero_topicos"].to_i)
    
    render :action => "cidadonos", :layout => "cidadonos"
  end

  def cidadonos_apoiadores
    render :layout => false
  end
  
  def cidadonos_parceiros
    render :layout => false
  end
  
  def cidadonos_quemsomos
    render :layout => false
  end

  # REMENDO (ATENÇÃO: esse método aqui abaixo é um remendo, não prosseguir o desenvolvimento assim... 
  # um novo projeto DEVE ser pensado aqui!) não recomendo prosseguir o desenvolvimento tentando tapar o sol com a peneira...
  def varzea2022
    @varzea  = Cidade.find_by_slug('varzea-paulista', :include => :estado)
    @estados = Estado.find(:all, :order => "abrev ASC")
    # atencão ao remendo abaixo...
    @cidades = Bairro.mais_ativos(:cidade => @varzea,
                                  :order => "bairros.relevancia DESC",
                                  :limit => @settings["home_cloud_items"].to_i).sort_by { |c| c.nome }
    @tags = Tag.do_contexto(:pais => Pais.find(1),
                            :estado => Estado.find_by_abrev('sp'),
                            :cidade => @varzea,
                            :bairro => nil,
                            :topico_type => nil,
                            :ultimos_dias => nil,
                            #:order => "tags.relevancia DESC",
                            :limit => @settings["home_cloud_items"].to_i)
    @usuarios = User.nao_admin.ativos.com_avatar.da_cidade(@varzea).aleatorios.find(:all, :limit => 8)
    
    @topicos = Topico.da_cidade(@varzea).de_user_ativo.find(:all, :include => [:locais], :order => "topicos.id DESC", :limit => @settings["home_numero_topicos"].to_i)
    @topicos_mais_comentados = Topico.da_cidade(@varzea).de_user_ativo.find(:all, :include => [:locais], :order => "topicos.comments_count DESC", :limit => @settings["home_numero_topicos"].to_i)
    @topicos_mais_apoiados   = Topico.da_cidade(@varzea).de_user_ativo.find(:all, :include => [:locais], :order => "topicos.adesoes_count DESC", :limit => @settings["home_numero_topicos"].to_i)
    
    render :action => "varzea2022", :layout => "varzea2022"
  end

  def varzea2022_apoiadores
    render :layout => false
  end
  
  def varzea2022_parceiros
    render :layout => false
  end
  
  def varzea2022_quemsomos
    render :layout => false
  end
  
  # Home da cidade
  def cidade
    case params[:order]
      when "relevancia"
        order = "topicos.relevancia DESC"
      when "recentes"
        order = "topicos.created_at DESC"
      when "antigos"
        order = "topicos.created_at ASC"
      when "mais_comentarios"
        order = "topicos.comments_count DESC"
      when "mais_apoios"
        order = "topicos.adesoes_count DESC"
      when "a-z"
        order = "topicos.titulo ASC"
      when "z-a"
        order = "topicos.titulo DESC"
      else
        params[:order] = "relevancia"
        order = "topicos.relevancia DESC"
    end
    
    @tags = Topico.tags_por_cidade(@cidade_corrente.id, :limit => 60).sort{ |a,b| a.name <=> b.name }
    @topicos = Topico.da_cidade(@cidade_corrente.id).find(:all, :limit => 8, :order => order)
    @bairros = Bairro.de_topicos(@cidade_corrente.id)
    @estatisticas = {
      :pessoas => Cidadao.da_cidade(@cidade_corrente.id).count,
      :propostas => Proposta.da_cidade(@cidade_corrente.id).count,
      :problemas => Problema.da_cidade(@cidade_corrente.id).count
    }
    # @ultimos_comentarios = [] #Comment.find(Topico)
    # troquei :order => "users.relevancia DESC" por "aleatorios" para mostrar alguma aleatoriedade
    @usuarios_mais_engajados = User.ativos.nao_admin.da_cidade(@cidade_corrente.id).aleatorios.find(:all, :include => :dado, :limit => 7)

    @contadores = Hash.new
    @contadores[:users] = User.da_cidade(@cidade_corrente.id).size
    @contadores[:propostas] = Proposta.da_cidade(@cidade_corrente.id).size
    @contadores[:problemas] = Problema.da_cidade(@cidade_corrente.id).size
  end
  
  # Lista de todas as tags do site
  def temas
    @tags = Tag.find(:all, Topico.find_options_for_tag_counts(:order => "name ASC"))
  end
  
  def termos_de_uso
  end
  
  def tour
  end

  def ajuda
  end

  def boas_praticas
  end

  def quem_somos
  end

  def para_cidadaos
  end

  def para_entidades
  end

end