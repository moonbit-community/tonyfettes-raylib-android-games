///|
fn axis(negative : Bool, positive : Bool) -> Float {
  if negative && not(positive) {
    -1.0
  } else if positive && not(negative) {
    1.0
  } else {
    0.0
  }
}

///|
fn should_start_duel() -> Bool {
  let start = @raylib.is_key_pressed(@raylib.KeyEnter) ||
    @raylib.is_key_pressed(@raylib.KeyJ) ||
    @raylib.is_key_pressed(@raylib.KeyK) ||
    @raylib.is_key_pressed(@raylib.KeySpace)
  if start {
    return true
  }
  // Touch action button
  let m = @raylib.get_mouse_position()
  let action_x = screen_w - 206
  let action_y = screen_h - 154
  if @raylib.is_mouse_button_pressed(@raylib.MouseButtonLeft) {
    if inside_rect(m.x, m.y, action_x, action_y, 176, 120) {
      return true
    }
  }
  false
}

///|
fn update_input(game : Game, _dt : Float) -> Unit {
  if @raylib.is_key_pressed(@raylib.KeyR) {
    start_new_run(game)
    return
  }

  if game.state == state_title {
    if should_start_duel() {
      start_new_run(game)
    }
    return
  }

  if game.state == state_game_over {
    if should_start_duel() {
      start_new_run(game)
    }
    return
  }

  if game.state == state_paused {
    if @raylib.is_key_pressed(@raylib.KeyP) {
      game.state = state_playing
      set_message(game, "Duel resumed.", 0.8)
    }
    return
  }

  if @raylib.is_key_pressed(@raylib.KeyP) {
    game.state = state_paused
    set_message(game, "Paused.", 10.0)
    return
  }

  let left : Bool = @raylib.is_key_down(@raylib.KeyA) ||
    @raylib.is_key_down(@raylib.KeyLeft)
  let right : Bool = @raylib.is_key_down(@raylib.KeyD) ||
    @raylib.is_key_down(@raylib.KeyRight)
  let up : Bool = @raylib.is_key_down(@raylib.KeyW) ||
    @raylib.is_key_down(@raylib.KeyUp)
  let down : Bool = @raylib.is_key_down(@raylib.KeyS) ||
    @raylib.is_key_down(@raylib.KeyDown)

  game.move_x = axis(left, right)
  game.move_y = axis(up, down)

  // Touch D-pad movement
  let m = @raylib.get_mouse_position()
  let ctl_x = 20
  let ctl_y = screen_h - 176
  if @raylib.is_mouse_button_down(@raylib.MouseButtonLeft) {
    if inside_rect(m.x, m.y, ctl_x, ctl_y, 74, 54) { game.move_x = -1.0 }
    if inside_rect(m.x, m.y, ctl_x + 82, ctl_y, 74, 54) { game.move_x = 1.0 }
    if inside_rect(m.x, m.y, ctl_x, ctl_y + 60, 74, 54) { game.move_y = -1.0 }
    if inside_rect(m.x, m.y, ctl_x + 82, ctl_y + 60, 74, 54) { game.move_y = 1.0 }
  }
  // Touch action button - light attack
  let action_x = screen_w - 206
  let action_y = screen_h - 154
  if @raylib.is_mouse_button_pressed(@raylib.MouseButtonLeft) {
    if inside_rect(m.x, m.y, action_x, action_y, 176, 120) {
      ignore(try_player_attack(game, attack_light))
    }
  }

  if absf(game.move_x) + absf(game.move_y) > 0.01 {
    let facing = normalize(game.move_x, game.move_y)
    game.facing_x = facing.0
    game.facing_y = facing.1
  }

  if @raylib.is_key_pressed(@raylib.KeyJ) {
    ignore(try_player_attack(game, attack_light))
  }

  if @raylib.is_key_pressed(@raylib.KeyK) {
    ignore(try_player_attack(game, attack_heavy))
  }

  if @raylib.is_key_pressed(@raylib.KeyL) ||
    @raylib.is_key_pressed(@raylib.KeySpace) {
    ignore(trigger_parry_dash(game))
  }
}
