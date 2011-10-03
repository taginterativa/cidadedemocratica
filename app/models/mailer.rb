class Mailer < ActionMailer::Base
  helper :application
  SITE_DOMAIN_FOR_LINKS = "www.cidadedemocratica.org.br"
  SITE_DOMAIN_FOR_LINKS = "200.207.40.205:9999" if (RAILS_ENV == 'development')
  ADMIN_NAME_AND_EMAIL  = "Administrador do Cidade Democrática <ryband@uol.com.br>"

  protected

  # Padrao de email para usuarios.
  def setup_user(user)
    user.reload
    if user and user.nome
      setup_default("#{user.nome} <#{user.email}>")
    else
      setup_default(user.email)
    end
    @body[:user] = user
  end

  # Padrao de email sobre topicos.
  # Notifica o criador do topico.
  def setup_topico(topico)
    topico.reload
    setup_default("#{topico.user.nome} <#{topico.user.email}>")
    @body[:topico] = topico
  end

  # Email para divulgar o topico.
  def setup_divulgacao(de_nome, de_email, para_email)
    # OLD CODE... dá pau de SPF se o email do remetendo não for o nosso...
    # setup_default("#{para_email}", "#{de_nome} <#{de_email}>")
    setup_default("#{para_email}")
    @reply_to = "#{de_nome} <#{de_email}>"
  end

  def setup_admin
    str_email_admin = (Settings['emails_administrador'] and not Settings['emails_administrador'].blank?) ? Settings['emails_administrador'] : ADMIN_NAME_AND_EMAIL
    setup_default(str_email_admin)
  end
  
  # Configura os seguidores do tópico para receberem o email tambem
  def setup_seguidores(topico)
    if topico.usuarios_que_seguem.size > 0
      lista_emails = Array.new
      topico.usuarios_que_seguem.each do |u|
        lista_emails << u.email
      end
      @bcc = lista_emails
    end
  end
  
  #Setup de seguidor
  def setup_seguidor(topico, seguidor)
    topico.reload
    setup_default("#{seguidor.nome} <#{seguidor.email}>")
    @body[:topico] = topico
  end

  private

  # Padrao de email do Cidade Democratica
  def setup_default(recipients, from = nil)
    @recipients  = recipients
    setup
  end

  def setup
    @body[:config] = SimpleConfig.for(:application)
    @from        = from || "Cidade Democrática <noreply@cidadedemocratica.org.br>"
    @subject     = "[Cidade Democrática] " #inicio padrao dos emails
    @sent_on     = Time.now
  end

end