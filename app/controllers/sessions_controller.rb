class SessionsController < ApplicationController
    # skip_before_action :require_login, only: [:create]

    def create
        @user = User.find_by(username: params[:username])
        if !!@user
            session[:user_id] = @user.id
            params[:id] = @user.id
            redirect_to root_path
        else
            @user = User.new(username: params[:username])
            session[:user_id] = @user.id
            params[:id] = @user.id
            redirect_to root_path
        end
    end

    def destroy
        session.delete :user_id
        head :no_content
    end

end
