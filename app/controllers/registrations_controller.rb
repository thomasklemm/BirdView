class RegistrationsController < ApplicationController
  before_action :ensure_new_user
  before_action :load_and_ensure_active_invitation, only: :new

  def new
    @registration = Registration.new(invitation_params)
  end

  # Create new user and accept invitation
  def create
    @registration = Registration.new(registration_params)

    if @registration.save
      sign_in @registration.user

      track 'User Create By Invitation', @registration.user
      track_user @registration.user, 'Invitation'

      track 'Invitation Accept', @registration.invitation
      track 'Account Join', @registration.account

      redirect_to projects_path,
        notice: "Welcome to Tweetbox."
    else
      render :new
    end
  end

  private

  def invitation_params
    params.slice(:invitation_code, :first_name, :last_name, :email)
  end

  def registration_params
    params[:registration].slice(:invitation_code, :first_name, :last_name, :email, :password)
  end

  def ensure_new_user
    user_signed_in? and return redirect_to root_path,
      notice: "Please logout and return to complete a new registration."
  end

  def load_and_ensure_active_invitation
    invitation_code = params[:invitation_code]
    invitation = Invitation.where(code: invitation_code).first if invitation_code.present?

    invitation_code.present? or return redirect_to root_url,
      notice: "You'll need an invitation code to successfully register."

    invitation.present? or return redirect_to root_url,
      notice: "The invitation code could not be found or has been revoked."

    invitation.used? and return redirect_to root_url,
      notice: "The invitation code has already been used."

    invitation.expired? and return redirect_to root_url,
      notice: "The invitation code has expired."
  end
end
