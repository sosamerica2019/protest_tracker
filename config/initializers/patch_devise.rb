module Devise
  module Models
    module Confirmable
    
      # Resend the confirmation message whenever a non-confirmed user is refused sign-in
      # to avoid the annoyance of having to re-requesting it and not knowing where
      def inactive_message
        if !confirmed? and not Rails.env.test?
          self.send_confirmation_instructions
          :unconfirmed
        else
          super
        end
      end
    end
  end
end