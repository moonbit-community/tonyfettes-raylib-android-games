///|
let maze_cols : Int = 21

///|
let maze_rows : Int = 23

///|
let tile_size : Int = 24

///|
let maze_x : Int = 24

///|
let maze_y : Int = 24

///|
let hud_x : Int = maze_x + maze_cols * tile_size + 24

///|
let screen_width : Int = 760

///|
let screen_height : Int = 610

///|
fn inside_rect(px : Float, py : Float, rx : Int, ry : Int, rw : Int, rh : Int) -> Bool {
  px >= Float::from_int(rx) && px <= Float::from_int(rx + rw) &&
  py >= Float::from_int(ry) && py <= Float::from_int(ry + rh)
}
