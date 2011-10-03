class AdesaoObserver < ActiveRecord::Observer
  def after_create(adesao)
    adesao.topico.atualiza_contadores
    adesao.user.atualiza_contadores
    TopicoMailer.deliver_nova_adesao(adesao.topico, adesao) if adesao.user.active?
  end

  def after_destroy(adesao)
    adesao.topico.atualiza_contadores if adesao and adesao.topico
    adesao.user.atualiza_contadores if adesao and adesao.user
    # Comentei: achei desnecessario ficar avisando q fulano nao mais apoia...
    # Atencao! Verificar erro q esse metodo (quando em uso...) CAUSA na remocao do usuario!
    # TopicoMailer.deliver_remove_adesao(adesao.topico, adesao) if adesao.user.active?
  end
end