class Contato < Tableless
  column :nome, :string
  column :email, :string
  column :mensagem, :text

  validates_presence_of :nome
  validates_presence_of :email
  validates_presence_of :mensagem
  validates_format_of :email,
                      :with => /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/

  def enviar(usuario_destinatario, contato)
    UserMailer.deliver_contato(usuario_destinatario, contato)
  end
end