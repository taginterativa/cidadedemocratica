class BugigangasController < ApplicationController
  before_filter :login_required, :except => [ :index, :novoNingApps, :criarNingApps, :verificaNingApps ]
  
  
  def index
  end

  def novoNingApps
    
    
    render :layout => false
  end

  def criarNingApps

    render :layout => false
  end
  
  def verificaNingApps

    render :layout => false
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
        @script_cidade << '<a href="' + topico_url(@local.cidade.slug) + '" target="_blank"><img src="http://cidadedemocratica.org.br/images/selo_melhore-' + tamanho + '.gif"></a>'

        #monta banner secundário
        case tipo
          when "tema"
              @script_cidade << '<a href="' + temas_url() + '" target="_blank"><img src="http://cidadedemocratica.org.br/images/selo_temas-' + tamanho + '.gif"></a>'
              # Monta os ultimos 5 itens da cidade
          when "proposta"
              @script_cidade << '<a href="' + nova_proposta_url("proposta") + '" target="_blank"><img src="http://cidadedemocratica.org.br/images/selo_proposta-' + tamanho + '.gif"></a>'
          when "problema"
              @script_cidade << '<a href="' + novo_topico_url("problema") + '" target="_blank"><img src="http://cidadedemocratica.org.br/images/selo_problema-' + tamanho + '.gif"></a>'          
        end        
        @script_cidade << '</p>'
      end
  end

  def ning
  end

  def bugiganga

    #Parametros para configurar: Quantidade de Itens a mostrar
    @rss = perfil_url(current_user) + '.rss'
    @itens = '3'

    # Setup e mostrar o demo
    if request.post? or request.put?
      @itens = params[:itens]
    end
    
    @script = '<script type="text/javascript" src="http://'+ request.headers["host"] +'/bugigangas/widget?rss='+ @rss +'&size='+ @itens +'"></script>'
		
  end

  def widget
    #recebe a url a processar
    url = params[:rss]
    size = params[:size]
    if size == nil or size.empty?
      size = '5'
    end
    
    #faz o download do conteudo
    require 'net/http'
    req = Net::HTTP.get_response(URI.parse(url))
    if req.class != Net::HTTPSuccess and req.class != Net::HTTPRedirection and req.class != Net::HTTPOK
      #puts 'erro ao conectar com o delicious :: url :: ' + url
      render :text => "Erro ao acessar o RSS"
    else
      #processa os itens e escreve ele de forma padronizada usando o view e function() document.write      
      require 'hpricot'
      
      page = Hpricot::XML(req.body)
      @title = page.search( "//channel" ).first.search( "//title" ).first.inner_html 
      @link = page.search( "//channel" ).first.search( "//item" ).first.search( "//guid" ).first.inner_html 
      
      @itens = Array.new 
      puts Benchmark.measure {
        doc, statuses = Hpricot::XML(req.body), []
        (doc/:item).each do |s|
        entry = Array.new
          %w[title description author pubDate link guid].each do |a|
            entry << s.at('title').inner_text
            entry << s.at('description').inner_text
            entry << s.at('author').inner_text
            entry << s.at('pubDate').inner_text
            entry << s.at('link').innerHTML
            entry << s.at('guid').innerHTML
         end
         @itens << entry
          #statuses << h
        end
        # pp statuses
      }
      
      respond_to do |wants|
        wants.js do 
          @itens = @itens[0..size.to_i-1]
          render :layout => false
        end
      end
    end
  end  

end