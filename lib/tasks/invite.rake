

namespace :invite do
  desc "Try inviting dib-accounts"
  task :dib, [:url, :election_id] => :environment do |task, args|
    file_url = args[:url] # WHAT IS THE REMOTE URL
    election = Election.find_by_id(args[:election_id])

    I18n.locale = :de
		
    # Parse CSV
    puts "E-Mail,Invite-Code"
		require 'open-uri'
    CSV.new(open(file_url), headers: true, col_sep: ";").each do |row|
      h = row.to_hash
      u = User.invite!(
        :personal_name => h['first_name'],
        :family_name => h['last_name'],
        :email => h['email_address_1'],
        :language => "Deutsch",
        :country => "DE",
        :verification_state => 4,       # Name & Address confirmed by DiB
        # :skip_invitation => true,      # Do send the invite directly
      )

      # if the user hasn't accepted its invite and doesn't have an election token yet and hasn't voted yet
      if !u.invitation_token.nil? && !u.has_active_token?(election) && !u.date_of_vote_on(election)
        # we need to put the creation time back before the cut off of the vote

        u.created_at = election.cutoff_date - 25.hours
        u.save

        # Give user the possibility to vote in this election
        UnusedElectionToken.create(:user_id => u.id,
                                  :election_id => election.id,
                                  :expiry_time => election.vote_end,
                                  :created_at => Time.now,
                                  :updated_at => Time.now)
      end
      
      puts "#{u.email},#{u.raw_invitation_token}"
    end
  end
end
