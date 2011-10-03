class Admin::AdminController < ApplicationController
  layout "admin"
  skip_filter :define_cidade_corrente
  before_filter :admin_login_required
end