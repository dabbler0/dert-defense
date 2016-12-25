# MAGIC NUMBERS
VIEWPORT_HEIGHT = 400
VIEWPORT_WIDTH = 600

N_LANES = 6

PADDING = 10

SOLDIER_SIZE = VIEWPORT_HEIGHT / N_LANES - PADDING * 2
LANE_HEIGHT = VIEWPORT_HEIGHT / N_LANES

FRAMERATE = 60

SOLDIER_SPEED = 1

# SPRITE LOADING
SPRITES = {}

hidden = document.getElementById 'hidden'

loadAsset = (name) ->
  img = document.createElement 'img'
  img.src = "assets/#{name}.png"
  hidden.appendChild img

  SPRITES[name] = img

  return img

loadAsset 'soldier'
loadAsset 'gun'
loadAsset 'bullet'
loadAsset 'wall'
loadAsset 'turret'
loadAsset 'background'

# RENDERING
canvas = document.getElementById 'main'
ctx = canvas.getContext '2d'

class Vector
  constructor: (@x, @y) ->

  clone: -> new Vector @x, @y
  add: (other) -> @x += other.x; @y += other.y

class Sprite
  constructor: (@texture, @size, @pos, @rotation) ->

  render: ->
    ctx.save()

    ctx.translate @pos.x, @pos.y
    ctx.rotate @rotation
    ctx.drawImage @texture, 0, 0, @size.x, @size.y

    ctx.restore()

  tick: ->

drawBackground = ->
  for i in [0...N_LANES]
    for j in [0...canvas.width / LANE_HEIGHT]
      ctx.drawImage SPRITES.background, j * LANE_HEIGHT, i * LANE_HEIGHT, LANE_HEIGHT, LANE_HEIGHT

class World
  constructor: (@sprites) ->
    @downflag = []

  render: ->
    ctx.clearRect 0, 0, canvas.width, canvas.height

    do drawBackground

    @sprites.forEach (x) -> x.render()

class Soldier extends Sprite
  constructor: (@lane) ->
    super(SPRITES.soldier,
      new Vector(SOLDIER_SIZE, SOLDIER_SIZE),
      new Vector(0, @lane * LANE_HEIGHT + PADDING),
      0
    )

    @health = 5

  tick: ->
    @pos.x += SOLDIER_SPEED

    if @health <= 0
      CREDITS += 1
      WORLD.downflag.push @

    if canvas.width - @pos.x < (LANE_HEIGHT + @size.x)
      encountered = WORLD.sprites.filter((x) => ((x instanceof Wall) or (x instanceof Turret)) and x.lane is @lane)

      if encountered.length > 0
        encountered.forEach (x) -> WORLD.downflag.push x
        WORLD.downflag.push @

    if @pos.x > canvas.width
      do lose

class BasicGun extends Sprite
  constructor: ->
    super(SPRITES.gun,
      new Vector(SOLDIER_SIZE, SOLDIER_SIZE),
      new Vector(0, 5 * LANE_HEIGHT + PADDING),
      0
    )

    @lastShot = 0

  tick: (n) ->
    @pos.x = MOUSE_POS.x - @size.x / 2

    if n - @lastShot > 10 and LEFT_MOUSE_DOWN
      WORLD.sprites.push new Bullet(@pos.clone(), new Vector(0, -2))
      @lastShot = n

class Bullet extends Sprite
  constructor: (@pos, @vel) ->
    super(SPRITES.bullet,
      new Vector(SOLDIER_SIZE, SOLDIER_SIZE),
      @pos,
      0
    )

  tick: ->
    @pos.add(@vel)

    center = new Vector(
      @pos.x + @size.x / 2,
      @pos.y + @size.y / 2
    )

    for el in WORLD.sprites
      if el instanceof Soldier and
          el.pos.x < center.x < el.pos.x + el.size.x and
          el.pos.y < center.y < el.pos.y + el.size.y
        el.health -= 1
        WORLD.downflag.push @

class Wall extends Sprite
  constructor: (@lane) ->
    super(SPRITES.wall,
      new Vector(LANE_HEIGHT, LANE_HEIGHT),
      new Vector(canvas.width - LANE_HEIGHT, @lane * LANE_HEIGHT),
      0
    )

class Turret extends Sprite
  constructor: (@lane) ->
    super(SPRITES.turret,
      new Vector(LANE_HEIGHT, LANE_HEIGHT),
      new Vector(canvas.width - LANE_HEIGHT, @lane * LANE_HEIGHT),
      0
    )

    @lastFired = 0

  tick: (n) ->
    if n - @lastFired > 150
      WORLD.sprites.push new Bullet(@pos.clone(), new Vector(-1, 0))
      @lastFired = n

MOUSE_POS = new Vector(0, 0)

canvas.addEventListener 'mousemove', (event) ->
  MOUSE_POS.x = event.offsetX
  MOUSE_POS.y = event.offsetY

LEFT_MOUSE_DOWN = false
RIGHT_MOUSE_DOWN = false

canvas.addEventListener 'mousedown', (event) ->
  if event.which is 1
    LEFT_MOUSE_DOWN = true
  else if event.which is 2
    RIGHT_MOUSE_DOWN = true

  if canvas.width - event.offsetX < LANE_HEIGHT and CREDITS >= 5
    lane = Math.floor event.offsetY / LANE_HEIGHT
    walls = WORLD.sprites.filter((x) -> (x instanceof Wall) and x.lane is lane)
    turrets = WORLD.sprites.filter((x) -> (x instanceof Turret) and x.lane is lane)

    if walls.length > 0 and turrets.length is 0
      WORLD.sprites.push new Turret(lane)
      CREDITS -= 5

  console.log event.which

canvas.addEventListener 'mouseup', (event) ->
  if event.which is 1
    LEFT_MOUSE_DOWN = false
  else if event.which is 2
    RIGHT_MOUSE_DOWN = false

  console.log event.which

WORLD = new World([
  new BasicGun(),
  new Wall(0),
  new Wall(1),
  new Wall(2),
  new Wall(3),
  new Wall(4),
  new Wall(5)
])

N_TICKS = 0
LAST_SOLDIER = 0
NEXT_SOLDIER = (60 * Math.random() * 4 + 60)

LOST_YET = false

CREDITS = 5

tick = ->
  unless LOST_YET
    N_TICKS += 1

    setTimeout tick, 1000 / FRAMERATE

    WORLD.render()

    # Draw credits
    ctx.font = '20px Arial'
    ctx.fillStyle = '#FFF'
    ctx.fillText '$' + CREDITS, 0, 20

    WORLD.sprites.forEach (x) -> x.tick(N_TICKS)

    if N_TICKS - LAST_SOLDIER > NEXT_SOLDIER
      WORLD.sprites.push new Soldier(Math.floor Math.random() * 5)

      NEXT_SOLDIER = (60 * Math.random() * 4 + 60)
      LAST_SOLDIER = N_TICKS

    WORLD.sprites = WORLD.sprites.filter (x) -> x not in WORLD.downflag
    WORLD.downflag = []

do tick

lose = ->
  LOST_YET = true
  ctx.fillText 'YOU LOSE', canvas.width / 2 - ctx.measureText('YOU LOSE').width / 2, canvas.height / 2
