module SessionsHelper

  # log in with passed user
  def log_in(user)
    session[:user_id] = user.id
  end

  # return logged in user (if the user exists)
  def current_user
    if session[:user_id]
      @current_user ||= User.find_by(id: session[:user_id])
    end
  end

  # return true if user logged in, else return false
  def logged_in?
    !current_user.nil?
  end

  # log out current user
  def log_out
    session.delete(:user_id)
    @current_user = nil
  end
end
