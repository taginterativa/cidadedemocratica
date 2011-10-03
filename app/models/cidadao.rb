class Cidadao < User
  delegate :sexo, :to => :dado
  
  def descricao_basica
    if (self.dado.sexo=="m")
      str = "Homem, "
    else
      str = "Mulher, "
    end
    str += "#{self.dado.idade} anos"
    return str
  end

  def nome_do_tipo
    (self.dado and self.dado.sexo == "f") ? "Cidadã" : "Cidadão"
  end

  def nome_da_classe
    "cidadao"
  end
end