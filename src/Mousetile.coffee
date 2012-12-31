# Require this file to load the whole library

# Util
Util = imports.Mousetile.util
Constants = Util.Constants

# Sub-libraries
Draggable = imports.Mousetile.draggable

# Classes
Rect = undefined
Seam = undefined
Container = undefined
Region = undefined

# Don't leak temp variables
((namespace) ->
  RectLib = imports.Mousetile.rect
  Rect = RectLib.Rect

  SeamLib = imports.Mousetile.seam
  Seam = SeamLib.Seam

  ContainerLib = imports.Mousetile.container
  Container = ContainerLib.Container

  RegionLib = imports.Mousetile.region
  Region = RegionLib.Region

  Util.Log(namespace)
  print(namespace)
)(this)
