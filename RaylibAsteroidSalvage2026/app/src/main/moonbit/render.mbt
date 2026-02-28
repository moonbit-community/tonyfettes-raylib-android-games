///|
fn draw_starfield() -> Unit {
  for i = 0; i < 70; i = i + 1 {
    let x = (i * 97 + i * i * 7) % screen_width
    let y = (i * 53 + i * i * 11) % screen_height
    let c = if i % 3 == 0 { @raylib.darkgray } else { @raylib.gray }
    @raylib.draw_pixel(x, y, c)
  }
}

///|
fn draw_ship(game : Game) -> Unit {
  if game.ship_invuln > 0.0 {
    let blink = @raylib.get_time().to_int() % 2
    if blink == 0 {
      return
    }
  }

  let dir_x = Float::from_double(@math.cos(game.ship_angle.to_double()))
  let dir_y = Float::from_double(@math.sin(game.ship_angle.to_double()))
  let side_x = Float::from_double(
    @math.cos((game.ship_angle + pi * 0.75).to_double()),
  )
  let side_y = Float::from_double(
    @math.sin((game.ship_angle + pi * 0.75).to_double()),
  )
  let side2_x = Float::from_double(
    @math.cos((game.ship_angle - pi * 0.75).to_double()),
  )
  let side2_y = Float::from_double(
    @math.sin((game.ship_angle - pi * 0.75).to_double()),
  )

  let nose = @raylib.Vector2::new(
    game.ship_x + dir_x * 15.0,
    game.ship_y + dir_y * 15.0,
  )
  let left = @raylib.Vector2::new(
    game.ship_x + side_x * 10.0,
    game.ship_y + side_y * 10.0,
  )
  let right = @raylib.Vector2::new(
    game.ship_x + side2_x * 10.0,
    game.ship_y + side2_y * 10.0,
  )

  @raylib.draw_triangle_lines(nose, left, right, @raylib.raywhite)

  if @raylib.is_key_down(@raylib.KeyUp) || @raylib.is_key_down(@raylib.KeyW) {
    let back = @raylib.Vector2::new(
      game.ship_x - dir_x * 8.0,
      game.ship_y - dir_y * 8.0,
    )
    @raylib.draw_circle(back.x.to_int(), back.y.to_int(), 3.0, @raylib.orange)
  }
}

///|
fn draw_rocks(game : Game) -> Unit {
  for i = 0; i < game.rocks.length(); i = i + 1 {
    if not(game.rocks[i].active) {
      continue
    }
    let color = match game.rocks[i].size {
      2 => @raylib.lightgray
      1 => @raylib.gray
      _ => @raylib.darkgray
    }
    @raylib.draw_circle_lines(
      game.rocks[i].x.to_int(),
      game.rocks[i].y.to_int(),
      game.rocks[i].radius,
      color,
    )
    @raylib.draw_circle_lines(
      (game.rocks[i].x + 3.0).to_int(),
      (game.rocks[i].y - 2.0).to_int(),
      game.rocks[i].radius * 0.6,
      color,
    )
  }
}

///|
fn draw_bullets(game : Game) -> Unit {
  for i = 0; i < game.bullets.length(); i = i + 1 {
    if not(game.bullets[i].active) {
      continue
    }
    @raylib.draw_circle(
      game.bullets[i].x.to_int(),
      game.bullets[i].y.to_int(),
      2.4,
      @raylib.yellow,
    )
  }
}

///|
fn draw_hud(game : Game) -> Unit {
  @raylib.draw_text("ASTEROID SALVAGE 2026", 18, 14, 30, @raylib.skyblue)
  @raylib.draw_text("Score: \{game.score}", 18, 52, 24, @raylib.raywhite)
  @raylib.draw_text("Wave: \{game.wave}", 18, 80, 22, @raylib.raywhite)
  @raylib.draw_text("Lives: \{game.lives}", 18, 106, 22, @raylib.raywhite)

  @raylib.draw_text("A/D or <-/-> rotate", 690, 20, 18, @raylib.gray)
  @raylib.draw_text("W or UP thrust", 690, 42, 18, @raylib.gray)
  @raylib.draw_text("SPACE fire", 690, 64, 18, @raylib.gray)
  @raylib.draw_text("R restart", 690, 86, 18, @raylib.gray)

  if game.game_over {
    @raylib.draw_rectangle(250, 250, 460, 130, @raylib.fade(@raylib.black, 0.8))
    @raylib.draw_text("MISSION FAILED", 320, 284, 42, @raylib.red)
    @raylib.draw_text("Press R to restart", 360, 334, 28, @raylib.raywhite)
  }
}

///|
fn draw_game(game : Game) -> Unit {
  @raylib.begin_drawing()
  @raylib.clear_background(@raylib.Color::new(7, 9, 18, 255))
  draw_starfield()
  draw_rocks(game)
  draw_bullets(game)
  draw_ship(game)
  draw_hud(game)
  // Draw touch controls
  let sw = screen_width
  let sh = screen_height
  let ctl_x = 20
  let ctl_y = sh - 176
  @raylib.draw_rectangle(8, sh - 190, 160, 180, @raylib.Color::new(10, 16, 28, 220))
  @raylib.draw_text("Touch", 56, sh - 186, 20, @raylib.white)
  @raylib.draw_rectangle(ctl_x, ctl_y, 74, 54, @raylib.Color::new(46, 64, 90, 255))
  @raylib.draw_text("LEFT", ctl_x + 12, ctl_y + 18, 20, @raylib.white)
  @raylib.draw_rectangle(ctl_x + 82, ctl_y, 74, 54, @raylib.Color::new(46, 64, 90, 255))
  @raylib.draw_text("RIGHT", ctl_x + 86, ctl_y + 18, 20, @raylib.white)
  @raylib.draw_rectangle(ctl_x, ctl_y + 60, 74, 54, @raylib.Color::new(46, 64, 90, 255))
  @raylib.draw_text("UP", ctl_x + 20, ctl_y + 78, 20, @raylib.white)
  @raylib.draw_rectangle(ctl_x + 82, ctl_y + 60, 74, 54, @raylib.Color::new(46, 64, 90, 255))
  @raylib.draw_text("DOWN", ctl_x + 86, ctl_y + 78, 20, @raylib.white)
  let action_x = sw - 206
  let action_y = sh - 154
  @raylib.draw_rectangle(action_x, action_y, 176, 120, @raylib.Color::new(188, 82, 76, 255))
  @raylib.draw_text("FIRE", action_x + 42, action_y + 40, 38, @raylib.white)
  @raylib.end_drawing()
}
