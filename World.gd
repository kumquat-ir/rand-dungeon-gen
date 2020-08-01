extends Spatial

#FORMAT: [
# [
#  [x, y, z, value],
#  [dir, additional data...]
# ],[ ... ]
#]
#VALUES:
#dir is index in RULD (+x +z -x -z)
#0: 	starting room
#1: 	5ft passage
#2:		10ft passage
#3: 	20ft passage
#4:		30ft passage
#5: 	40ft passage
#			- pillar count: 0, 1, 2
#			- height: 10, 20
#			- gallery: true, false
#6: 	door
#7: 	beyond door
#8: 	chamber
#9: 	chamber exit
#10:	stairs
#11:	choose passage
#12:	choose side passage
var genHooks:Array = [
	[
		[0, 0, 0, 0], [0]
	]
]

var rng:RandomNumberGenerator = RandomNumberGenerator.new()
var setSeed = null #for testing

func _ready():
	if setSeed == null:
		rng.randomize()
	else:
		rng.set_seed(hash(setSeed))

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		genStep()

func roll(sides:int, omit:Array = []) -> int:
	var vals:Array = range(sides)
	for i in omit:
		if i - 1 in vals:
			vals.remove(vals.find(i - 1))
	return vals[rng.randi_range(0, len(vals) - 1)] + 1

func genStep():
	if len(genHooks) == 0:
		print("no hooks left to generate")
		return
	#proper hooks will stop evaluating on the first statement
	#short-circuit eval ftw
	if len(genHooks[0]) != 2 or len(genHooks[0][0]) != 4 or len(genHooks[0][1]) < 1:
		printerr("malformed hook " + str(genHooks[0]) + ", removing")
		genHooks.remove(0)
		return
	var x = genHooks[0][0][0]
	var y = genHooks[0][0][1]
	var z = genHooks[0][0][2]
	var symbol = genHooks[0][0][3]
	var dir = genHooks[0][1][0]
	match symbol:
		0:
			print("generating start room at " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
			genStart(x, y, z, dir)
		1:
			print("generating 5ft passage at " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
			gen5pass(x, y, z, dir)
		2:
			print("generating 10ft passage at " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
			gen10pass(x, y, z, dir)
		3:
			print("generating 20ft passage at " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
			gen20pass(x, y, z, dir)
		4:
			print("generating 30ft passage at " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
			gen30pass(x, y, z, dir)
		5:
			if len(genHooks[0][1] != 4):
				printerr("malformed 40ft passage hook " +  str(genHooks[0]) + ", removing")
			else:
				var pillars = genHooks[0][1][1]
				var h = genHooks[0][1][2]
				var gallery = genHooks[0][1][2]
				print("generating 40ft passage (" + str(pillars) + "/" + str(h) + "/" + str(gallery) +
						") at " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
				gen40pass(x, y, z, dir, pillars, h, gallery)
		6:
			print("generating door at " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
			genDoor(x, y, z, dir)
		7:
			print("generating beyond door at " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
			genPastDoor(x, y, z, dir)
		8:
			print("generating chamber at " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
			genRoom(x, y, z, dir)
		9:
			print("generating chamber exit at " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
			genRoomExit(x, y, z, dir)
		10:
			print("generating stairs at " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
			genStairs(x, y, z, dir)
		11:
			print("choosing passage for " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
			choosePass(x, y, z, dir)
		12:
			print("choosing side passage for " + str(x) +  "/" + str(y) + "/" + str(z) + "-" + str(dir))
			chooseSidePass(x, y, z, dir)
		_:
			printerr("found unknown gen symbol " + str(symbol) + " at " + str(x) + 
					"/" + str(y) + "/" + str(z) + "-" + str(dir) + ", removing")
	genHooks.remove(0)

func genStart(x:int, y:int, z:int, dir:int):
	pass

func gen5pass(x:int, y:int, z:int, dir:int):
	pass

func gen10pass(x:int, y:int, z:int, dir:int):
	pass

func gen20pass(x:int, y:int, z:int, dir:int):
	pass

func gen30pass(x:int, y:int, z:int, dir:int):
	pass

func gen40pass(x:int, y:int, z:int, dir:int, pillar:int, h:int, gallery:bool):
	pass

func genDoor(x:int, y:int, z:int, dir:int):
	pass

func genPastDoor(x:int, y:int, z:int, dir:int):
	pass

func genRoom(x:int, y:int, z:int, dir:int):
	pass

func genRoomExit(x:int, y:int, z:int, dir:int):
	pass

func genStairs(x:int, y:int, z:int, dir:int):
	pass

func choosePass(x:int, y:int, z:int, dir:int):
	pass

func chooseSidePass(x:int, y:int, z:int, dir:int):
	pass

#checks array of x/y/z coords to see if the space is open (tile-metadata is 0 or nonexistant)
#TODO don't use getCArrVal in getTileAt because that bloats the chunks' arrays a lot
func checkArray(arr:Array) -> bool:
	for coords in arr:
		if $"tile-metadata".getTileAt(coords[0], coords[1], coords[2]) != 0:
			return false
	return true

#to generate arrays for checkArray
func prismArray(lx:int, ly:int, lz:int, sx:int, sy:int, sz:int) -> Array:
	var arr = []
	for x in range(min(lx, 0), max(lx, 0)):
		for y in range(min(ly, 0), max(ly, 0)):
			for z in range(min(lz, 0), max(lz, 0)):
				arr.append([x + sx, y + sy, z + sz])
	return arr
