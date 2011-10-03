module WhereIsTheUser
  protected

  # Se usuário navega via "/params[:cidade]/etc." na URL,
  # usar a @cidade_corrente ditados pela URL
  #
  # Se não houver params[:cidade] na URL, verificar se há
  # cookie[:cidade_corrente]. Se usá-la
  #
  # Se não houver nem params, nem cookie...
  # define sao-paulo como "cidade inicial"
  # e guarna no cookie do usuário, no bom sentido...
  def define_cidade_corrente
    if params[:cidade_slug]
      begin
        @cidade_corrente = Cidade.slugged_find(params[:cidade_slug], :include => [:estado])
      rescue ActiveRecord::RecordNotFound
        redirect_to root_url and return false
      end
    elsif cookies[:cidade_corrente]
      begin
        @cidade_corrente = Cidade.slugged_find(cookies[:cidade_corrente], :include => [:estado])
      rescue ActiveRecord::RecordNotFound
        redirect_to root_url and return false
      end
    else
      @cidade_corrente = Cidade.slugged_find('sao-paulo') # if !(controller_name == 'home' and action_name == 'index')
    end
    # Guarda o cookie com a slug da cidade
    cookies[:cidade_corrente] = @cidade_corrente.slug if @cidade_corrente
  end

#  def guardar_area_definida
#    cookies[:cidade_corrente] = @cidade_corrente.slug if @cidade_corrente
#  end
end