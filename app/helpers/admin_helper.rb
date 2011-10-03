module AdminHelper
  
  def ajusta_dias_faltantes_com_zero(de, ate, my_array)
    # 1o. Ordena o vetor por data!
    my_array.sort! { |x, y| x.dia.to_date <=> y.dia.to_date }
    
    # 2o. Percorre da data X até a data Y, dia a dia (dia = D), todos os dias
    i = 0 # 3o. Marca onde estamos no vetor de datas+totais
    inseriu = false
    de.to_date.upto(ate.to_date) do |d|
      # Quando coincidirem D == vetor[data], avanca o marcador de onde estamos
      if my_array[i] and (my_array[i].dia.to_date == d)
        i += 1
      else # Quando nao coincidirem, adiciona [dia = D, total = 0] no vetor
        if my_array.first
          tmp = my_array.first.clone
          tmp.dia = d
          tmp.total = 0
          my_array << tmp
          inseriu = true
        end
      end
    end
    # Reordena o vetor, caso tenha havido inserção.
    if inseriu
      return my_array.sort! { |x, y| x.dia.to_date <=> y.dia.to_date }
    else
      return my_array
    end
  end
  
  # Dados dois arrays (ex.: propostas e problemas)
  # calcula os totais de cada um e retorna o TOTAL
  # do primeiro, com o devido percentual.
  def calcula_total(primeiro, segundo)
    tot1 = 0
    primeiro.each{ |t| tot1 += t.total.to_i }
    tot2 = 0
    segundo.each{ |t| tot2 += t.total.to_i }
    totais = (tot1+tot2)
    percentage = (totais > 0) ? (100*tot1/totais) : 0
    return "#{tot1} (#{number_to_percentage(percentage, :precision => 0 )}) "
  end

  def descreve_total_participacoes_nacionais(la, user_id)
    tmp = 0
    la.group_by(&:estado_id).each do |grupo, array|
      tmp += array.size if grupo.nil?
    end
    return content_tag(:p, "<b>Nacional: #{tmp}</b>", :style => "margin:0")
  end

  def descreve_total_participacoes_estaduais(la, user_id)
    tmp = 0
    str = ""
    la.group_by(&:estado_id).each do |grupo, array|
      unless grupo.nil?
        str += "#{Estado.find(grupo).abrev}: #{array.size} <br />"
        tmp += array.size
      end
    end
    div_detalhe  = content_tag(:div, str, :id => "detalhe_estadual_#{user_id}", :style => "display:none;margin-left:30px")
    mais_detalhe = link_to_function("[+]", "$('detalhe_estadual_#{user_id}').toggle()") + div_detalhe
    return content_tag(:p, "<b>Estadual: #{tmp}</b> #{mais_detalhe}", :style => "margin:0")
  end

  def descreve_total_participacoes_municipais(la, user_id)
    tmp = 0
    str = ""
    la.group_by(&:cidade_id).each do |grupo, array|
      unless grupo.nil?
        tmp += array.size
        str += "#{Cidade.find(grupo).nome}: #{array.size} <br />"
      end
    end
    div_detalhe  = content_tag(:div, str, :id => "detalhe_municipal_#{user_id}", :style => "display:none;margin-left:30px")
    mais_detalhe = link_to_function("[+]", "$('detalhe_municipal_#{user_id}').toggle()") + div_detalhe
    return content_tag(:p, "<b>Municipal: #{tmp}</b> #{mais_detalhe}", :style => "margin:0")
  end

  def descreve_total_participacoes_locais(la, user_id)
    tmp = 0
    str = ""
    la.group_by(&:bairro_id).each do |grupo, array|
      unless grupo.nil?
        tmp += array.size
        str += "#{Bairro.find(grupo).nome}: #{array.size} <br />"
      end
    end
    div_detalhe  = content_tag(:div, str, :id => "detalhe_local_#{user_id}", :style => "display:none;margin-left:30px")
    mais_detalhe = link_to_function("[+]", "$('detalhe_local_#{user_id}').toggle()") + div_detalhe
    return content_tag(:p, "<b>Local: #{tmp}</b> #{mais_detalhe}", :style => "margin:0")
  end
  
  # Dados vetores de atividades (prop, probl, coment...),
  # retornar um vetor de atividades gerais
  def soma_atividades(de, ate, propostas, problemas, adesoes, comentarios)
    pp = ajusta_dias_faltantes_com_zero(de, ate, propostas)
    pb = ajusta_dias_faltantes_com_zero(de, ate, problemas)
    a = ajusta_dias_faltantes_com_zero(de, ate, adesoes)
    c = ajusta_dias_faltantes_com_zero(de, ate, comentarios)
    i = 0
    inseriu = false
    tmp = []
    de.to_date.upto(ate.to_date) do |d|
      soma = 0
      soma += pp[i].total.to_i if pp[i] and pp[i].total
      soma += pb[i].total.to_i if pb[i] and pb[i].total
      soma += a[i].total.to_i if a[i] and a[i].total
      soma += c[i].total.to_i if c[i] and c[i].total
      tmp[i] = { :dia => d, :total => soma }
      i += 1
    end
    return tmp
  end
  
end
