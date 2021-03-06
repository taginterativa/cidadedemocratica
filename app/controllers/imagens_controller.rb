class ImagensController < ApplicationController
  before_filter :obter_topico

  def index
    @imagens = @topico.imagens
  end

  def create
    imagem = @topico.imagens.create(params[:imagem])
    if imagem
        image_in = "#{RAILS_ROOT}/public#{imagem.public_filename}"
        # Refazendo thumb, small e mini
        sizes = {:thumb => '75x75', :small => '50x50', :mini => '30x30'}
        sizes.each do |k,v|
          system "convert -resize #{v} #{image_in} #{RAILS_ROOT}/public/#{imagem.public_filename(k)}"
        end
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
