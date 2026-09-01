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

      create_button :raise_mana, 600, 300, "Raise Mana"
      @buttons[:raise_mana].location =  [:basic]
      highlight_button :raise_mana, 100
      reveal_button :raise_mana

      def raise_mana_clicked
        if not button_highlight_full?(:raise_mana)
          return
        end
        generate_resource(:mana, 1)
      end
  end

# ============================================================
# :start
# Description: Open air above the buried structure.
#
# Available Actions:
# ============================================================
  def setup_basic
    add_message(:notes, "You gaze around the dusty workshop. Hardly ausipicious beginnings, but it's all you could afford. In one corner, a long dormant golem slumps against the wall. You will need to raise a great deal of power to make it useful.")

    create_actor :basic
    @actors[:basic].location =  [:basic]

    create_unlock :first_golem
  end

  def basic_entered
    add_message(:notes, "You returned to your first workshop.")
  end

  def basic_tick
    add_message(:notes, "Tick...")
  end

  def first_golem_unlocked
  end
end
