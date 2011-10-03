class ImagensController < ApplicationController
  before_filter :obter_topico

  def index
    @imagens = @topico.imagens
  end

  def create
    if @topico.imagens.create(params[:imagem])
      flash[:notice] = "Imagem salva com sucesso."
      redirect_to :action => "index", :topico_slug => @topico.to_param
    end
  end

  def destroy
    @imagem = @topico.imagens.find(params[:id])
    if @imagem
      @imagem.destroy
      flash[:notice] = "Imagem removida com sucesso."
      redirect_to :action => "index", :topico_slug => @topico.to_param
    end
  end

  protected

  verify :params => [ :topico_slug ],
         :only => :obter_topico
  def obter_topico
    @topico = Topico.slugged_find(params[:topico_slug])
  end

end