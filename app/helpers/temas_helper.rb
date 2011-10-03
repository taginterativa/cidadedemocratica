module TemasHelper

  def select_tema_para_topico
    temas = Array.new
    Tema.find(:all, :conditions => [ "parent_id IS NULL" ], :order => "nome ASC").each do |t|
      temas << "<option class=\"tema\" value=\"#{t.id}\">#{t.nome}</option>"
      if !t.children.empty?
        t.children.each do |s|
          temas << "<option class=\"subtema\" value=\"#{s.id}\">--- #{s.nome}</option>"
        end
      end
    end
    select_tag("topico[tema_ids][]", temas.join("\n"), :id => "")
  end

end