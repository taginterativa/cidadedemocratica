class LocaisController < ApplicationController

  def escolher_uma_regiao
    render :update do |page|
      page.insert_html :top, "locais",
                       :partial => "observatorios/seletor_de_local",
                          :locals => {
                            :local => nil
                          }
    end
  end

  #========================#
  #     C I D A D E S      #
  #========================#
  # Lista todas as cidades (agrupadas por estados)
  def cidades
    @cidades = Cidade.find(:all, :include => :estado, :order => "estados.nome ASC, cidades.nome ASC")
  end
  
  # Retorna lista de <optionS>CIDADES</optionS>
  verify :params => :estado_id,
         :only => :cidades_options_for_select
  def cidades_options_for_select
    first_option = params[:first_option] ? params[:first_option] : false
    cidades = Cidade.do_estado(params[:estado_id]).find(:all, :order => "nome ASC")
    render :partial => "locais/options_for_select",
           :locals => {
             :my_collection => cidades,
             :options => {
               :first_option => first_option
             }
           }
  end
  
  # Retorna lista de SLUG !!!
  # <optionS>CIDADES</optionS>
  verify :params => :estado_id,
         :only => :cidades_li_for_ul
  def cidades_li_for_ul
    str_return = ""
    cidades = Cidade.do_estado(params[:estado_id]).find(:all, :order => "nome ASC")
    cidades.each do |cidade|
      cs = params[:cidades_selecionadas].split(",")
        if cs.include?(cidade.id.to_s)
          str_return += render_to_string :partial => "topicos/selecionar_cidades_li",
                                                  :locals => { 
                                                     :cidade => cidade,
                                                     :selecionada => true
                                                  }
        else          
          str_return += render_to_string :partial => "topicos/selecionar_cidades_li",
                                                  :locals => { 
                                                     :cidade => cidade,
                                                     :selecionada => false
                                                  }
        end
    end
    render :update do |page|
      #page.alert(params[:cidades_selecionadas])
      page.replace_html 'ul_cidades', :text => str_return
    end
  end

  # Retorna lista de SLUG !!!
  # <optionS>CIDADES</optionS>
  verify :params => :estado_id,
         :only => :cidades_options_for_select
  def cidades_slugs_options_for_select
    cidades = Cidade.do_estado(params[:estado_id]).find(:all, :order => "nome ASC")
    render :partial => "locais/options_slug_for_select",
           :locals => { 
             :my_collection => cidades,
             :options => { 
               :first_option => false
             }
           }
  end
  
  # Retorna lista de SLUG !!!
  # <optionS>CIDADES</optionS>
  verify :params => :estado_abrev,
         :only => :cidades_slugs
  def cidades_slugs
    cidades = []
    if (params[:estado_abrev].size == 2)
      estado = Estado.find(:first, 
                           :conditions => ["abrev = UPPER(?)", params[:estado_abrev]])
      cidades = estado.cidades.find(:all, 
                                    :order => "cidades.nome ASC") if estado
    end
    render :partial => "locais/cidades_slugs",
           :locals  => { :cidades => cidades }
  end

  #========================#
  #     B A I R R O S      #
  #========================#
  # Lista os bairros de uma cidade
  def bairros
    @bairros = @cidade_corrente.bairros.find(:all, :order => "nome ASC")
    render :template => "home/bairros" #:layout => "layouts/application", :partial => "home/bairros"
  end

  #protect_from_forgery :except => [:bairros_options_for_select]
  # Retorna lista de <optionS>BAIRROS</optionS>
  verify :params => :cidade_id,
         :only => :bairros_options_for_select
  def bairros_options_for_select
    bairros = Bairro.da_cidade(params[:cidade_id]).find(:all, :order => "nome ASC")
    render :partial => "locais/options_for_select",
           :locals => {
             :my_collection => bairros,
              :options => {
                :first_option => false
              }
            }
  end
  
  verify :params => :cidade_id,
         :only => :li_bairros
  def li_bairros
    bairros = Bairro.da_cidade(params[:cidade_id]).find(:all, :order => "nome ASC")
    render :partial => "locais/li_bairros_loop",
           :locals => {
             :bairros => bairros,
            }
  end

end