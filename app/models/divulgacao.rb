class Divulgacao
  include Validateable
  attr_accessor :de_nome,
                :de_email,
                :para_emails,
                :emails,
                :dica

  validates_presence_of :de_nome, :de_email
  validates_format_of :de_email,
                      :with => /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/,
                      :message => "Digite seu e-mail corretamente"

  def initialize(attributes)
    self.de_nome = attributes[:de_nome] if attributes[:de_nome]
    self.de_email = attributes[:de_email] if attributes[:de_email]
    self.para_emails = attributes[:para_emails] if attributes[:para_emails]
    self.emails = (attributes[:para_emails] and not attributes[:para_emails].blank?) ? attributes[:para_emails].gsub(" ", "").gsub("\r", "").split(/ |\,|\n/) : nil
    self.dica = attributes[:dica] if attributes[:dica]
  end

  protected
  
  def validate
    #errors.add_on_empty %w( indicador_nome indicador_email )
    #errors.add("indicador_email", "E-mail inválido") unless self.indicador_email =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
    errors.add("para_emails", "A lista tem e-mails inválidos, corrija-os") unless emails_validos
  end
  
  # Verifica se a lista de e-mails fornecida para indicar o site é
  # válida.
  def emails_validos
    validos = true
    if self.emails.nil?
      validos = false
    elsif self.emails.empty? or self.emails.blank?
      validos = false
    else
      self.emails.each do |e|
        validos = false if !email_valido(e)
      end
    end
    return validos
  end

  def email_valido(email)
    return email =~ /^[a-zA-Z][\w\.-]*[a-zA-Z0-9]@[a-zA-Z0-9][\w\.-]*[a-zA-Z0-9]\.[a-zA-Z][a-zA-Z\.]*[a-zA-Z]$/
  end
end