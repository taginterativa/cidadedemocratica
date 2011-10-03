module ImagemHelper

  # Mostra o avatar do usuário, dado o obj "user":
  # se tem a imagem, mostra-a;
  # se não, imagem default.
  def avatar(user, options = {})
    options = {
      :thumbnails => :mini,
      :image_options => {
        :alt => user.nome
      },
      :image_only => false,
      :div_options => { :class => "avatar" }
    }.merge(options)

    if user.imagem
      av = image_tag(user.imagem.public_filename(options[:thumbnails]), options[:image_options])
    else
      if user.pessoa?
        av = image_tag("icones/avatares/avatar_padrao_cidadao_#{options[:thumbnails]}.png", options[:image_options]) if (user.sexo=="m")
        av = image_tag("icones/avatares/avatar_padrao_cidada_#{options[:thumbnails]}.png", options[:image_options]) if (user.sexo=="f")
      elsif user.organizacao?
        av = image_tag("icones/avatares/avatar_padrao_organizacao_#{options[:thumbnails]}.png", options[:image_options])
      else
        av = image_tag("avatar_padrao.png", options[:image_options])
      end
    end
    content = options[:image_only] ? av : content_tag(:div, link_to(av, perfil_url(:id => user.id), :title => "Veja o perfil de #{h(user.nome)}"), options[:div_options])
    return content
  end

  # Centraliza a imagem grande do usuário
  # na área da tela/foto.
  def posiciona_imagem_grande(user)
    if user.imagem and 
       user.imagem.public_filename and
       FileTest.exist?("#{RAILS_ROOT}/public#{user.imagem.public_filename}")
      # A imagem existe (está no file-system)
      # Fazer o ajuste de posicionamento dentro do DIV
      wh = ImageSize.of_file("#{RAILS_ROOT}/public#{user.imagem.public_filename}")
      w,h = wh.to_s.split("x")[0], wh.to_s.split("x")[1]
      #Agora vamos centralizar a imagem no retangulo 190x200
      dw = 0
      dw = ((w - 190)/2).to_i if (w.to_i > 190) #ponto médio horizontal
      dh = 0
      dh = ((h - 200)/2).to_i if (h.to_i > 200) #ponto médio vertica
      class_name = "imagem_grande"
      return image_tag(user.imagem.public_filename, :style => "position:relative;left:-#{dw}px;-top:#{dh}px", :class => class_name)
    else
      case user.type.to_s
        when /(Cidadao)|(GestorPublico)/
          av = image_tag("icones/default_user_female.png", :class => class_name) if (user.sexo=="f")
          av = image_tag("icones/default_user_male.png", :class => class_name)   if (user.sexo=="m")
        else
          av = image_tag("icones/default_user_organizacao.png", :class => class_name)
      end

      return av
    end
  end
end
