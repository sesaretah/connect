class ApplicationController < ActionController::API
  require "unicode_fixer"
  before_action :inspect_unicode
  before_action :configure_permitted_parameters, if: :devise_controller?

  protected

  def configure_permitted_parameters
    devise_parameter_sanitizer.for(:sign_up) { |u| u.permit(:username, :email, :password, :password_confirmation, :remember_me) }
    devise_parameter_sanitizer.for(:sign_in) { |u| u.permit(:login, :username, :email, :password, :remember_me) }
    devise_parameter_sanitizer.for(:account_update) { |u| u.permit(:username, :email, :password, :password_confirmation, :current_password) }
  end

  def inspect_unicode
    fix_unicode_values(nil, params)
  end

  def fix_unicode_values(parent, hash)
    hash.each { |key, value|
      value.is_a?(Hash) ? fix_unicode_values(key, value) : hash[key] = UnicodeFixer.fix(value)
    }
  end

  def owner(obj, user)
    if obj.user_id == user.id
      return true
    else
      return false
    end
  end
end
