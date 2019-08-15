require "securerandom"

module DiemHaikunator
  class << self
    def haikunate(token_range = 9999)
      build(token_range)
    end

    private

    def build(token_range)
      case SecureRandom.random_number(6)
      when 0
        sections = [
          adjectives[random_seed % adjectives.length],
          nouns[random_seed % nouns.length],
          token(token_range)
        ]
      when 1
        sections = [
          token(token_range),
          adjectives[random_seed % adjectives.length],
          nouns[random_seed % nouns.length]
        ]
      when 2
        sections = [
          adjectives[random_seed % adjectives.length],
          token(token_range),
          nouns[random_seed % nouns.length]
        ]
      when 3
        sections = [
          diem_adjectives[random_seed % diem_adjectives.length],
          diem_nouns[random_seed % diem_nouns.length],
          token(token_range)
        ]
      when 4
        sections = [
          token(token_range),
          diem_adjectives[random_seed % diem_adjectives.length],
          diem_nouns[random_seed % diem_nouns.length]
        ]
      when 5
        sections = [
          diem_adjectives[random_seed % diem_adjectives.length],
          token(token_range),
          diem_nouns[random_seed % diem_nouns.length]
        ]
      end
      delimiter = ["-", ".", "_", " ", ":", "*"][SecureRandom.random_number(6)]
      sections.compact.join(delimiter)
    end

    def random_seed
      SecureRandom.random_number(4096)
    end

    def token(range)
      SecureRandom.random_number(range) if range > 0
    end

    def adjectives
      %w(
        autumn hidden bitter misty silent empty dry dark summer
        icy delicate quiet white cool spring winter patient
        twilight dawn crimson wispy weathered blue billowing
        broken cold damp falling frosty green long lingering
        bold little morning muddy old red rough still small
        sparkling throbbing shy wandering withered wild black
        young holy solitary fragrant aged snowy floral
        restless divine polished ancient purple lively nameless
      )
    end
    
    def diem_adjectives
      %w(
        delicate hidden silent quiet cool patient broken
        lingering still determined lively international powerful basic magnificent public transparent
        realistic united decentralised pluralist egalitarian cultured
        social productive sustainable ecological creative peaceful 
        open green genuine urgent daring ongoing great beautiful
      )
    end

    def nouns
      %w(
        waterfall river breeze moon rain wind sea morning
        snow lake sunset pine shadow leaf dawn glitter forest
        hill cloud meadow sun glade bird brook butterfly
        bush dew dust field fire flower firefly feather grass
        haze mountain night pond darkness snowflake silence
        sound sky shape surf thunder violet water wildflower
        wave water resonance sun wood dream cherry tree fog
        frost voice paper smoke star
      )
    end
    
    def diem_nouns
      %w(
        democracy energy fire storm rain star
        possibilities peace institutions freedom solidarity
        equality power inspiration Europe imagination ideas
        diversity technology transformation
      )
    end
  end
end