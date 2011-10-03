class TopicoMailer < Mailer

  # Notifica dono do topico
  # que houve um novo comentario.
  # def novo_comentario(topico, comentario)
  #   setup_topico(topico)
  #   # prepara_seguidores(topico, 'comentou', comentario)
  #   @subject    += "#{comentario.user.nome} comentou #{topico.nome_do_tipo(:artigo => :definido)} no CidadeDemocrática!"
  #   @body[:comentario] = comentario
  # end

  # Notifica o usuário de que há um novo comentário.
  def novo_comentario(user, topico, comment)
    setup

    @body[:user] = user
    @body[:topico] = topico
    @body[:comment] = comment

    @recipients  = "#{user.nome} <#{user.email}>"
    @subject    += "#{comment.user.nome} comentou #{topico.nome_do_tipo(:artigo => :definido)}"
  end

  # Notifica dono do topico
  # que houve uma nova adesao.
  def nova_adesao(topico, adesao)
    setup_topico(topico)
    prepara_seguidores(topico, 'apoiou', adesao)
    @subject    += "#{adesao.user.nome} apoiou #{topico.nome_do_tipo(:artigo => :definido)} no CidadeDemocrática!"
    @body[:verbo] = "apoiou"
    @body[:adesao] = adesao
  end

  # Notifica dono do topico
  # que houve uma nova adesao.
  # ATENÇÃO: ao remover um usuário da base, as adesoes sao removidas em cascata 
  #          (graças ao :dependent => :destroy); o IF abaixo evita erros nesse caso.
  def remove_adesao(topico, adesao)
    if adesao.user and topico.user
      setup_topico(topico)
      prepara_seguidores(topico, 'removeu a adesão', adesao)
      @subject    += "#{adesao.user.nome} removeu o apoio de #{topico.nome_do_tipo(:artigo => :indefinido)} no CidadeDemocrática!"
      @body[:verbo] = "deixou de apoiar"
      @body[:adesao] = adesao
    end
  end

  # Notifica dono do topico
  # o que foi divulgado.
  def status_da_divulgacao(topico)
  end

  # Envia email falando sobre o topico.
  def divulgacao(topico, de_nome, de_email, para_email, dica)
    setup_divulgacao(de_nome, de_email, para_email)
    @subject    += "#{de_nome} indicou uma questão pública para você!"

    @body[:topico] = topico
    @body[:de_nome] = de_nome
    @body[:de_email] = de_email
    @body[:dica] = dica
    @body[:url]  = "http://www.cidadedemocratica.com.br/topico/#{topico.to_param}"
  end

  def prepara_seguidores(topico, verbo, objeto)
    if topico.usuarios_que_seguem.size > 0
      topico.usuarios_que_seguem.each do |u|
        #lista_emails << u.email
        TopicoMailer.deliver_envia_seguidor(topico, verbo, objeto, u)
      end
    end
  end

  def envia_seguidor(topico, verbo, objeto, seguidor)
    setup_seguidor(topico, seguidor)   
    @subject    += "Nova atividade de #{topico.nome_do_tipo(:artigo => :indefinido)} no CidadeDemocrática!"
    @body[:verbo] = verbo
    @body[:objeto] = objeto
    @body[:seguidor] = seguidor
  end
end