class CommentsController < ApplicationController
  before_filter :verificar_se_pode_editar, :only => [ :set_comentario_body ]

  # Permite a edição do comentário na lista de topicos
  in_place_edit_for :comentario, :body

  # Metodos que não precisam de authenticity token
  protect_from_forgery :except => [ :processar, :create, :set_comentario_body ]

  verify :params => [ :topico_id ],
         :only => :process
  def processar
    @comment = Comment.new(params[:comment])
    @comment.commentable_id = params[:topico_id]
    @comment.commentable_type = "Topico"
    session[:novo_comentario] = @comment
    redirect_to :action => "create"
  end

  verify :session => [ :novo_comentario ],
         :only => :create
  def create
    @comment = session[:novo_comentario]
    @topico = Topico.find(@comment.commentable_id)

    if logged_in?
      @comment.user = current_user
      # @topico.comment_threads << @comment
      if @comment.save
        session[:novo_comentario] = nil

        # Tentamos colocar a atualização dos contadores e a notificação por e-mail
        # num ActiveRecord::Observer, mas por alguma razão misteriosa não deu
        # certo. Por isso, manter aqui por enquanto.

        # Atualiza contadores...
        @topico.atualiza_contadores
        @comment.user.atualiza_contadores

        # ... e envia as notificações por e-mail para o dono do tópico e para as
        # pessoas que seguem.
        @topico.notificar_novo_comentario(@comment)

        flash[:notice] = "Comentário criado com sucesso."
        redirect_to topico_url(:topico_slug => @topico.to_param)
      else
        render :controller => "topicos", :action => "show"
      end
    else
      flash[:notice] = "Para deixar um comentário, faça seu login ou cadastre-se."
      redirect_to login_url
    end
  end
  
  verify :params => [ :id ],
         :only => [ :body ]
  def body
    comentario = Comentario.find(params[:id])
    render :text => comentario.body
  end
  
  private
  
  def verificar_se_pode_editar
    @comentario = Comentario.find(params[:id])
    if logged_in? and not current_user.admin?
      if current_user != @comentario.user
        flash[:warning] = "Você não tem permissão para editar esse comentário."
        redirect_to topico_url(:topico_slug => @topico.to_param) and return false
      end
    end
  end
  

end