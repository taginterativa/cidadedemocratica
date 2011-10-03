namespace :cidade do
  namespace :contadores do
    desc "Atualiza contadores e relevancia por usuario"
    task :usuario => :environment do
      User.ativos.find(:all).each{ |u| u.atualiza_contadores }
    end

    desc "Atualiza contadores e relevancia por topico"
    task :topico => :environment do
      Topico.find(:all).each{ |t| t.atualiza_contadores }
    end
    
    desc "Atualiza contadores e relevancia de estados, cidades e bairros"
    task :estado_cidade_bairro => :environment do
      Estado.find(:all).each{ |e| e.atualiza_contadores }
      Cidade.find(:all).each{ |c| c.atualiza_contadores }
      Bairro.find(:all).each{ |b| b.atualiza_contadores }
      Session.delete_all # para limpar as sessions...
    end
    
    desc "Atualiza contadores e relevancia das tags"
    task :tag => :environment do
      Tema.find(:all).each{ |t| t.atualiza_contadores }
    end
  end

  namespace :ajustes do
    desc "Lista os comentarios sem topico relacionado"
    task :orfaos => :environment do
      Comment.find(:all).each do |c|
        topico = Comment.find_commentable('Topico', c.commentable_id)
        if topico.nil?
          puts 'Este comentário não tem tópico: ' + c.id.to_s
        elsif topico.user.nil?
          puts 'Este comentário não tem usuário: ' + c.id.to_s
        end
      end
      Adesao.all.each do |a|
        if a.topico.nil?
          puts 'Esta adesão não tem tópico: ' + a.id.to_s
        end
        if a.user.nil?
          puts 'Esta adesão não tem usuário: ' + a.id.to_s
        end
      end
    end
  end

  namespace :avisos do
    desc "Envia e-mail semanal aos usuarios com Observatorio"
    task :observatorio => :environment do
      desde = 7.days.ago
      User.com_observatorio_ativo.all(:include => :dado).each do |user|
        # A stupid way to test...
        #if (user.email == 'alexandre_piccolo@yahoo.com.br') or (user.email == 'alexandrepiccolo@gmail.com')
          if !user.observatorios.first.atividades(desde).empty? and user.active?
            puts "E-mail enviado para #{user.nome} (#{user.email})..."
            UserMailer.deliver_observatorio(user, desde) #if (user.email == 'alexandre_piccolo@yahoo.com.br') or (user.email == 'alexandrepiccolo@gmail.com')
          end
        #end
      end
    end
    
    desc "Envia e-mail diário aos usuários não confirmados"
    task :nao_confirmados => :environment do
      dias = 7.days.ago
      User.cadastrado_em(dias).nao_confirmados.each do |user|
        puts "E-mail [para confirmar cadastro] enviado para #{user.email}"
        UserMailer.deliver_signup_last_try(user)
      end
    end
  end
  
  namespace :verificacoes do
    desc "Verifica localizacoes de usuarios"
    task :users => :environment do
      Local.de_usuario.each do |local|
        if not local.ok?
          local.ok?(true)
        end
      end
    end
  end

end
