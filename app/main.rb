require 'app/game.rb'
require 'app/mygame.rb'

def init args
    args.state.game = MyGame.new(args)
end


def tick args
    if args.state.tick_count == 0
        init args
    end

    args.state.game.tick()
    args.state.game.render()
    if not args.state.game.running
        args.outputs.primitives << {x:500, y:350, w:280, h:180, r:128, g:128, b:128}.solid
        args.outputs.primitives << {x:500, y:350, w:280, h:180, r:64, g:64, b:64}.border
        args.outputs.primitives << {x:600, y:450, w:280, h:180, text: "Game Over", r:0, g:0, b:0}.label
        args.outputs.primitives << {x:400, y:400, w:280, h:180, text: "Click or Press Space to Restart", r:0, g:0, b:0}.label
        if args.inputs.mouse.click or args.inputs.keyboard.space
            init(args)
        end
    end
end
