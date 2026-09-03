require 'app/game.rb'
require 'app/proc_gen.rb'

class MyGame < Game
  def initialize args
    super

    setup_globals
    setup_basic

    @descend_target = :entry
    @location = :basic
    @last_observation = nil
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
#  Raise Mana:  Requires: ??
#  Activate Golem: Requires: Golem, Mana
#  Craft Golem: Requires: Materials
#
# Unlocks:
#  First golem
#  Travel to... ??
# ============================================================
  def setup_basic
    add_message(:notes, "You gaze around the dusty workshop. Hardly ausipicious beginnings, but it's all you could afford. In one corner, a long dormant golem slumps against the wall. You will need to raise a great deal of power to make it useful.")

    create_actor :basic, 180
    @actors[:basic].location =  [:basic]

    create_unlock :first_golem


    create_button :raise_mana, 600, 300, "Raise Mana"
    @buttons[:raise_mana].location =  [:basic]
    highlight_button :raise_mana, 100
    reveal_button :raise_mana
  end

  def raise_mana_clicked
    if not button_highlight_full?(:raise_mana)
      return
    end
    generate_resource(:mana, 1)
  end

  def basic_entered
    add_message(:notes, "You returned to your first workshop.")
  end

  def basic_tick
    @actors[:basic].ticks_remaining -= 1
    if @actors[:basic].ticks_remaining == 0
      @actors[:basic].ticks_remaining = @actors[:basic].ticks_total
      add_message(:notes, "Tick...")
    end
  end

  def first_golem_unlocked
  end
end
