class Admin::UsersController < Admin::AdminController
  PER_PAGE = 25
  
  # GET /users
  # GET /users.xml
  def index
    @per_page = (params[:per_page] and not params[:per_page].blank?) ? params[:per_page].to_i : PER_PAGE

    @estados = Estado.all(:order => "abrev ASC")
    @cidades = (params[:busca_estado] and not params[:busca_estado].blank?) ? Cidade.all(:conditions => ["estado_id = ?", params[:busca_estado]], :order => "nome ASC") : []

    # Comentário do Mário: por alguma razão, .por_idade e .com_status está dando problemas em produção. Temporiamente, removi essas chamadas para voltar a funcionar. Analisar.
    # @users = User.com_nome(params[:busca_nome]).com_email(params[:busca_email]).do_sexo(params[:busca_sexo]).por_idade(params[:busca_idade]).do_tipo(params[:busca_tipo]).com_status(params[:busca_status]).do_estado(params[:busca_estado]).da_cidade(params[:busca_cidade]).paginate(:all, :per_page => @per_page, :page => params[:page], :order => "users.id DESC")
    # @users = User.paginate(:all, :per_page => @per_page, :page => params[:page], :order => "users.id DESC")
    @users = User.com_status(params[:busca_status]).com_nome(params[:busca_nome]).com_email(params[:busca_email]).do_sexo(params[:busca_sexo]).do_tipo(params[:busca_tipo]).do_estado(params[:busca_estado]).da_cidade(params[:busca_cidade]).paginate(:all, :per_page => @per_page, :page => params[:page], :include => "dado", :order => "users.id DESC")

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @users }
      format.csv { save_as_csv(@users) }
    end
  end

  # GET /users/1
  # GET /users/1.xml
  def show
    @user = User.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/new
  # GET /users/new.xml
  def new
    @user = User.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @user }
    end
  end

  # GET /users/1/edit
  def edit
    @user = User.find(params[:id])
  end

  # POST /users
  # POST /users.xml
  def create
    @user = User.new(params[:user])

    respond_to do |format|
      if @user.save
        flash[:notice] = "Usuário criado com sucesso."
        format.html { redirect_to(admin_users_path) }
        format.xml  { render :xml => @user, :status => :created, :location => @user }
      else
        format.html { render :action => "new" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /users/1
  # PUT /users/1.xml
  def update
    @user = User.find(params[:id])

    respond_to do |format|
      if @user.update_attributes(params[:user])
        flash[:notice] = "Usuário atualizado com sucesso."
        format.html { redirect_to(admin_users_path) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @user.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /users/1
  # DELETE /users/1.xml
  def destroy
    @user = User.find(params[:id])
    @user.destroy
    # @user.delete! # usando os assm states...!
    flash[:notice] = "Usuário removido com sucesso."

    respond_to do |format|
      format.html { redirect_to(admin_users_path) }
      format.xml  { head :ok }
    end
  end

  def banir
    @user = User.find(params[:id])
    @user.suspend!
    flash[:notice] = "Usuário (id = #{@user.id}; email = #{@user.email}) banido!"

    respond_to do |format|
      format.html { redirect_to(admin_users_path) }
      format.xml  { head :ok }
    end
  end

  # Envia email do observatorio pro user.
  def observatorio_email
    @user = User.find(params[:id])
    UserMailer.deliver_observatorio(@user)
    render :update do |page|
      page.alert("Email enviado para #{@user.email}!")
    end
  end

  def mudartipo
    @user = User.find(params[:id])
  end

  def mudartipo_post
    @user = User.find(params[:id])
    if @user.update_attribute("type", params[:user][:type].to_s.camelize)
      flash[:notice] = "Usuário atualizado com sucesso."
      redirect_to(admin_users_path)
    else
      render :action => "mudartipo", :id => @user.id
    end
  end

  def mudarstate
    @user = User.find(params[:id])
  end

  def mudarstate_post
    @user = User.find(params[:id])
    if @user.update_attribute("state", params[:user][:state].to_s)
      flash[:notice] = "Estado do usuário atualizado com sucesso."
      redirect_to(admin_users_path)
    else
      render :action => "mudarstate", :id => @user.id
    end
  end

  def historico_de_logins
    @historico_de_logins = HistoricoDeLogin.paginate(:per_page => PER_PAGE, :page => params[:page], :include => :user, :order => "historico_de_logins.id DESC")
  end
  
  protected
  
  def save_as_csv(users)
    csv_string = FasterCSV.generate do |csv|
      # header row
      csv << ["email", "id", "nome"]

      # data rows
      users.each do |user|
        nome = ""
        nome = user.nome if (user.dado and not user.nome.blank?)
        csv << [user.email, user.id, nome]
      end
    end

    # send it to the browser
    send_data csv_string,
              :type => 'text/csv; charset=utf-8; header=present',
              :disposition => "attachment; filename=users-#{Time.now.strftime('%Y%m%d-%H%M%S')}.csv"
    
  end
  
  def export_csv(users)
    filename = I18n.l(Time.now, :format => :short) + "-users.csv"
    content = Project.to_csv(projects)
    #content = BOM + Iconv.conv("utf-16le", "utf-8", content)
    send_data content, :filename => filename
  end
end