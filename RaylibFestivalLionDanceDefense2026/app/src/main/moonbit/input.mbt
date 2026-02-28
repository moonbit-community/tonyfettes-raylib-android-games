///|
fn clear_input(game : Game) -> Unit {
  game.input.move_x = 0
  game.input.move_y = 0
  game.input.press_strike = false
  game.input.press_guard = false
  game.input.press_burst = false
  game.input.press_pause = false
  game.input.press_restart = false
  game.input.press_start = false
}

///|
fn update_input(game : Game) -> Unit {
  clear_input(game)

  if @raylib.is_key_down(@raylib.KeyA) || @raylib.is_key_down(@raylib.KeyLeft) {
    game.input.move_x = game.input.move_x - 1
  }
  if @raylib.is_key_down(@raylib.KeyD) || @raylib.is_key_down(@raylib.KeyRight) {
    game.input.move_x = game.input.move_x + 1
  }
  if @raylib.is_key_down(@raylib.KeyW) || @raylib.is_key_down(@raylib.KeyUp) {
    game.input.move_y = game.input.move_y - 1
  }
  if @raylib.is_key_down(@raylib.KeyS) || @raylib.is_key_down(@raylib.KeyDown) {
    game.input.move_y = game.input.move_y + 1
  }

  game.input.move_x = clampi(game.input.move_x, -1, 1)
  game.input.move_y = clampi(game.input.move_y, -1, 1)

  game.input.press_strike = @raylib.is_key_pressed(@raylib.KeyJ)
  game.input.press_guard = @raylib.is_key_pressed(@raylib.KeyK)
  game.input.press_burst = @raylib.is_key_pressed(@raylib.KeySpace)
  game.input.press_pause = @raylib.is_key_pressed(@raylib.KeyP)
  game.input.press_restart = @raylib.is_key_pressed(@raylib.KeyR)

  game.input.press_start = game.input.press_strike ||
    @raylib.is_key_pressed(@raylib.KeyEnter) ||
    @raylib.is_key_pressed(@raylib.KeySpace)

  // Touch controls
  let m = @raylib.get_mouse_position()
  let ctl_x = 20
  let ctl_y = screen_h - 176
  let action_x = screen_w - 206
  let action_y = screen_h - 154
  if @raylib.is_mouse_button_down(@raylib.MouseButtonLeft) {
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
  }
  if @raylib.is_mouse_button_pressed(@raylib.MouseButtonLeft) {
    if inside_rect(m.x, m.y, action_x, action_y, 176, 120) {
      game.input.press_strike = true
      game.input.press_start = true
    }
  }
  game.input.move_x = clampi(game.input.move_x, -1, 1)
  game.input.move_y = clampi(game.input.move_y, -1, 1)
}
