module GraficosHelper
#---------------------------------------------------#
#        Graficos IMAGENS estáticas = GEM           #
#---------------------------------------------------#

  # Recebe um obj = ARRAY do tipo [ [data, total], [data, total], ... ]
  # Retorna um gráfico tipo LINE, colocando em X as datas e em Y os totais.
  def mostra_grafico_no_tempo_de(obj, my_options = {})
    options = {
      :width => 400,
      :height => 150,
      :title => "",
      :line_colors => "3333FF",
      :axis_with_labels => false,
      :axis_labels => false
    }.merge!(my_options)
  
    # Define os marcadores (as datas!) no eixo X
    define_valores_eixo_x(obj, options)
  
    # Define os valores do eixo Y
    aux = []
    obj.each {|r| aux << r[:total].to_i }
    if eixo_y = define_valores_eixo_y(aux)
      if options[:axis_with_labels] and options[:axis_labels]
        options[:axis_with_labels] << 'y'
        options[:axis_labels] << eixo_y
      else
        options[:axis_with_labels] = ['y']
        options[:axis_labels] = [eixo_y]
      end
    end
  
    Gchart.line(:data => [aux], 
                :size => "#{options[:width]}x#{options[:height]}",
                :title => options[:title],
                :axis_with_labels => options[:axis_with_labels],
                :axis_labels => options[:axis_labels],
                :line_colors => options[:line_colors],
                :format => 'image_tag')
  end

  # Recebe um obj = ARRAY do tipo [ [nome_fatia, total], [nome_fatia, total], ... ]
  # Retorna um gráfico tipo PIE, mostrando o percentual representado pela fatia no total.
  def mostra_grafico_pizza(obj, my_options = {})
    options = {
      :key => ":total",
      :width => 400,
      :height => 150,
      :title => "",
      :line_colors => "",
      :show_legend => true
    }.merge!(my_options)
    
    total = 0
    obj.each { |r| total += r[:total].to_i }
    aux = [[],[],[]]
    obj.each do |r|
      srand
      percentage = number_to_percentage(100 * r[:total].to_i / total, :precision => 1)
    
      # A fatia receberá qual etiqueta/nome?
      if options[:klass] and (options[:key].to_s == "id")
        tmp = options[:klass].find(r[:id])
        obj_row_name = tmp[options[:label]]
      else
        obj_row_name = r[options[:key]]
      end
    
      # Setup values for chart...
      aux[0] << r[:total].to_i
      aux[1] << "#{obj_row_name}: #{r[:total]}"
      aux[2] << "#{((rand(239))+15).to_s(16)}#{((rand(239))+15).to_s(16)}#{((rand(239))+15).to_s(16)}"
    end
  
    cores = options[:line_colors].blank? ? "#{aux[2].join(',')}" : options[:line_colors]
    legenda = options[:show_legend] ? aux[1] : ""
    Gchart.pie(:data => [ aux[0] ],
               :size => "#{options[:width]}x#{options[:height]}",
               :title => options[:title],
               :line_colors => cores,
               :legend => legenda,
               :format => 'image_tag')
  end

  def define_valores_eixo_y(arr)
    #arr.sort!
    dif = arr.max - arr.min
    return false if dif <= 0
    return [0,1] if dif <= 1
    if dif > 10
      umq = ((arr.max + arr.min)/5).to_i
      return [arr.min, umq, 2*umq, 3*umq, 4*umq, arr.max]      
    elsif (dif > 3) and (dif < 10)
      umt = ((arr.max + arr.min)/3).to_i
      return [arr.min, umt, 2*umt, arr.max]
    else
      med = ((arr.max + arr.min)/2).to_i
      return [arr.min, med, arr.max]
    end
  end
  
  def define_valores_eixo_x(obj, options = {})
    eixo_x1 = []
    eixo_x2 = []
    if obj and obj.first and obj.first[:dia] and obj.last[:dia]
      inicio = obj.first[:dia].to_date
      fim    = obj.last[:dia].to_date
      dif    = fim - inicio
      intervalos = 10 if dif.to_i > 10
      intervalos = 5  if dif.to_i <= 10
      dias = dif/intervalos
      inseriu_ano = false
      0.upto(intervalos) do |i| 
        eixo_x1 << (inicio + (i * dias)).strftime("%d%b")
        eixo_x2 << (inicio + (i * dias)).strftime("%Y") if !inseriu_ano
        inseriu_ano = true
      end
      options[:axis_with_labels] = ['x', 'x']
      options[:axis_labels] = [eixo_x1, eixo_x2]
    end
  end
  
#---------------------------------------------------#
#   Graficos interativos = Google visualization     #
#---------------------------------------------------#

  # Retorna uma string com DIV (class=grid_12) contendo:
  # - javascript que seta vars do grafico (googlecode)
  # - titulo H3 com o título e o valor total acumulado
  # - DIV com id para grafico ser desenhado dentro
  def drawLineGraph(de, ate, array, my_options = {})
    srand()
    options = {
      :div_id => "#{rand(99999)}",
      :titulo_h3 => "Título padrão"
    }.merge!(my_options)
    
    my_array= ajusta_dias_faltantes_com_zero(de, ate, array)
    graph, total = lineGraphScript(de, ate, my_array, options)
    
    valor  = content_tag(:span, total, :class => "valor")
    titulo = content_tag(:h3, "#{options[:titulo_h3]}: #{valor}")
    
    str    = graph + titulo + content_tag(:div, "Gráfico #{options[:div_id]}", :id => "graph_#{options[:div_id]}")
    return content_tag(:div, str, :class => "grid_12 alpha omega")
  end
  
  def lineGraphScript(de, ate, array, my_options = {})
    options = {
      :width => 600,
      :height => 300,
      :legend => 'bottom'
    }.merge!(my_options)
    excluir = [ :div_id, :titulo_h3, :data_name ]
        
    str  = ""
    str += "<script type=\"text/javascript\" charset=\"utf-8\">\n"
    content_for :loading_charts do
      setup_special_initialize(options[:div_id])
    end
    tmp_data  = "data_#{options[:div_id]}"
    tmp_chart = "chart_#{options[:div_id]}"
    str += "function drawLineChart(my_div_id) {\n"
    str += "\tvar #{tmp_data} = new google.visualization.DataTable();\n"
    str += "\t#{tmp_data}.addColumn('string', 'Dias');\n"
    str += "\t#{tmp_data}.addColumn('number', '#{options[:data_name]}');\n"
    str += "\t#{tmp_data}.addRows(#{(ate - de).to_i + 1});\n"
    
    total = 0
    0.upto(array.size-1) do |j|
      str += "\t\t#{tmp_data}.setValue(#{j}, 0, '#{array[j].dia.to_time.strftime('%d %b%Y')}');\n"
      str += "\t\t#{tmp_data}.setValue(#{j}, 1, #{array[j].total.to_i});\n"
      total += array[j].total.to_i
    end
    str += "\tvar #{tmp_chart} = new google.visualization.LineChart(document.getElementById('graph_#{options[:div_id]}'));\n"
    google_options = options.delete_if { |key, value| excluir.include?(key) }
    str += "\t#{tmp_chart}.draw(#{tmp_data}, #{google_options.to_json});\n"
    str += "}\n"
    str += "</script>"
    
    return [str, total]
  end
  
  def setup_special_initialize(div_id)
    str  = ""
    str += "\tsetTimeout(\"drawLineChart('graph_#{div_id}')\", 2000);\n"
    return str
  end  
end
