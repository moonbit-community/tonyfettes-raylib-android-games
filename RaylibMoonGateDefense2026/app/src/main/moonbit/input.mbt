///|
fn clear_input(game : Game) -> Unit {
  game.input_move_x = 0
  game.input_move_y = 0
  game.input_place_press = false
  game.input_cancel_press = false
  game.input_barrier_press = false
  game.input_pause_press = false
  game.input_restart_press = false
}

///|
fn update_input(game : Game) -> Unit {
  clear_input(game)

  if @raylib.is_key_pressed(@raylib.KeyA) ||
    @raylib.is_key_pressed(@raylib.KeyLeft) {
    game.input_move_x = game.input_move_x - 1
  }
  if @raylib.is_key_pressed(@raylib.KeyD) ||
    @raylib.is_key_pressed(@raylib.KeyRight) {
    game.input_move_x = game.input_move_x + 1
  }
  if @raylib.is_key_pressed(@raylib.KeyW) ||
    @raylib.is_key_pressed(@raylib.KeyUp) {
    game.input_move_y = game.input_move_y - 1
  }
  if @raylib.is_key_pressed(@raylib.KeyS) ||
    @raylib.is_key_pressed(@raylib.KeyDown) {
    game.input_move_y = game.input_move_y + 1
  }

  game.input_place_press = @raylib.is_key_pressed(@raylib.KeyJ)
  game.input_cancel_press = @raylib.is_key_pressed(@raylib.KeyK)
  game.input_barrier_press = @raylib.is_key_pressed(@raylib.KeySpace)
  game.input_pause_press = @raylib.is_key_pressed(@raylib.KeyP)
  game.input_restart_press = @raylib.is_key_pressed(@raylib.KeyR)

  // Touch controls
  let m = @raylib.get_mouse_position()
  let ctl_x = 20
  let ctl_y = screen_h - 176
  let action_x = screen_w - 206
  let action_y = screen_h - 154
  if @raylib.is_mouse_button_pressed(@raylib.MouseButtonLeft) {
    if inside_rect(m.x, m.y, ctl_x, ctl_y, 74, 54) {
      game.input_move_x = game.input_move_x - 1
    }
    if inside_rect(m.x, m.y, ctl_x + 82, ctl_y, 74, 54) {
      game.input_move_x = game.input_move_x + 1
    }
    if inside_rect(m.x, m.y, ctl_x, ctl_y + 60, 74, 54) {
      game.input_move_y = game.input_move_y - 1
    }
    if inside_rect(m.x, m.y, ctl_x + 82, ctl_y + 60, 74, 54) {
      game.input_move_y = game.input_move_y + 1
    }
    if inside_rect(m.x, m.y, action_x, action_y, 176, 120) {
      game.input_place_press = true
    }
  }
}
