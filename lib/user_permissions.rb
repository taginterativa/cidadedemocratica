module UserPermissions

  protected

  def tem_permissao_para_editar
    # if logged_in?
    #   if @user != current_user
    #     redirect_to perfil_url(:id => @user.id) and return false
    #   end
    # else
    #   redirect_to login_url
    # end
    return true
  end

end