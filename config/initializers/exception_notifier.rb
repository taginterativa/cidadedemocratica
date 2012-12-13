# encoding: utf-8

Cidadedemocratica::Application.config.middleware.use ExceptionNotifier,
  :email_prefix => "[Erro] ",
  :sender_address => %{"Cidade Democrática" <exception@cidadedemocratica.org.br},
  :exception_recipients => %w{noreply@cidadedemocratica.org.br}
