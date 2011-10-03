class AvatarController < ApplicationController
  before_filter :login_required

  # O usuário tem permissão para editar o avatar?
  include UserPermissions
  before_filter :tem_permissao_para_editar

  def new
    @user = current_user
    @imagem = Imagem.new
  end

  def create
    @user = current_user
    if @user.imagem
      imagem = @user.imagem
      imagem.destroy
    end
    @user.reload
    if @user.imagens.create(params[:imagem])
      flash[:notice] = "Imagem salva com sucesso."
      session[:can_resize] = 1
      redirect_to :action => "resize"
    end
  end

  verify :session => :can_resize,
         :only => :resize         
  def resize
    @user = current_user
    if @user.imagem # and TODO: image_size > 190x190...
      if request.post? and
         params[:x1] and params[:y1] and params[:width] and params[:height]
        #taken from: http://groups.google.com/group/javascript-image-cropper-ui/browse_thread/thread/99dd2c186006539d
        image_in = "#{RAILS_ROOT}/public#{@user.imagem.public_filename}"
        # Refazendo thumb, small e mini
        doit  = "convert -crop #{params[:width]}x#{params[:height]}+#{params[:x1]}+#{params[:y1]} #{image_in} +repage -strip #{image_in}"
        doit2 = "convert -resize 75x75 #{image_in} #{RAILS_ROOT}/public/#{@user.imagem.public_filename(:thumb)}"
        doit3 = "convert -resize 50x50 #{image_in} #{RAILS_ROOT}/public/#{@user.imagem.public_filename(:small)}"
        doit4 = "convert -resize 30x30 #{image_in} #{RAILS_ROOT}/public/#{@user.imagem.public_filename(:mini)}"
        system doit
        system doit2
        system doit3
        system doit4
        session[:can_resize] = nil
        redirect_to :controller => "users", :action => "show", :id => @user.id
      end
    else
      redirect_to :controller => "users", :action => "show", :id => @user.id
    end
  end

  def destroy
    @user = current_user
    @imagem = @user.imagem
    if @imagem
      @imagem.destroy
      flash[:notice] = "Imagem removida com sucesso."
      redirect_to :controller => "users", :action => "show", :id => @user.id
    end
  end

end