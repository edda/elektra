require 'securerandom'

module Identity
  module Domains
    class TechnicalUsersController < ::DashboardController

      authorization_required only: [:index, :new, :create]
      
      def index
        services.identity.users(domain_id:@scoped_domain_id, "name__startswith" => 't_' ).length
        @technical_users = services.identity.users(domain_id:@scoped_domain_id, "name__startswith" => 't_' ).select{|user| user.name.start_with?("t_")}
      end
      
      def new
        @technical_user = services.identity.new_user(description: "Created by #{current_user.name}. Purpose: ")
      end
      
      def create
        attributes = {
          name: "t_#{SecureRandom.hex(8)}", 
          password: generate_password,
          description: params[:user][:description],
          domain_id: params[:user][:domain_id]
        }

        @technical_user = services.identity.new_user(attributes)
        @password = attributes[:password]
        if @technical_user.save
          render action: :create
        else
          render action: :new
        end
      end
      
      def edit
        @technical_user = services.identity.find_user(params[:id])
        enforce_permissions("identity:technical_user_update", user: @technical_user)
      end
      
      def update
        @technical_user = services.identity.find_user(params[:id])
        enforce_permissions("identity:technical_user_update", user: @technical_user)
        
        @technical_user.description = params[:user][:description]
        if @technical_user.save
          render action: :update
        else
          render action: :edit
        end
      end
      
      def reset_password
        @technical_user = services.identity.find_user(params[:id])
        enforce_permissions("identity:technical_user_reset_password", user: @technical_user)
      end
      
      def change_password
        @technical_user = services.identity.find_user(params[:id])
        enforce_permissions("identity:technical_user_reset_password", user: @technical_user)

        @new_password = generate_password
        @technical_user.password = @new_password
        if @technical_user.save
          render action: :change_password
        else
          render action: :reset_password
        end
      end
      
      def destroy
        @technical_user = services.identity.find_user(params[:id])
        enforce_permissions("identity:technical_user_delete", user: @technical_user)
        
        if @technical_user.destroy
          @deleted = true
        else
          @deleted = false
        end  
      end

      private
      def generate_password(length=8)
        Array.new(length){[*"A".."Z", *"a".."z",*"0".."9"].sample}.join
      end
    end
  end
end
