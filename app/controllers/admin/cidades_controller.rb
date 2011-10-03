class Admin::CidadesController < Admin::AdminController
  # GET /cidades
  # GET /cidades.xml
  def index
    @cidades = Cidade.do_estado(params[:estado_id]).com_nome(params[:busca_nome]).paginate(:per_page => 50, :page => params[:page], :include => :estado, :order => "cidades.nome ASC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @cidades }
    end
  end

  # GET /cidades/1
  # GET /cidades/1.xml
  def show
    @cidade = Cidade.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @cidade }
    end
  end

  # GET /cidades/new
  # GET /cidades/new.xml
  def new
    @cidade = Cidade.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @cidade }
    end
  end

  # GET /cidades/1/edit
  def edit
    @cidade = Cidade.find(params[:id])
  end

  # POST /cidades
  # POST /cidades.xml
  def create
    @cidade = Cidade.new(params[:cidade])

    respond_to do |format|
      if @cidade.save
        flash[:notice] = "Cidade criada com sucesso."
        format.html { redirect_to(admin_cidades_path) }
        format.xml  { render :xml => @cidade, :status => :created, :location => @cidade }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @cidade.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /cidades/1
  # PUT /cidades/1.xml
  def update
    @cidade = Cidade.find(params[:id])

    respond_to do |format|
      if @cidade.update_attributes(params[:cidade])
        flash[:notice] = "Cidade atualizada com sucesso."
        format.html { redirect_to(admin_cidades_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @cidade.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /cidades/1
  # DELETE /cidades/1.xml
  def destroy
    @cidade = Cidade.find(params[:id])
    @cidade.destroy

    respond_to do |format|
      format.html { redirect_to(admin_cidades_path) }
      format.xml  { head :ok }
    end
  end
  
  # GET
  def maisbairros
    @cidade = Cidade.find(params[:id])
  end
  
  # POST
  def novosbairros
    @cidade = Cidade.find(params[:id])
    params[:nomes_dos_bairros].strip.split("\n").each do |b|
      @cidade.bairros.create(:nome => b.strip)
    end
    
    flash[:notice] = "Bairros criados com sucesso!"
    respond_to do |format|
      format.html { redirect_to(admin_cidades_path) }
      format.xml  { head :ok }
    end
  end
end