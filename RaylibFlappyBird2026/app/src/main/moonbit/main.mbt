///|
priv struct Bird {
  mut y : Float
  mut velocity : Float
}

///|
priv struct Pipe {
  mut x : Float
  mut gap_y : Float
  mut scored : Bool
}

///|
priv struct Game {
  sw : Float
  sh : Float
  bird_x : Float
  bird : Bird
  bird_radius : Float
  gravity : Float
  jump_force : Float
  pipes : Array[Pipe]
  pipe_width : Float
  gap_size : Float
  pipe_speed : Float
  pipe_spacing : Float
}

///|
fn Bird::reset(self : Bird, sh : Float) -> Unit {
  self.y = sh / 2.0
  self.velocity = 0.0
}

///|
fn Bird::update(
  self : Bird,
  gravity : Float,
  radius : Float,
  sh : Float,
  dt : Float,
) -> Unit {
  self.velocity += gravity * dt
  self.y += self.velocity * dt
  if self.y < radius {
    self.y = radius
    self.velocity = 0.0
  }
  if self.y > sh - radius {
    self.y = sh - radius
    self.velocity = 0.0
  }
}

///|
fn Bird::draw(self : Bird, x : Float, radius : Float) -> Unit {
  @raylib.draw_circle_v(
    @raylib.Vector2::new(x, self.y),
    radius,
    @raylib.yellow,
  )
}

///|
fn Pipe::draw(self : Pipe, width : Float, gap_size : Float) -> Unit {
  let px = self.x.to_int()
  let pw = width.to_int()
  let gap_top = (self.gap_y - gap_size / 2.0).to_int()
  let gap_bottom = (self.gap_y + gap_size / 2.0).to_int()
  @raylib.draw_rectangle(px, 0, pw, gap_top, @raylib.darkgreen)
  @raylib.draw_rectangle(
    px,
    gap_bottom,
    pw,
    @raylib.get_screen_height() - gap_bottom,
    @raylib.darkgreen,
  )
}

///|
fn Pipe::reset(self : Pipe, x : Float, game : Game) -> Unit {
  self.x = x
  self.gap_y = random_gap_y(game)
  self.scored = false
}

///|
fn random_gap_y(game : Game) -> Float {
  Float::from_int(
    @raylib.get_random_value(
      (game.gap_size / 2.0 + 50.0).to_int(),
      (game.sh - game.gap_size / 2.0 - 50.0).to_int(),
    ),
  )
}

///|
fn reset(game : Game) -> Unit {
  game.bird.reset(game.sh)
  for i in 0..<game.pipes.length() {
    game.pipes[i].reset(game.sw + Float::from_int(i) * game.pipe_spacing, game)
  }
}

///|
fn update(game : Game, dt : Float) -> Unit {
  if @raylib.is_gesture_detected(@raylib.GestureTap) {
    game.bird.velocity = game.jump_force
  }
  game.bird.update(game.gravity, game.bird_radius, game.sh, dt)

  // Move pipes left; recycle off-screen pipes to the right
  for pipe in game.pipes {
    pipe.x -= game.pipe_speed * dt
    if pipe.x < -game.pipe_width {
      pipe.reset(
        pipe.x + Float::from_int(game.pipes.length()) * game.pipe_spacing,
        game,
      )
    }
  }
}

///|
fn draw(game : Game) -> Unit {
  @raylib.begin_drawing()
  @raylib.clear_background(@raylib.skyblue)
  for pipe in game.pipes {
    pipe.draw(game.pipe_width, game.gap_size)
  }
  game.bird.draw(game.bird_x, game.bird_radius)
  @raylib.end_drawing()
}

///|
fn main {
  @raylib.init_window(0, 0, "Flappy Bird")
  @raylib.set_target_fps(60)
  @raylib.set_exit_key(0)
  let sw = Float::from_int(@raylib.get_screen_width())
  let sh = Float::from_int(@raylib.get_screen_height())

  let pipe_count = 4
  let game : Game = {
    sw,
    sh,
    bird_x: sw * 0.2,
    bird: { y: 0.0, velocity: 0.0 },
    bird_radius: sh / 25.0,
    gravity: sh * 1.5,
    jump_force: sh * -0.65,
    pipe_width: sh / 8.0,
    gap_size: sh / 4.0,
    pipe_speed: sw / 6.0,
    pipe_spacing: sw / 3.0,
    pipes: Array::makei(pipe_count, fn(_) {
      { x: 0.0, gap_y: 0.0, scored: false }
    }),
  }
  reset(game)

  while not(@raylib.window_should_close()) {
    let dt = @raylib.get_frame_time()
    update(game, dt)
    draw(game)
  }
  @raylib.close_window()
}
