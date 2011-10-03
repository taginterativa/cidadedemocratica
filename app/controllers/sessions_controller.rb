# This controller handles the login/logout function of the site.  
class SessionsController < ApplicationController
  # Be sure to include AuthenticationSystem in Application Controller instead
  include AuthenticatedSystem

  protect_from_forgery :except => [ :new ]
  # render new.rhtml
  def new
    @user = User.new # Para o formulário de cadastro.

    if request.post?
      logout_keeping_session!
      user = User.authenticate(params[:login], params[:password])
      if user
        # Protects against session fixation attacks, causes request forgery
        # protection if user resubmits an earlier form using back
        # button. Uncomment if you understand the tradeoffs.
        # reset_session
        self.current_user = user
        user.historico_de_logins.create(:ip => request.remote_ip())
        new_cookie_flag = (params[:remember_me] == "1")
        handle_remember_cookie! new_cookie_flag
  
        if session[:novo_topico]
          redirect_to :controller => "topicos", :action => "create"
        elsif session[:novo_comentario]
          redirect_to :controller => "comments", :action => "create"
        elsif session[:observatorio]
          redirect_to :controller => "observatorios", :action => "index"
        elsif session[:topico]
          redirect_to :controller => "topicos", :action => "show"
        elsif session[:topico_seguir]
          redirect_to :controller => "topicos", :action => "seguir"
        elsif session[:topico_aderir]
          redirect_to :controller => "topicos", :action => "aderir"
        else
          #salvo e limpo a referencia
          url_refer = session[:url_referer] 
          session[:url_referer] = nil
          if url_refer and not url_refer.to_s.include?("reset_password")
            # Se nao passou pelos filtros usa o refer da primeira entrada no /login
            redirect_to url_refer 
          else
            # Caso nao veio pelo referer ou nao era nenhum das atividades que guarda na sessão vai para o perfil
            # Esse caso só vai ocorrer em caso de ERRO
            redirect_back_or_default(perfil_url(current_user.id))
          end
        end
      else
        note_failed_signin
        @login       = params[:login]
        @remember_me = params[:remember_me]
        @user = User.new # Para o formulário de cadastro.
        render :action => "new"
      end
    else
      # Salvando na sessao a url de origem quando ele entra pela primeira vez no login. Depois e feito o post dos dados e reutulizado essa referencia.
      session[:url_referer] = request.referer
    end
  end

  def destroy
    logout_killing_session!
    redirect_back_or_default("/")
  end

protected
  # Track failed login attempts
  def note_failed_signin
    flash[:error] = "Não foi possível fazer seu login. Redigite seu e-mail e sua senha. As senhas do Cidade Democrática distinguem maiúsculas de minúsculas."
    logger.warn "Failed login for '#{params[:login]}' from #{request.remote_ip} at #{Time.now.utc}"
  end
end