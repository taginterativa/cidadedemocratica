class Tema < Tag
  
  # Dada uma tag, retornar todos os users que jah utilizaram-na
  def users
    u = []
    Topico.find_tagged_with(self).each{ |t| u << t.user }
    return u
  end
  
  # Atualizacoes dos contadores
  def atualiza_contadores
    topicos_count = 0
    topicos_count = Topico.com_tag(self).count(:all)

    topicos_relevancias_sum = 0
    topicos = Topico.com_tag(self).find(:all)
    topicos.each { |t| topicos_relevancias_sum += t.relevancia }

    users_count = 0
    users_count = self.users.size
    
    users_relevancias_sum = 0
    self.users.each { |u| users_relevancias_sum += u.relevancia }
    
    self.relevancia = (eval(Settings.tag_formula_relevancia)).to_i
    self.save(false)
  end
  
end