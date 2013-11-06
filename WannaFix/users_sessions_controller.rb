class UsersSessionsController < Devise::SessionsController
  prepend_before_filter :require_no_authentication, :only => [:create ]

  respond_to :json

  def login_failure
    render :json => {error: 'Incorrect Username or Password'}, :status => 401
  end


  def create
    ensure_params_exist

    warden.custom_failure!

    return invalid_login_attempt unless User.find_for_database_authentication(:email=>params[:user][:email])

    self.resource = warden.authenticate!(scope: resource_name, recall:"#{controller_path}#login_failure")

    set_flash_message(:notice, :signed_in) if is_navigational_format?
    sign_in(resource_name, resource)
    render :template => 'users/show'

  end
  
  def destroy
  # DELETE /resource/sign_out

    redirect_path = after_sign_out_path_for(resource_name)
    signed_out = (Devise.sign_out_all_scopes ? sign_out : sign_out(resource_name))
    set_flash_message :notice, :signed_out if signed_out && is_navigational_format?

    render :json => {message: 'Logout succeeded'}
  end

  def ensure_params_exist
    return unless params[:user].blank?
    render :json=>{:success=>false, :message=> 'missing user parameter'}, :status=>422
  end

  def invalid_login_attempt
    warden.custom_failure!
    render :json=> {:success=>false, :message=> 'Error with your login or password'}, :status=>401
  end
end
