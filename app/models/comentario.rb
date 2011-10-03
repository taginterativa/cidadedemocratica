class Comentario < Comment
  #=============================================================#
  #                    NAMED Scopes                             #
  #=============================================================#
  named_scope :de_user_ativo, 
              :include => [:user], 
              :conditions => ["users.state = 'active'"]
  named_scope :dos_topicos, lambda { |topico_ids|
    if topico_ids.nil?
      { }
    else 
      { 
        :conditions => [ "commentable_type = 'Topico' AND commentable_id IN (?)", topico_ids ] 
      }
    end
  }
  named_scope :no_intervalo, lambda { |data_de, data_ate|
    if data_de and data_ate and data_de.kind_of?(Date) and data_ate.kind_of?(Date)
      {
        :conditions => "DATE(comments.created_at) >= '#{data_de.strftime('%Y-%m-%d')}' AND DATE(comments.created_at) <= '#{data_ate.strftime('%Y-%m-%d')}'"
      }
    else
      {}
    end
  }
  named_scope :agrupados_por_dia_de_criacao, 
  {
    :select => "count(*) AS total, DATE(comments.created_at) AS dia",
    :group  => "DAY(comments.created_at), MONTH(comments.created_at), YEAR(comments.created_at)"
  }
  named_scope :agrupados_por_tipo, 
  {
    :select => "count(*) AS total, comments.tipo",
    :group  => "comments.tipo"
  }
  
  
  def self.estatisticas_do_texto(texto)
    palavras = []
    texto.split(' ').each do |word|
      w = word.downcase.gsub(/\.|\,|\?|\!|\(|\)|\'/,'')
      palavras << w
    end
    palavras.sort!
    contador = {}
    palavras.each do |p|
      if contador.has_key?(p)
        contador[p] += 1
      else
        contador.merge!(p => 1)
      end
    end
    return contador
  end
    
end