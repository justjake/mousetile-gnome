###
  Colors
  Although there is no color class, these functions are proved as a way
  of constructing colors in a pleasant way
###

Clutter = imports.gi.Clutter
Util = imports.Mousetile.util


shuffle = (arr) ->
  out = []
  while arr.length
    idx = Math.min(Math.floor(Math.random() * arr.length), arr.length - 1)
    out.push(
      arr.splice(idx, 1)[0]
    )
  out



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


parse_hex = (hex) ->
  r = parseInt(hex[1..2], 16)
  g = parseInt(hex[3..4], 16)
  b = parseInt(hex[5..6], 16)
  rgba(r, b, b)

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
tricolor = (steps) ->
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

# Mondrial-like colors
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

# zenburn colors
zenburn = (steps) ->
  # colors from zenburn.vim
  # https://github.com/jnurmine/Zenburn/blob/master/colors/zenburn.vim
  hex = [
    "#3f3f3f"
    "#dcdccc"
    #  black + red
    "#1E2320"
    "#705050"
    #  green + yellow
    "#60b48a"
    "#dfaf8f"
    #  blue + purple
    "#506070"
    "#dc8cc3"
    #  cyan + white
    "#8cd0d3"
    "#dcdccc"
    #  bright-black + bright-red
    "#709080"
    "#dca3a3"
    #  bright-green + bright-yellow
    "#c3bf9f"
    "#f0dfaf"
    #  bright-blue + bright-purple
    "#94bff3"
    "#ec93d3"
    #  bright-cyan + bright-white
    "#93e0e3"
    "#ffffff"
  ]
  colors = [
    { r: 223, g: 143, b: 143, a: 255, }
    { r: 140, g: 211, b: 211, a: 255, }
    { r: 195, g: 159, b: 159, a: 255, }
    { r: 112, g: 128, b: 128, a: 255, }
    { r: 63, g: 63, b: 63, a: 255, }
    { r: 255, g: 255, b: 255, a: 255, }
    { r: 220, g: 204, b: 204, a: 255, }
    { r: 240, g: 175, b: 175, a: 255, }
    { r: 96, g: 138, b: 138, a: 255, }
    { r: 147, g: 227, b: 227, a: 255, }
    { r: 148, g: 243, b: 243, a: 255, }
    { r: 80, g: 112, b: 112, a: 255, }
    { r: 112, g: 80, b: 80, a: 255, }
    { r: 220, g: 204, b: 204, a: 255, }
    { r: 236, g: 211, b: 211, a: 255, }
    { r: 220, g: 163, b: 163, a: 255, }
    { r: 30, g: 32, b: 32, a: 255, }
    { r: 220, g: 195, b: 195, a: 255, }
  ]

  # colors = shuffle(hex.map(parse_hex))

#  color_js_string = "hex = [\n"
#  for c in colors
#    color_js_string += "  #{hash_to_string(c)}\n"
#  Util.Log(color_js_string + ']')

  # standard incrementor guy
  calls = 0
  get_next = ->
    colors[calls++ % colors.length]

# dark colors
dark = (series_steps) ->
  dark = (hue, stepNum) ->
    hsv(
      hue,
      interpolate.linear(0, 15, stepNum / series_steps),
      interpolate.linear(20, 3, stepNum / series_steps)
    )

  progress = (hue, type) ->
    step = 1
    ->
      type(hue, step++)

  return progress(100, dark)



native_series = (fn) ->
  ->
    color = fn()
    # convert to RGB as needed
    color = hsv_to_rgba(color) if color.h?
    to_native(color)

