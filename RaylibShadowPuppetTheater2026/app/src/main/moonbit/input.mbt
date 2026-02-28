///|
fn clear_input(game : Game) -> Unit {
  game.input.axis_dx = 0
  game.input.axis_dy = 0
  game.input.lock_pressed = false
  game.input.undo_pressed = false
  game.input.burst_pressed = false
  game.input.pause_pressed = false
  game.input.restart_pressed = false
  game.input.start_pressed = false
}

///|
fn sample_input(game : Game) -> Unit {
  clear_input(game)

  if @raylib.is_key_pressed(@raylib.KeyLeft) ||
    @raylib.is_key_pressed(@raylib.KeyA) {
    game.input.axis_dx = game.input.axis_dx - 1
  }
  if @raylib.is_key_pressed(@raylib.KeyRight) ||
    @raylib.is_key_pressed(@raylib.KeyD) {
    game.input.axis_dx = game.input.axis_dx + 1
  }
  if @raylib.is_key_pressed(@raylib.KeyUp) ||
    @raylib.is_key_pressed(@raylib.KeyW) {
    game.input.axis_dy = game.input.axis_dy - 1
  }
  if @raylib.is_key_pressed(@raylib.KeyDown) ||
    @raylib.is_key_pressed(@raylib.KeyS) {
    game.input.axis_dy = game.input.axis_dy + 1
  }

  game.input.lock_pressed = @raylib.is_key_pressed(@raylib.KeyJ)
  game.input.undo_pressed = @raylib.is_key_pressed(@raylib.KeyK)
  game.input.burst_pressed = @raylib.is_key_pressed(@raylib.KeySpace)
  game.input.pause_pressed = @raylib.is_key_pressed(@raylib.KeyP)
  game.input.restart_pressed = @raylib.is_key_pressed(@raylib.KeyR)

  game.input.start_pressed = @raylib.is_key_pressed(@raylib.KeyEnter) ||
    @raylib.is_key_pressed(@raylib.KeyJ) ||
    @raylib.is_key_pressed(@raylib.KeySpace)

  // Touch controls
  let m = @raylib.get_mouse_position()
  let sw = screen_w
  let sh = screen_h
  let ctl_x = 20
  let ctl_y = sh - 176
  let action_x = sw - 206
  let action_y = sh - 154
  if @raylib.is_mouse_button_pressed(@raylib.MouseButtonLeft) {
    if inside_rect(m.x, m.y, ctl_x, ctl_y, 74, 54) { game.input.axis_dx = game.input.axis_dx - 1 }
    if inside_rect(m.x, m.y, ctl_x + 82, ctl_y, 74, 54) { game.input.axis_dx = game.input.axis_dx + 1 }
    if inside_rect(m.x, m.y, ctl_x, ctl_y + 60, 74, 54) { game.input.axis_dy = game.input.axis_dy - 1 }
    if inside_rect(m.x, m.y, ctl_x + 82, ctl_y + 60, 74, 54) { game.input.axis_dy = game.input.axis_dy + 1 }
    if inside_rect(m.x, m.y, action_x, action_y, 176, 120) {
      game.input.lock_pressed = true
      game.input.start_pressed = true
    }
  }
}
