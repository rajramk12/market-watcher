class Admin::BaseController < ApplicationController
before_action :authenticate_admin!




private




def authenticate_admin!
  # Simple placeholder auth (replace with Devise / OAuth later)
  #head :unauthorized unless session[:admin] == true
end
end
