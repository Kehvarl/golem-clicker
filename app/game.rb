# ============================================================
# Kehvarl's DragonRuby Clicker Engine
#
# A minimal multi-location clicker engine.
#
# Core Concepts:
#   Location  - Scopes rendering and ticking.
#   Buttons   - UI elements with tick/click hooks.
#   Actors    - Background ticking entities.
#   Resources - Numeric tracked values.
#   Unlocks   - Boolean flags with optional callbacks.
#   Logs      - Scrollable message panels.
#
# Frame Order:
#   tick   -> actors, buttons, input
#   render -> buttons, resources, logs
#
# Extension Conventions:
#   <id>_tick
#   <id>_clicked
#   <key>_unlocked
#
# Defined methods are dispatched automatically.
# ============================================================

class Game
    attr_accessor :running
    def initialize args
        @running = true
        @args = args
        @location = nil
        @visited_locations = {}
        @unlocks = {}
        @buttons = {}
        @actors = {}
        @values = {}
        @logs = {}
        @default_button_color = {r:128,g:128,b:128}
        @default_border_color = {r:64,g:64,b:64}
        @default_highlight_color = {r:196,g:196,b:196}
        @default_text_color = {r:0,g:0,b:0}
    end

# == Input ==
# ------------------------------------------------------------
# handle_mouse_click
# Processes mouse click events.
#
# Invokes <id>_clicked for visible buttons
# whose bounds contain the click and match location.
# ------------------------------------------------------------
    def handle_mouse_click
        if @args.inputs.mouse.click
            b = @buttons.find_all do |k, v|
                v.show && @args.inputs.mouse.click.point.inside_rect?(v.primitives.first) &&  location_match?(v.location)
            end
            b.each do |_, button|
                if self.respond_to? button.on_click
                    self.send button.on_click
                end
            end
        end
    end

# == Update/Tick ==

# ------------------------------------------------------------
# tick
# Main per-frame update loop.
#
# Order:
#   1. Actors
#   2. Buttons
#   3. Input
#
# Skips execution if @running is false.
# Dispatches:
#   <id>_tick
#   <id>_clicked
# ------------------------------------------------------------
    def tick
        if not @running
            return
        end

        @actors.each do |_, actor|
            if actor_can_tick?(actor)
                if actor.on_tick_proc
                    actor.on_tick_proc.call(self, actor)
                elsif actor.on_tick && respond_to?(actor.on_tick)
                    self.send(actor.on_tick)
                end
            end
        end

        @buttons.each do |_, button|
            if button_can_tick?(button)
                if button.on_tick_proc
                    button.on_tick_proc.call(self, button)
                elsif button.on_tick && self.respond_to?(button.on_tick)
                    self.send(button.on_tick)
                end
                calculate_highlight(button)
                if button.highlight
                    button.primitives[1].w = button.primitives[0].w * (button.highlight_percent/100.0).clamp(0.0, 1.0)
                end
            end
        end

        handle_mouse_click

    end

# == Render ==

# ------------------------------------------------------------
# render
# Draws visible buttons, resources, and logs
# for the current location.
# ------------------------------------------------------------
    def render
        @buttons.each do |_, button|
            if button.show
                if location_match?(button.location)
                    @args.outputs.primitives << button.primitives
                end
            end
        end

        visible_values = @values.select { |k, v| v.show }
        visible_values.keys.each_with_index do |v, i|
            resource = visible_values[v]
            @args.outputs.primitives << {x: 0, y: 700 - (i * 18)  ,text: "#{resource.label}: #{resource.value.floor}", r: 0, g: 0, b: 0}.label!
        end

        render_logs
    end

# ------------------------------------------------------------
# render_logs
# Renders all visible logs.
#
# Messages are drawn bottom-up and clipped
# to the log’s bounding box.
# ------------------------------------------------------------
    def render_logs
        @logs.each do |l|
            log = l[1]

            if not log.show
                next
            end

            # Draw message box
            @args.outputs.primitives << {
                x: log.x,y: log.y, w: log.w,h: log.h,
                r: 20, g: 20, b: 20
            }.solid!

            @args.outputs.primitives << {
                x: log.x,y: log.y, w: log.w,h: log.h,
                r: 200, g: 200, b: 200
            }.border!

            # Render messages bottom-up
            y_cursor = log.y + log.h - log.padding

            log.messages.reverse.each do |msg|
                split_lines = wrap_text(msg.text, log.w - (log.padding * 2), log.line_height)
                split_lines.each do |line|
                    y_cursor -= log.line_height
                    if y_cursor < log.y + log.padding
                        break
                    end
                    @args.outputs.primitives << {
                        x: log.x + log.padding,
                        y: y_cursor,
                        text: line,
                        size_px: log.line_height-1,
                        **msg.color
                    }.label!
                end
            end
        end
    end

# == Locations ==

# ------------------------------------------------------------
# change_location
# Triggers a location change
#
# Implicit callbacks:
#   <location>_left
#   <location>_entered
#   <location>_first_entered
# ------------------------------------------------------------

    def change_location(new_location)
        return if @location == new_location

        if self.respond_to?("#{@location}_left".to_sym)
            self.send("#{@location}_left".to_sym)
        end

        @location = new_location

        if not @visited_locations[new_location]
            @visited_locations[new_location] = true
            if self.respond_to?("#{new_location}_first_entered".to_sym)
                self.send("#{new_location}_first_entered".to_sym)
            elsif self.respond_to?("#{new_location}_entered".to_sym)
                self.send("#{new_location}_entered".to_sym)
            end
        else
            if self.respond_to?("#{new_location}_entered".to_sym)
                self.send("#{new_location}_entered".to_sym)
            end
        end
    end

# == Buttons ==

# ------------------------------------------------------------
# create_button
# Registers a button.
#
# Hidden by default.
# Optional location limits render/tick scope.
# Optional on_tick_proc overrides implicit <id>_tick dispatch with a lambda.
#
# Implicit callbacks:
#   <id>_clicked
#   <id>_tick
# ------------------------------------------------------------
    def create_button id, x, y, text, w=nil, h=nil, location=nil, always_tick=nil
        if w == nil or h == nil
            w, h = @args.gtk.calcstringbox text
            w += 20
            h += 20
        end
        @buttons[id] = {
            show: false,
            text: text,
            location: location,
            always_tick: always_tick,
            on_click: "#{id}_clicked".to_sym,
            on_tick: "#{id}_tick".to_sym,
            on_tick_proc: nil,
            highlight_percent: 0,
            highlight: false,
            primitives: [
                {x:x, y:y, w:w, h:h, **@default_button_color}.solid!,
                {x:x, y:y, w:0, h:h, **@default_highlight_color}.solid!,
                {x:x, y:y, w:w, h:h, **@default_border_color}.border!,
                {x: x + 10, y:y + 30 ,text:text, **@default_text_color}.label!,
            ]}
    end

# ------------------------------------------------------------
# highlight_button
# Enables highlight rendering for a button.
#
# starting_percent sets initial fill level (0–100).
# ------------------------------------------------------------
    def highlight_button id, starting_percent = 0
        @buttons[id].highlight = true
        @buttons[id].primitives[1].w = @buttons[id].primitives[0].w * (starting_percent / 100.0)
        @buttons[id].highlight_percent = starting_percent
    end

# ------------------------------------------------------------
# auto_highlight
# Animates highlight toward a target percentage.
#
# percent_per_second controls animation speed.
# ------------------------------------------------------------
    def auto_highlight id, target_percent = 100, percent_per_second = 10
        @buttons[id].highlight_target = target_percent
        @buttons[id].highlight_rate = percent_per_second
    end

# ------------------------------------------------------------
# restart_highlight
# Resets highlight progress and assigns a new target.
# ------------------------------------------------------------
    def restart_highlight id, starting_percent = 0, target_percent = 100
        @buttons[id].highlight_percent = starting_percent
        @buttons[id].highlight_target = target_percent
    end

# ------------------------------------------------------------
# set_highlight
# Sets the button hight value
# ------------------------------------------------------------
    def set_highlight id, highlight_percent
        @buttons[id].highlight_percent = highlight_percent
    end

# ------------------------------------------------------------
# adjust_highlight
# Adjusts the button highlight percentage by the given amount
# ------------------------------------------------------------
    def adjust_highlight id, percent_change
        @buttons[id].highlight_percent += percent_change
    end

# ------------------------------------------------------------
# reveal_button
# Makes a button eligible for rendering.
# ------------------------------------------------------------
    def reveal_button id
        @buttons[id].show = true
    end

# ------------------------------------------------------------
# calculate_highlight
# Advances highlight animation toward its target.
#
# Called automatically during tick.
# ------------------------------------------------------------
    def calculate_highlight button
        time = 1.0/60
        if button.highlight and (button.highlight_target)
            diff = button.highlight_target - button.highlight_percent
            step = button.highlight_rate * time

            if diff.abs <= step
                button.highlight_percent = button.highlight_target
                button.highlight_target = nil
            else
                button.highlight_percent += step * (diff < 0 ? -1 : 1)
            end
        end
    end

# Returns true if the button's highlight bar is filled'
    def button_highlight_full?(id)
        @buttons[id].highlight_percent >= 100
    end

# Returns true if the button should tick this frame
# based on location and always_tick.
    def button_can_tick?(button)
        button.always_tick || location_match?(button.location)
    end

# == Actors ==
# ------------------------------------------------------------
# create_actor
# Registers a background ticking entity.
#
# Optional location restricts where it ticks.
# Optional on_tick_proc overrides implicit <id>_tick dispatch with a lambda.
#
# Implicit callback:
#   <id>_tick
# ------------------------------------------------------------
    def create_actor id, ticks_total=60, location=nil, always_tick=nil
        @actors[id] = {
                    location: location,
                    always_tick: always_tick,
                    ticks_total: ticks_total,
                    ticks_remaining: ticks_total,
                    on_tick: "#{id}_tick".to_sym,
                    on_tick_proc: nil,
            }
    end

# Returns true if the actor should tick this frame
# based on location and always_tick.
    def actor_can_tick?(actor)
        actor.always_tick || location_match?(actor.location)
    end

# == Resources ==
# ------------------------------------------------------------
# ensure_resource
# Registers a resource entry if it does not exist.
#
# Resources track value, label, and visibility.
# ------------------------------------------------------------
    def ensure_resource(resource, show = true)
        if !@values.key?(resource)
            @values[resource] = {value: 0, label: resource.to_s.capitalize, show: show}
        end
    end

# ------------------------------------------------------------
# generate_resource
# Increases a resource value.
# ------------------------------------------------------------
    def generate_resource(resource, qty=1, show=true)
        ensure_resource(resource, show)
        @values[resource].value+= qty
    end

# ------------------------------------------------------------
# set_resource
# Sets a resource to an explicit value.
# ------------------------------------------------------------
    def set_resource(resource, qty, show=true)
        ensure_resource(resource, show)
        @values[resource].value = qty
    end

# ------------------------------------------------------------
# get_resource
# Returns the current value of a resource.
# ------------------------------------------------------------
    def get_resource(resource)
        ensure_resource(resource)
        return @values[resource].value
    end

# ------------------------------------------------------------
# use_resource
# Attempts to subtract from a resource.
#
# Returns false if insufficient quantity.
# ------------------------------------------------------------
    def use_resource(resource, qty=1)
        ensure_resource(resource)
        if @values[resource].value < qty
            return false
        end
        @values[resource].value -= qty
        return true
    end

# ------------------------------------------------------------
# set_resource_label
# Updates display label and optional visibility.
# ------------------------------------------------------------
    def set_resource_label(resource, label, show=nil)
        ensure_resource(resource)
        @values[resource].label = label
        if show != nil
            @values[resource].show = show
        end
    end

# == Unlocks ==
# ------------------------------------------------------------
# create_unlock
# Registers a boolean unlock flag.
# ------------------------------------------------------------
    def create_unlock(key)
        @unlocks[key] = false
    end

# ------------------------------------------------------------
# unlocked?
# Returns true if the unlock has been activated.
# ------------------------------------------------------------
    def unlocked?(key)
        @unlocks[key] == true
    end

# ------------------------------------------------------------
# unlock
# Activates an unlock flag.
#
# Dispatches optional:
#   <key>_unlocked
#
# Returns true if newly unlocked.
# ------------------------------------------------------------
    def unlock(key)
        if not unlocked?(key)
            @unlocks[key] = true
            if self.respond_to? "#{key}_unlocked".to_sym
                 self.send("#{key}_unlocked".to_sym)
            end
            return true
        end
        return false
    end

# == Logs ==
# ------------------------------------------------------------
# create_log
# Registers a message panel.
#
# Stores bounded message history.
# ------------------------------------------------------------
    def create_log id, x, y, w, h
        @logs[id] = {
                id: id,
                x: x, y: y, w: w, h: h,
                messages: [],
                max_messages: 50,
                padding: 8,
                line_height: 24,
                show: true
        }
    end

# ------------------------------------------------------------
# add_message
# Appends a message to a log.
#
# Old messages are truncated to max_messages.
# ------------------------------------------------------------
    def add_message(log_id, text, color=nil)
        log = @logs[log_id]
        return unless log

        c = color || { r: 230, g: 230, b: 230 }
        log.messages << {text: text, color: c}
        log.messages = log.messages.last(log.max_messages)
    end

# == Utilities ==
#-------------------------------------------------------------
# location_match
# Returns true if the location is either nil, an exactl match for the current location,
# or if it's a list that includes the current location
#-------------------------------------------------------------
    def location_match?(location)
        if location.nil?
            return true
        elsif location.is_a?(Symbol)
            return location == @location
        elsif location.is_a?(Array)
            return location.include?(@location)
        end
        return false
    end

# ------------------------------------------------------------
# wrap_text
# Splits text into lines constrained by pixel width.
#
# Uses GTK string measurement for accuracy.
# ------------------------------------------------------------
    def wrap_text(text, max_width_px, size_px=14, font=nil)
        words = text.split(" ")
        lines = []
        current_line = ""

        words.each do |word|
            test_line = current_line.empty? ? word : "#{current_line} #{word}"

            w, _h = @args.gtk.calcstringbox(test_line, size_px: size_px, font: font)

            if w <= max_width_px
                current_line = test_line
            else
                lines << current_line unless current_line.empty?
                current_line = word
            end
        end

        lines << current_line unless current_line.empty?

        lines
    end

# ------------------------------------------------------------
# save_game
# Save all current game state for later recall
#
# Uses GTK serialize to store a collection in a file
# ------------------------------------------------------------
    def save_game filename='game_state.txt'
        state = {
            running: @running,
            location: @location,
            unlocks: @unlocks,
            buttons: @buttons,
            actors: @actors,
            values: @values,
            logs: @logs
        }
        GTK.serialize_state(filename, state)
    end

# ------------------------------------------------------------
# load_game
# Retore the current game state from a file
# ------------------------------------------------------------
    def load_game filename='game_state.txt'
        parsed_state = GTK.deserialize_state(filename)
        if !parsed_state
            puts "No saved game present"
        else
            @running = parsed_state[:running]
            @location = parsed_state[:location]
            @unlocks = parsed_state[:unlocks]
            @buttons = parsed_state[:buttons]
            @actors = parsed_state[:actors]
            @values = parsed_state[:values]
            @logs = parsed_state[:logs]
        end
    end
end
