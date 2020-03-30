MultiBall = Class{__includes = Ball}

function MultiBall:init(skin, x, y, dy, dx)
    self.x = x
    self.y = y

    self.dy = dy
    self.dx = dx

    self.skin = skin

    self.width = 8
    self.height = 8

    self.sx = 1
    self.sy = 1

    self.remove = false

    self.size = 2
end

