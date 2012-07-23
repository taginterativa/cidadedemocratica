# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all
  helperful :title

  # See ActionController::RequestForgeryProtection for details
  # Uncomment the :secret if you're not using the cookie session store
  protect_from_forgery

  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem

  # The Exception Notifier plugin provides a mailer object and a default set
  # of templates for sending email notifications when errors occur in a Rails
  # application.
  include ExceptionNotifiable

  # See ActionController::Base for details
  # Uncomment this to filter the contents of submitted sensitive data parameters
  # from your application log (in this case, all fields with names like "password").
  filter_parameter_logging :password

  # Métodos exclusivos da cidade/área corrente
  # include WhereIsTheUser
  # before_filter :define_cidade_corrente

  # Mantém o desenvolvimento seguro e livre de indexadores.
  before_filter :get_settings

  def obter_localizacao
    @pais = Pais.find(1)

    if !params[:estado_abrev].blank?
      if Estado.exists?(:abrev => params[:estado_abrev])
        @estado = Estado.find_by_abrev(params[:estado_abrev])
        if !params[:cidade_slug].blank?
          if @estado.cidades.exists?(:slug => params[:cidade_slug])
            @cidade = @estado.cidades.find_by_slug(params[:cidade_slug])
            if !params[:bairro_id].blank?
              if @cidade.bairros.exists?(params[:bairro_id])
                @bairro = @cidade.bairros.find_by_id(params[:bairro_id])
              else
                logger.info("  \e[1;31m404: Nao existe bairro com ID = #{params[:bairro_id]}.\e[0m")
                render :file => "#{RAILS_ROOT}/public/404.html", :layout => false, :status => 404 and return
              end
            end
          else
            logger.info("  \e[1;31m404: Nao existe cidade com slug \"#{params[:cidade_slug]}\" no estado de #{@estado.nome.remover_acentos}.\e[0m")
            render :file => "#{RAILS_ROOT}/public/404.html", :layout => false, :status => 404 and return
          end
        end
      else
        logger.info("  \e[1;31m404: Nao existe estado com abreviacao \"#{params[:estado_abrev]}\".\e[0m")
        render :file => "#{RAILS_ROOT}/public/404.html", :layout => false, :status => 404 and return
      end
    end
  end

  private
  
  helper_method :ambiente_producao?
  def ambiente_producao?
    (RAILS_ENV=='production')
  end
  
  def get_settings
    @settings = Settings.all
  end
end
