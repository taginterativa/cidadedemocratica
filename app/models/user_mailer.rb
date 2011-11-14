# DEPRECATED: now using config.gem - see at environment.rb
#require "text/format" 
class UserMailer < Mailer
  helper :mailer

  def signup_notification(user)
    user.reload # O código de ativação não fica correto sem esta chamada.

    @recipients  = user.email
    @from        = "Cidade Democrática <noreply@cidadedemocratica.org.br>"
    @subject     = "Falta pouco para você participar do Cidade Democrática"
    @sent_on     = Time.now

    @body[:user] = user
    @body[:url]  = "http://#{SITE_DOMAIN_FOR_LINKS}/usuario/confirmar/#{user.activation_code}"
    @body[:config] = SimpleConfig.for(:application)
  end

  def activation(user)
    setup_user(user)
    @subject    += "Boas vindas ao cidade democrática"
    @body[:url]  = "http://#{SITE_DOMAIN_FOR_LINKS}/perfil/#{user.id}"
  end
  
  def signup_last_try(user)
    user.reload # O código de ativação não fica correto sem esta chamada.

    @recipients  = user.email
    @from        = "Cidade Democrática <noreply@cidadedemocratica.org.br>"
    @subject     = "Faltou confirmar seu cadastro no Cidade Democrática"
    @sent_on     = Time.now

    @body[:user] = user
    @body[:url]  = "http://#{SITE_DOMAIN_FOR_LINKS}/usuario/confirmar/#{user.activation_code}"
    @body[:config] = SimpleConfig.for(:application)
  end

  def solicitar_vinculacao(organizacao, user)
    setup_user(organizacao)
    @subject    += "#{user.nome} quer fazer parte de #{organizacao.nome}"
    @body[:organizacao] = organizacao
    @body[:user]        = user
  end
  
  def instrucoes_reset_senha(user)
    setup_user(user)
    @subject    += "Quer mudar sua senha, #{user.nome}?"
    @body[:url]  = "http://#{SITE_DOMAIN_FOR_LINKS}/usuario/pwdrst/#{user.id_criptografado}/#{user.crypted_password}/#{user.salt}"
  end

  def observatorio(user, desde=7.days.ago)
    setup_user(user)
    #@body[:topicos] = user.observatorios.first.topico_ids
    @body[:desde] = desde
    @body[:atividades] = user.observatorios.first.atividades(desde)
    @subject    += "Resumo do observatório"
  end

  def contato(usuario_destinatario, contato)
    setup_user(usuario_destinatario)
    @body[:contato] = contato
    @subject    += "Nova mensagem de #{contato.nome.nome_proprio}"
    @reply_to = "#{contato.nome.nome_proprio} <#{contato.email}>"
  end

#  protected
#    def setup_email2user(user)
#      user.reload
#
#      config = SimpleConfig.for(:application)
#      @body[:config] = config
#
#      @recipients  = "#{user.email}"
#      @from        = "sistema@cidadedemocratica.com.br"
#      @subject     = "[Cidade Democrática] "
#      @sent_on     = Time.now
#      @body[:user] = user
#    end
end