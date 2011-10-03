class AdminMailer < Mailer

  # Notifica admin que a ENTIDADE (= ong, empresa etc.)
  # solicitou um cadastro especial
  def pedido_cadastro_entidade(solicitante)
    setup_admin
    @subject    += "#{solicitante[:nome]} solicitou um cadastro de \"#{solicitante[:entidade]}\" no Cidade Democrática!"
    @reply_to = "#{solicitante[:nome]} <#{solicitante[:email]}>"
    @body[:solicitante] = solicitante
  end
  
  def denuncia_em_topico(topico, denuncia)
    setup_admin
    @subject    += "#{denuncia[:nome]} denunciou algo em \"#{topico.titulo}\" no Cidade Democrática!"
    @reply_to = "#{denuncia[:nome]} <#{denuncia[:email]}>"
    @body[:topico] = topico
    @body[:denuncia] = denuncia
  end

end