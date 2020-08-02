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

enum {AXIS_X, AXIS_Y, AXIS_Z}
enum {PLANE_YZ, PLANE_XZ, PLANE_XY}

func _ready():
	if setSeed == null:
		rng.randomize()
	else:
		rng.set_seed(hash(setSeed))
	for dir in range(4):
		var dsl = dirSum2([5, 2, 0, 0], dir)
		var dss = dirSum2([0, 4, 2, 0], dir)
		print(prismArray(dsl[0], 3, dsl[1], dss[0], 0, dss[1]))
		$tiles.setPrism(dsl[0], 3, dsl[1], dss[0], 0, dss[1], 2)
	$"tile-metadata".setLine(AXIS_Y, 20, 0, -10, 0, 1)
	$"tile-metadata".setLine(AXIS_X, 20, -10, 0, 0, 2)
	$"tile-metadata".setLine(AXIS_Z, 20, 0, 0, -10, 3)
	$"tile-metadata".setSingle(0, 0, 0, 0)

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
func checkArray(arr:Array) -> bool:
	for coords in arr:
		if $"tile-metadata".getTileAt(coords[0], coords[1], coords[2]) != 0:
			return false
	return true

#to generate arrays for checkArray
func prismArray(lx:int, ly:int, lz:int, sx:int, sy:int, sz:int) -> Array:
	var arr = []
	for x in range(min(lx + 1, 0), max(lx, 1)):
		for y in range(min(ly + 1, 0), max(ly, 1)):
			for z in range(min(lz + 1, 0), max(lz, 1)):
				arr.append([x + sx, y + sy, z + sz])
	return arr

func forward(amt:int, dir:int) -> Array:
	match dir:
		0:
			return [amt, 0]
		1:
			return [0, amt]
		2:
			return [-amt, 0]
		3:
			return [0, -amt]
	return [0, 0]

func right(amt:int, dir:int) -> Array:
	match dir:
		0:
			return [0, -amt]
		1:
			return [amt, 0]
		2:
			return [0, amt]
		3:
			return [-amt, 0]
	return [0, 0]

func left(amt:int, dir:int) -> Array:
	match dir:
		0:
			return [0, amt]
		1:
			return [-amt, 0]
		2:
			return [0, -amt]
		3:
			return [amt, 0]
	return [0, 0]

func back(amt:int, dir:int) -> Array:
	match dir:
		0:
			return [-amt, 0]
		1:
			return [0, -amt]
		2:
			return [amt, 0]
		3:
			return [0, amt]
	return [0, 0]

func dirSum1(amts:Array, xz: int, dir:int) -> int:
	return right(amts[0], dir)[xz] + forward(amts[1], dir)[xz] + left(amts[2], dir)[xz] + back(amts[3], dir)[xz]

func dirSum2(amts:Array, dir:int) -> Array:
	var rgt = right(amts[0], dir)
	var fwd = forward(amts[1], dir)
	var lft = left(amts[2], dir)
	var bck = back(amts[3], dir)
	return [rgt[0] + fwd[0] + lft[0] + bck[0], rgt[1] + fwd[1] + lft[1] + bck[1]]
