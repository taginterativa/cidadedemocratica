class Admin::RelatoriosController < Admin::AdminController

  before_filter :intervalo

  def index
    @causas = Topico.agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
      @propostas = Topico.do_tipo(Proposta).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
      @problemas = Topico.do_tipo(Problema).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @prop_prob = Topico.agrupados_por_tipo.no_intervalo(@data_de, @data_ate)
      @prop_prob_total = 0 
      @prop_prob.each{ |k| @prop_prob_total += k.total.to_i }
      
    @adesoes = Adesao.agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @comentarios = Comentario.agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    
    @pais    = Topico.agrupados_pelo_pais.no_intervalo(@data_de, @data_ate)
    @estados = Topico.agrupados_por_estados.no_intervalo(@data_de, @data_ate)
    @cidades = [] #Topico.agrupados_por_cidades.no_intervalo(@data_de, @data_ate)
    @bairros = Topico.agrupados_por_bairros.no_intervalo(@data_de, @data_ate)
    @temas   = [] #Topico.join_da_cidade(@cidades.first).agrupados_por_tags.no_intervalo(@data_de, @data_ate)
  end
  
  verify :params => :id,
         :only => :cidade
  def cidade
    @cidade = Cidade.find(params[:id])
    @propostas = Topico.do_tipo(Proposta).join_da_cidade(@cidade).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @problemas = Topico.do_tipo(Problema).join_da_cidade(@cidade).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    
    topicos     = Topico.join_da_cidade(@cidade).no_intervalo(@data_de, @data_ate).find(:all)
    topicos_ids = topicos.collect { |t| t.id }

    @adesoes = Adesao.dos_topicos(topicos_ids).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @comentarios = Comentario.dos_topicos(topicos_ids).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @temas   = Topico.join_da_cidade(@cidade).agrupados_por_tags.no_intervalo(@data_de, @data_ate)
    @bairros = Topico.no_intervalo(@data_de, @data_ate).agrupados_por_bairros_da_cidade(@cidade)
    
    users = User.que_criaram_comentaram_ou_apoiaram_topicos(topicos).collect{ |u| u.id }
    @users = User.find(users)
  end

  verify :params => :id,
         :only => :tag
  def tag
    @tag = Tag.find(params[:id])
    @propostas = Topico.do_tipo(Proposta).join_da_tag(@tag).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @problemas = Topico.do_tipo(Problema).join_da_tag(@tag).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    
    topicos     = Topico.join_da_tag(@tag).no_intervalo(@data_de, @data_ate).find(:all)
    topicos_ids = topicos.collect { |t| t.id }

    @adesoes = Adesao.dos_topicos(topicos_ids).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @comentarios = Comentario.dos_topicos(topicos_ids).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    
    @pais    = Topico.join_da_tag(@tag).agrupados_pelo_pais.no_intervalo(@data_de, @data_ate)
    @estados = Topico.join_da_tag(@tag).agrupados_por_estados.no_intervalo(@data_de, @data_ate)
    @cidades = Topico.join_da_tag(@tag).agrupados_por_cidades.no_intervalo(@data_de, @data_ate)
    @bairros = Topico.join_da_tag(@tag).agrupados_por_bairros.no_intervalo(@data_de, @data_ate)
    
    users = User.que_criaram_comentaram_ou_apoiaram_topicos(topicos).collect{ |u| u.id }
    @users = User.find(users)
  end


  verify :params => [:ambito, :tag_id],
         :only => :relatorio
  def relatorio
    if params[:ambito] == "estadual"
      @estado = Estado.find(params[:estado_id])
      relatorio_estadual
    elsif params[:ambito] == "municipal"
      @cidade = Cidade.find(params[:cidade_id], :include => :estado)
      relatorio_municipal
    else
      relatorio_nacional
    end
  end
  
  verify :params => [:de, :ate],
         :only => :definir_intervalo
  def definir_intervalo
    @cidades = Topico.agrupados_por_cidades.no_intervalo(@data_de, @data_ate)
    @estados = Topico.agrupados_por_estados.no_intervalo(@data_de, @data_ate)
    render :update do |page|
      page.replace_html 'territorio', 
                        :partial => "select_territorio", 
                        :locals => { 
                          :escolhido => false, 
                          :estados => @estados, 
                          :cidades => @cidades 
                        }
      page.replace_html 'intervalo', 
                        :partial => "select_intervalo", 
                        :locals => { 
                          :escolhido => true
                        }
      #page.alert('x!')
    end
  end

  verify :params => [:de, :ate, :ambito],
         :only => :definir_territorio
  def definir_territorio
    if (params[:ambito] == "municipal")
      @cidade = Cidade.find(params[:cidade_id], :include => :estado)
      @temas  = Topico.join_da_cidade(@cidade).agrupados_por_tags.no_intervalo(@data_de, @data_ate)
      @local  = @cidade
    elsif (params[:ambito] == "estadual")
      @estado = Estado.find(params[:estado_id])
      @temas  = Topico.join_do_estado(@estado).agrupados_por_tags.no_intervalo(@data_de, @data_ate)
      @local  = @estado
    else
      @pais   = Pais.find(1)
      @temas  = Topico.agrupados_por_tags.no_intervalo(@data_de, @data_ate)
      @local  = @pais
    end
    
    render :update do |page|
      page.replace_html 'territorio',  
                        :partial => "select_territorio", 
                        :locals => { 
                          :escolhido => true, 
                          :local => @local 
                        }
      page.replace_html 'lista_temas', 
                        :partial => "select_temas", 
                        :locals => { 
                          :temas => @temas 
                        }
      page.show 'submit_gerar'
    end
  end

  private
  
  def intervalo
    if params["de"] and params["ate"]
      @data_de  = Date.new(params["de"]["year"].to_i, params["de"]["month"].to_i, params["de"]["day"].to_i) #|| 30.days.ago
      @data_ate = Date.new(params["ate"]["year"].to_i, params["ate"]["month"].to_i, params["ate"]["day"].to_i)
    else
      @data_ate = Date.today
      @data_de  = (Date.today.day == 1) ? (Date.today - 1.day).beginning_of_month : Date.today.beginning_of_month #@data_ate - 30.days
    end
  end
  
  def relatorio_municipal
    @tags = Tag.find(params[:tag_id])
    tags_ids = @tags.map(&:id) #collect{ |tt| tt.id }
    
    @propostas = Topico.do_tipo(Proposta).join_da_cidade(@cidade).que_tem_as_tags(params[:tag_id]).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @problemas = Topico.do_tipo(Problema).join_da_cidade(@cidade).que_tem_as_tags(params[:tag_id]).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    
    @topicos     = Topico.join_da_cidade(@cidade).que_tem_as_tags(params[:tag_id]).no_intervalo(@data_de, @data_ate).find(:all, :select => "DISTINCT topicos.id, topicos.*")
    topicos_ids = @topicos.map(&:id) #collect { |t| t.id }
    
    @adesoes = Adesao.dos_topicos(topicos_ids).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @comentarios = Comentario.dos_topicos(topicos_ids).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    
    textos = ""
    Comentario.dos_topicos(topicos_ids).no_intervalo(@data_de, @data_ate).find(:all).each { |c| textos += c.body unless c.body.blank? }
    @nuvem_conceitos = Comentario.estatisticas_do_texto(textos)

    @territorios_dados = []
    territorios = Local.de_topicos.que_tem_as_tags(tags_ids).no_intervalo(@data_de, @data_ate).agrupados_por_bairros_da_cidade(@cidade).sort! {|l1, l2| l1.total.to_i <=> l2.total.to_i}
    territorios.each do |territorio|
      if territorio.bairro_id.nil? # = sem bairro definido
        tmp = Topico.join_da_cidade(@cidade).que_tem_as_tags(tags_ids).no_intervalo(@data_de, @data_ate).find(:all, :select => "DISTINCT topicos.id, topicos.*", :conditions => "locais.bairro_id IS NULL")
        dados = retorna_dados_territorio(tmp)
        atividades = dados[:topicos].size + dados[:adesoes] + dados[:comentarios]
        @territorios_dados << ["Sem bairro definido", atividades, dados]
      else
        bairro = Bairro.find(territorio.bairro_id)
        tmp = Topico.join_do_bairro(bairro).que_tem_as_tags(tags_ids).no_intervalo(@data_de, @data_ate).find(:all, :select => "DISTINCT topicos.id, topicos.*")
        dados = retorna_dados_territorio(tmp)
        atividades = dados[:topicos].size + dados[:adesoes] + dados[:comentarios]
        @territorios_dados << ["#{bairro.nome}", atividades, dados]
      end
    end
    @territorios_dados.sort!{ |t1, t2| t2[1] <=> t1[1] }
    
    users = User.que_criaram_comentaram_ou_apoiaram_topicos(@topicos).collect{ |u| u.id }
    @users = User.find(users)
    
    @topicos_mais_ativos = @topicos.sort{ |t1, t2| t1.relevancia.size <=> t2.relevancia.size }.group_by(&:type)
  end

  def relatorio_estadual
    @tags = Tag.find(params[:tag_id])
    tags_ids = @tags.map(&:id) #collect{ |tt| tt.id }
    
    @propostas = Topico.do_tipo(Proposta).join_do_estado(@estado).que_tem_as_tags(params[:tag_id]).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @problemas = Topico.do_tipo(Problema).join_do_estado(@estado).que_tem_as_tags(params[:tag_id]).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    
    @topicos     = Topico.join_do_estado(@estado).que_tem_as_tags(params[:tag_id]).no_intervalo(@data_de, @data_ate).find(:all, :select => "DISTINCT topicos.id, topicos.*")
    topicos_ids = @topicos.map(&:id) #collect { |t| t.id }
    
    @adesoes = Adesao.dos_topicos(topicos_ids).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @comentarios = Comentario.dos_topicos(topicos_ids).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    
    textos = ""
    Comentario.dos_topicos(topicos_ids).no_intervalo(@data_de, @data_ate).find(:all).each { |c| textos += c.body }
    @nuvem_conceitos = Comentario.estatisticas_do_texto(textos)

    @territorios_dados = []
    territorios = Local.de_topicos.que_tem_as_tags(tags_ids).no_intervalo(@data_de, @data_ate).agrupados_por_cidades_do_estado(@estado).sort! {|l1, l2| l1.total.to_i <=> l2.total.to_i}
    territorios.each do |territorio|
      if territorio.cidade_id.nil? # = sem cidade definida
        tmp = Topico.join_do_estado(@estado).que_tem_as_tags(tags_ids).no_intervalo(@data_de, @data_ate).find(:all, :select => "DISTINCT topicos.id, topicos.*", :conditions => "locais.cidade_id IS NULL")
        dados = retorna_dados_territorio(tmp)
        atividades = dados[:topicos].size + dados[:adesoes] + dados[:comentarios]
        @territorios_dados << ["Sem cidade definida", atividades, dados]
      else
        cidade = Cidade.find(territorio.cidade_id)
        tmp = Topico.join_da_cidade(cidade).que_tem_as_tags(tags_ids).no_intervalo(@data_de, @data_ate).find(:all, :select => "DISTINCT topicos.id, topicos.*")
        dados = retorna_dados_territorio(tmp)
        atividades = dados[:topicos].size + dados[:adesoes] + dados[:comentarios]
        @territorios_dados << ["#{cidade.nome}", atividades, dados]
      end
    end
    @territorios_dados.sort!{ |t1, t2| t2[1] <=> t1[1] }
    
    users = User.que_criaram_comentaram_ou_apoiaram_topicos(@topicos).collect{ |u| u.id }
    @users = User.find(users)
    
    @topicos_mais_ativos = @topicos.sort{ |t1, t2| t1.relevancia.size <=> t2.relevancia.size }.group_by(&:type)
  end
  
  def relatorio_nacional
    @tags = Tag.find(params[:tag_id])
    tags_ids = @tags.map(&:id) #collect{ |tt| tt.id }
    
    @propostas = Topico.do_tipo(Proposta).que_tem_as_tags(params[:tag_id]).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @problemas = Topico.do_tipo(Problema).que_tem_as_tags(params[:tag_id]).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    
    @topicos     = Topico.que_tem_as_tags(params[:tag_id]).no_intervalo(@data_de, @data_ate).find(:all, :select => "DISTINCT topicos.id, topicos.*")
    topicos_ids = @topicos.map(&:id) #collect { |t| t.id }
    
    @adesoes = Adesao.dos_topicos(topicos_ids).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    @comentarios = Comentario.dos_topicos(topicos_ids).agrupados_por_dia_de_criacao.no_intervalo(@data_de, @data_ate)
    
    textos = ""
    Comentario.dos_topicos(topicos_ids).no_intervalo(@data_de, @data_ate).find(:all).each { |c| textos += c.body if c and c.body }
    @nuvem_conceitos = Comentario.estatisticas_do_texto(textos)

    @territorios_dados = []
    territorios = Local.de_topicos.que_tem_as_tags(tags_ids).no_intervalo(@data_de, @data_ate).agrupados_por_estados_do_pais.sort! {|l1, l2| l1.total.to_i <=> l2.total.to_i}
    territorios.each do |territorio|
      if territorio.estado_id.nil? # = sem estado definido
        tmp = Topico.join_do_pais.que_tem_as_tags(tags_ids).no_intervalo(@data_de, @data_ate).find(:all, :select => "DISTINCT topicos.id, topicos.*", :conditions => "locais.estado_id IS NULL")
        dados = retorna_dados_territorio(tmp)
        atividades = dados[:topicos].size + dados[:adesoes] + dados[:comentarios]
        @territorios_dados << ["Sem estado definido", atividades, dados]
      else
        estado = Estado.find(territorio.estado_id)
        tmp = Topico.join_do_estado(estado).que_tem_as_tags(tags_ids).no_intervalo(@data_de, @data_ate).find(:all, :select => "DISTINCT topicos.id, topicos.*")
        dados = retorna_dados_territorio(tmp)
        atividades = dados[:topicos].size + dados[:adesoes] + dados[:comentarios]
        @territorios_dados << ["#{estado.nome}", atividades, dados]
      end
    end
    @territorios_dados.sort!{ |t1, t2| t2[1] <=> t1[1] }
    
    users = User.que_criaram_comentaram_ou_apoiaram_topicos(@topicos).collect{ |u| u.id }
    @users = User.find(users)
    
    @topicos_mais_ativos = @topicos.sort{ |t1, t2| t1.relevancia.size <=> t2.relevancia.size }.group_by(&:type)
  end
  
  # Dado um conjunto de Topicos, retornar as contagens de
  # Adesoes, Comentarios e Users (q aderiram e comentaram...) desses topicos
  def retorna_dados_territorio(topicos)
    users_aux = User.que_criaram_comentaram_ou_apoiaram_topicos(topicos).map(&:id)
    dados = {
      :topicos => topicos,
      :adesoes => Adesao.dos_topicos(topicos.map(&:id)).no_intervalo(@data_de, @data_ate).count(:all),
      :comentarios => Comentario.dos_topicos(topicos.map(&:id)).no_intervalo(@data_de, @data_ate).count(:all),
      :users => User.find(users_aux)
    }
    return dados
  end

end