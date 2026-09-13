require 'app/game.rb'
require 'app/proc_gen.rb'

# Some controls that might be nice
  # A text box with a timed message Queueue
  # Fade-in/Fade-out Buttons
  # Agent Tick and Trigger
  # Location-specific Resources
  # Unique Entities (Golems)
    # A golem needs:
    # Type
    # Equipment
    # Current Task

class MyGame < Game
  def initialize args
    super

    setup_globals
    setup_start
    setup_ritual_room

    @location = :start
  end

# ============================================================
# No Location / Global
# Elements available in multiple scenes
# ============================================================
  def setup_globals
      create_log :notes, 300, 10, 680, 270
      set_resource :mana, 0

      # What can be done anywhere?
        # Travel to unlocked areas
        # Command golems?

  end

# ============================================================
# :start
# Description: Open air above the buried structure.
#
# Available Actions:
#  Travel to
#   Ritual Room
# ============================================================
  def setup_start
    # You know what? Maybe instead of a notebox I need an RPG textbox thing...
    add_message(:notes, "Guess what?")
    add_message(:notes, "You're going to command golems!")
    add_message(:notes, "Click the button to see your sorcerer's lair!")

    create_button :start_ritual_room, 600, 400, "Enter"
    @buttons[:start_ritual_room].location =  [:start]
    highlight_button :start_ritual_room, 100
    reveal_button :start_ritual_room

    def start_ritual_room_clicked
      change_location :ritual_room
    end
  end



  # ============================================================
  # :ritual_room
  # Description: Raise Mana
  #
  # Available Actions:
  #  Raise Mana:  Requires: ??
  #  Activate Golem: Requires: Golem, Mana
  #
  # Unlocks:
  #  First golem
  #  Travel to
  #   Workshop
  #   ??
  # ============================================================
  def setup_ritual_room
    create_actor :ritual_room, ticks_total: 180
    @actors[:ritual_room].location =  [:ritual_room]

    create_unlock :first_golem

    create_button :raise_mana, 600, 500, "Raise Mana"
    @buttons[:raise_mana].location =  [:ritual_room]
    highlight_button :raise_mana, 100
    reveal_button :raise_mana

    create_button :activate_golem, 600, 400, "Activate Golem"
    @buttons[:activate_golem].location =  [:ritual_room]
  end

  def raise_mana_clicked
    if not button_highlight_full?(:raise_mana)
      return
    end
    generate_resource(:mana, 1)
  end

  def activate_golem_tick
    mana = get_resource(:mana)
    percent = [100, (mana/50)*100].min
    highlight_button :activate_golem, percent
  end

  def activate_golem_clicked
    if not button_highlight_full?(:activate_golem)
      return
    end
    if use_resource(:mana, 50)
      generate_resource(:golems, 1)
    end
  end

  def ritual_room_first_entered
    add_message(:notes, "You gaze around the dusty space. Hardly ausipicious beginnings, but it's all you could afford. In one corner, a long dormant golem slumps against the wall. You will need to raise a great deal of power to make it useful.")
  end

  def ritual_room_entered
    add_message(:notes, "You returned to the ritual space.")
  end

  def raise_mana_tick
    @actors[:ritual_room].ticks_remaining -= 1
    if @actors[:ritual_room].ticks_remaining == 0
      @actors[:ritual_room].ticks_remaining = @actors[:ritual_room].ticks_total
      if get_resource(:mana) >= 50
        unlock(:first_golem)
      end
    end
  end

  def first_golem_unlocked
    add_message(:notes, "You have raised enough power to activate the old golem.")
    reveal_button :activate_golem
  end
end
