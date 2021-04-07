class V1::UsersController < ApplicationController
  include JWTWrapper
  #def login
  #  if User.find_by_email(params['email']).try(:valid_password?, params[:password])
  #    @user = User.find_by_email(params['email'])
  #    render :json => {data: {result: 'OK', token: JWTWrapper.encode({ user_id: @user.id }), user_id: @user.id}, klass: 'User'}.to_json , :callback => params['callback']
  #  else
  #    render :json => {result: 'ERROR',  error: I18n.t(:doesnt_match) }.to_json , status: :unprocessable_entity
  #  end
  #end

  def login
    user = User.find_by_email(params[:user][:email])
    #user.notify_user if user
    if !user.blank?
      render :json => { data: { result: "OK", token: JWTWrapper.encode({ user_id: user.id }), user_id: user.id }, klass: "Login" }.to_json, :callback => params["callback"]
    else
      render :json => { result: "ERROR", reason: I18n.t(:doesnt_match) }.to_json, status: :unprocessable_entity
    end
  end

  def verify
    user = User.verify(params["verification_code"])
    if !user.blank?
      render :json => { data: { result: "OK", token: JWTWrapper.encode({ user_id: user.id }), user_id: user.id }, klass: "Verify" }.to_json, :callback => params["callback"]
    else
      render :json => { result: "ERROR", reason: I18n.t(:doesnt_match) }.to_json, status: :unprocessable_entity
    end
  end

  def sign_up
    #    params.permit!
    #    if !params["username"].blank?
    #      username = params["username"]
    #    else
    #      username = SecureRandom.hex(10)
    #    end
    #    password = SecureRandom.hex(10)
    user = User.create(email: params[:user][:email], password: params[:user][:password], password_confirmation: params[:user][:password], last_login: DateTime.now)
    if !user.blank?
      Profile.create(name: params["name"], user_id: user.id)
      #user.notify_user
    end
    if !user.blank?
      if user.id != nil
        render :json => { data: { result: "OK", token: JWTWrapper.encode({ user_id: user.id }), user_id: user.id }, klass: "SignUp" }.to_json, :callback => params["callback"]
      else
        render :json => { result: "ERROR", reason: I18n.t(:already_exist) }.to_json, status: :unprocessable_entity
      end
    else
      render :json => { result: "ERROR", reason: I18n.t(:doesnt_match) }.to_json, status: :unprocessable_entity
    end
  end

  # def sign_up
  #   @user = User.new(email: params['email'], password: params['password'], password_confirmation: params['password_confirmation'])
  #   if @user.save
  #     Profile.create(name: params['name'], surename: params['surename'], user_id: @user.id)
  #     render :json => { data: {result: 'OK', token: JWTWrapper.encode({ user_id: @user.id }), user_id: @user.id}, klass: 'User'}.to_json, :callback => params['callback']
  #   else
  #     render :json => {result: 'ERROR', error: @user.errors }.to_json , status: :unprocessable_entity
  #   end
  # end

  def validate_token
    if !current_user.blank?
      render :json => { data: { result: "OK", name: current_user.profile.name, uuid: current_user.uuid }, klass: "Validate" }.to_json, :callback => params["callback"]
    else
      render json: { data: [], klass: "Error" }, status: :ok
    end
  end

  def index
    users = User.all
    render json: { data: ActiveModel::SerializableResource.new(users, user_id: current_user.id, each_serializer: UserSerializer).as_json, klass: "User" }, status: :ok
  end

  def role
    if !current_user.blank?
      render json: { data: AbilitySerializer.new(current_user).as_json, klass: "UserRole" }, status: :ok
    end
  end

  def change_role
    if !current_user.blank?
      current_user.current_role_id = params[:role_id]
      current_user.save
      render json: { data: AbilitySerializer.new(current_user).as_json, klass: "UserRole" }, status: :ok
    end
  end

  def assignments
    user = User.find(params[:user_id])
    role = Role.find(params[:role_id])
    user.assign(role.id) if user && role
    render json: { data: RoleSerializer.new(role, user_id: current_user.id).as_json, klass: "Role" }, status: :ok
  end

  def delete_assignment
    user = User.find(params[:user_id])
    role = Role.find(params[:role_id])
    user.unassign(role.id) if user && role
    render json: { data: RoleSerializer.new(role, user_id: current_user.id).as_json, klass: "Role" }, status: :ok
  end

  def service
    response = open("https://auth.ut.ac.ir:8443/cas/serviceValidate?service=https%3A%2F%2Fsn.ut.ac.ir%2Fusers%2Fservice&ticket=" + params[:ticket]).read
    result = Hash.from_xml(response.gsub("\n", ""))
    Rails.logger.info result
  end
end
