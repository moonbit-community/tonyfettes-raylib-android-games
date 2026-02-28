///|
let screen_width : Int = 960

///|
let screen_height : Int = 640

///|
let pi : Float = 3.141592653589793

///|
let bullet_max : Int = 80

///|
let rock_max : Int = 96

///|
fn inside_rect(px : Float, py : Float, rx : Int, ry : Int, rw : Int, rh : Int) -> Bool {
  px >= Float::from_int(rx) && px <= Float::from_int(rx + rw) &&
  py >= Float::from_int(ry) && py <= Float::from_int(ry + rh)
}
