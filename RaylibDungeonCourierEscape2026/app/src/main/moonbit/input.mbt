///|
fn clear_input(game : Game) -> Unit {
  game.input.move_x = 0.0
  game.input.move_y = 0.0
  game.input.interact_press = false
  game.input.smoke_press = false
  game.input.sprint_hold = false
  game.input.start_press = false
  game.input.retry_press = false
}

///|
fn update_input(game : Game) -> Unit {
  clear_input(game)

  let mut ix : Float = 0.0
  let mut iy : Float = 0.0

  if @raylib.is_key_down(@raylib.KeyA) || @raylib.is_key_down(@raylib.KeyLeft) {
    ix = ix - 1.0
  }
  if @raylib.is_key_down(@raylib.KeyD) || @raylib.is_key_down(@raylib.KeyRight) {
    ix = ix + 1.0
  }
  if @raylib.is_key_down(@raylib.KeyW) || @raylib.is_key_down(@raylib.KeyUp) {
    iy = iy - 1.0
  }
  if @raylib.is_key_down(@raylib.KeyS) || @raylib.is_key_down(@raylib.KeyDown) {
    iy = iy + 1.0
  }

  let len2 = ix * ix + iy * iy
  if len2 > 1.0 {
    let inv : Float = (1.0 : Float) / sqrtf(len2)
    ix = ix * inv
    iy = iy * inv
  }

  game.input.move_x = ix
  game.input.move_y = iy

  game.input.interact_press = @raylib.is_key_pressed(@raylib.KeyJ)
  game.input.smoke_press = @raylib.is_key_pressed(@raylib.KeyK)
  game.input.sprint_hold = @raylib.is_key_down(@raylib.KeySpace)

  game.input.start_press = @raylib.is_key_pressed(@raylib.KeyEnter) ||
    @raylib.is_key_pressed(@raylib.KeySpace) ||
    @raylib.is_key_pressed(@raylib.KeyJ)

  game.input.retry_press = @raylib.is_key_pressed(@raylib.KeyR) ||
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
      game.input.move_x = game.input.move_x - 1.0
    }
    if inside_rect(m.x, m.y, ctl_x + 82, ctl_y, 74, 54) {
      game.input.move_x = game.input.move_x + 1.0
    }
    if inside_rect(m.x, m.y, ctl_x, ctl_y + 60, 74, 54) {
      game.input.move_y = game.input.move_y - 1.0
    }
    if inside_rect(m.x, m.y, ctl_x + 82, ctl_y + 60, 74, 54) {
      game.input.move_y = game.input.move_y + 1.0
    }
  }
  if @raylib.is_mouse_button_pressed(@raylib.MouseButtonLeft) {
    if inside_rect(m.x, m.y, action_x, action_y, 176, 120) {
      game.input.interact_press = true
      game.input.start_press = true
      game.input.retry_press = true
    }
  }
  game.input.move_x = clampf(game.input.move_x, -1.0, 1.0)
  game.input.move_y = clampf(game.input.move_y, -1.0, 1.0)
}
