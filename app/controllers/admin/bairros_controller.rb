class Admin::BairrosController < Admin::AdminController
  # GET /bairros
  # GET /bairros.xml
  def index
    @cidade  = Cidade.find(params[:cidade_id], :include => [:estado]) if (params[:cidade_id] and not params[:cidade].blank?)
    @bairros = Bairro.da_cidade(params[:cidade_id]).com_nome(params[:busca_nome]).paginate(:per_page => 50, :page => params[:page], :include => :cidade, :order => "bairros.nome ASC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @bairros }
    end
  end

  # GET /bairros/1
  # GET /bairros/1.xml
  def show
    @bairro = Bairro.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @bairro }
    end
  end

  # GET /bairros/new
  # GET /bairros/new.xml
  def new
    @bairro = Bairro.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @bairro }
    end
  end

  # GET /bairros/1/edit
  def edit
    @bairro = Bairro.find(params[:id])
  end

  # POST /bairros
  # POST /bairros.xml
  def create
    @bairro = Bairro.new(params[:bairro])

    respond_to do |format|
      if @bairro.save
        flash[:notice] = "Bairro criado com sucesso."
        format.html { redirect_to(admin_bairros_path) }
        format.xml  { render :xml => @bairro, :status => :created, :location => @bairro }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @bairro.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /bairros/1
  # PUT /bairros/1.xml
  def update
    @bairro = Bairro.find(params[:id])

    respond_to do |format|
      if @bairro.update_attributes(params[:bairro])
        flash[:notice] = "Bairro atualizado com sucesso."
        format.html { redirect_to(admin_bairros_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @bairro.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /bairros/1
  # DELETE /bairros/1.xml
  def destroy
    @bairro = Bairro.find(params[:id])
    @bairro.destroy

    respond_to do |format|
      format.html { redirect_to(admin_bairros_path) }
      format.xml  { head :ok }
    end
  end
end
