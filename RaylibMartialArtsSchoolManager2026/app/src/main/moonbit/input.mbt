///|
fn clear_input(game : Game) -> Unit {
  game.input.move_x = 0
  game.input.move_y = 0
  game.input.confirm_pressed = false
  game.input.cancel_pressed = false
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
    game.input.move_x = game.input.move_x - 1
  }
  if @raylib.is_key_pressed(@raylib.KeyRight) ||
    @raylib.is_key_pressed(@raylib.KeyD) {
    game.input.move_x = game.input.move_x + 1
  }
  if @raylib.is_key_pressed(@raylib.KeyUp) ||
    @raylib.is_key_pressed(@raylib.KeyW) {
    game.input.move_y = game.input.move_y - 1
  }
  if @raylib.is_key_pressed(@raylib.KeyDown) ||
    @raylib.is_key_pressed(@raylib.KeyS) {
    game.input.move_y = game.input.move_y + 1
  }

  game.input.confirm_pressed = @raylib.is_key_pressed(@raylib.KeyJ)
  game.input.cancel_pressed = @raylib.is_key_pressed(@raylib.KeyK)
  game.input.burst_pressed = @raylib.is_key_pressed(@raylib.KeySpace)
  game.input.pause_pressed = @raylib.is_key_pressed(@raylib.KeyP)
  game.input.restart_pressed = @raylib.is_key_pressed(@raylib.KeyR)
  game.input.start_pressed = @raylib.is_key_pressed(@raylib.KeyEnter) ||
    game.input.confirm_pressed

  // Touch controls
  let m = @raylib.get_mouse_position()
  let ctl_x = 20
  let ctl_y = screen_h - 176
  let action_x = screen_w - 206
  let action_y = screen_h - 154
  if @raylib.is_mouse_button_pressed(@raylib.MouseButtonLeft) {
    if inside_rect(m.x, m.y, ctl_x, ctl_y, 74, 54) {
      game.input.move_x = game.input.move_x - 1
    }
    if inside_rect(m.x, m.y, ctl_x + 82, ctl_y, 74, 54) {
      game.input.move_x = game.input.move_x + 1
    }
    if inside_rect(m.x, m.y, ctl_x, ctl_y + 60, 74, 54) {
      game.input.move_y = game.input.move_y - 1
    }
    if inside_rect(m.x, m.y, ctl_x + 82, ctl_y + 60, 74, 54) {
      game.input.move_y = game.input.move_y + 1
    }
    if inside_rect(m.x, m.y, action_x, action_y, 176, 120) {
      game.input.confirm_pressed = true
      game.input.start_pressed = true
    }
  }
}
