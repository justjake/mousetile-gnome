###
  Colors
  Although there is no color class, these functions are proved as a way
  of constructing colors in a pleasant way
###

Clutter = imports.gi.Clutter
Util = imports.Mousetile.util

# Number utils
bound0 = (x, max) ->
  Math.min(Math.max(x, 0), max)

bound01 = (x, max) ->
  x = bound0(x, max)
  x / max

interpolate = {
  linear:  (begin, end, ratio = 0.5) ->
    distance = end - begin
    begin + distance * ratio
}

hash_to_string = (hash) ->
  res = "{"
  for k, v of hash
    res += " #{k}: #{v},"
  res += " }"

# color structs
rgba = (r = 0, g = 0, b = 0, a = 255) ->
  return {
    r: bound0(r, 255)
    g: bound0(g, 255)
    b: bound0(b, 255)
    a: bound0(a, 255)
  }

hsv = (h, s, v) ->
  res = {
    h: bound0(h, 360)
    s: bound0(s, 100)
    v: bound0(v, 100)
  }
  Util.Log("hsv: #{hash_to_string(res)}")
  return res



# See http://bgrins.github.com/TinyColor/docs/tinycolor.html
hsv_to_rgba = (hsv) ->
  h = bound01(hsv.h, 360) * 6
  s = bound01(hsv.s, 100)
  v = bound01(hsv.v, 100)

  i = Math.floor(h)
  f = h - i
  p = v * (1 - s)
  q = v * (1 - f * s)
  t = v * (1 - (1 - f) * s)
  mod = i % 6
  r = [v, q, p, p, t, v][mod]
  g = [t, v, v, q, p, p][mod]
  b = [p, p, t, v, v, q][mod]

  res = rgba(r * 255, g * 255, b * 255)
  Util.Log("rgba is #{hash_to_string(res)}")
  return res



if Util.is_gjs()
  to_native = (color) ->
    for k, v of color
      # ints only plz
      color[k] = Math.floor(v)

    new Clutter.Color {
      red: color.r
      green: color.g
      blue: color.b
      alpha: color.a
    }
else
  to_native = (color) ->
    "rgba(#{color.r},#{color.g},#{color.b},#{color.a/255})"


# Color series ################################################################

# from https://kuler.adobe.com/#themeID/2209535

student_portfolio = (steps) ->
  series_steps = Math.ceil(steps / 3)

  progression = (hue, stepNum) ->
    hsv(
      hue,
      interpolate.linear(30, 100, stepNum / series_steps),
      interpolate.linear(95, 40, stepNum / series_steps)
    )

  color_progression = (hue) ->
    step = 1
    ->
      progression(hue, step++)

  reds = color_progression(11)
  teals = color_progression(169)
  yellows = color_progression(56)

  calls = 0
  series = [reds, teals, yellows]

  get_next = ->
    series[calls++ % series.length]()

  return get_next

piet = (steps) ->
  series_steps = Math.ceil(steps / 7)

  primary = (hue, stepNum) ->
    hsv(
      hue,
      interpolate.linear(90, 100, stepNum / series_steps),
      interpolate.linear(100, 85, stepNum / series_steps)
    )

  light = (hue, stepNum) ->
    hsv(
      hue,
      interpolate.linear(0, 15, stepNum / series_steps),
      interpolate.linear(100, 90, stepNum / series_steps)
    )
  dark = (hue, stepNum) ->
    hsv(
      hue,
      interpolate.linear(0, 15, stepNum / series_steps),
      interpolate.linear(10, 3, stepNum / series_steps)
    )


  progress = (hue, type) ->
    step = 1
    ->
      type(hue, step++)

  reds = progress(15, primary)
  yellows = progress(56, primary)
  blues = progress(240, primary)
  lights = progress(200, light)
  darks = progress(200, dark)

  calls = 0
  series = [lights, lights, yellows, blues, lights, reds, lights, darks]

  get_next = ->
    series[calls++ % series.length]()

  return get_next

native_series = (fn) ->
  ->
    color = fn()
    rgb = hsv_to_rgba(color)
    to_native(rgb)

