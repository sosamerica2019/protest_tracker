module ButtonsHelper

  def read_more_button(election)
    link_to(t('buttons.read_more'), new_candidacy_path(election_id: election.id), :class => "btn btn-primary")
  end
  
	def translate_button(candidacy)
	  link_to(t('elections.button_translate'), translate_candidacy_path(candidacy), :class => "btn btn-warning")
	end
	
	def view_candidates_button(election)
	  link_to(t('elections.link_candidates'), candidates_election_path(election), :class => "btn btn-info")
	end
	
	def view_results_button(election)
	  link_to(t('buttons.see_results'), results_election_path(election), :class => "btn btn-info")
	end
	
  def vote_button(election)
	  link_to(t('voting.cast_vote'), voting_election_path(election), :class => "btn btn-danger")
	end
end
