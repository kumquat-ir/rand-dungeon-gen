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
#			- force: 0 - 5
#7: 	beyond door
#8: 	chamber
#9: 	chamber exit
#10:	stairs
#11:	choose passage
#12:	choose side passage
var genHooks:Array = [
	[
		[0, 0, 0, 1], [3]
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

func _process(_delta):
	if Input.is_action_just_pressed("ui_accept"):
		genStep()

func roll(sides:int, omit:Array = []) -> int:
	var vals:Array = range(sides)
	for i in omit:
		if i - 1 in vals:
			vals.remove(vals.find(i - 1))
	return -1 if len(vals) < 1 else vals[rng.randi_range(0, len(vals) - 1)] + 1

# ----- ACTUAL GENERATION -----

func genStep():
	if len(genHooks) == 0:
		print("no hooks left to generate")
		return 1
	if len(genHooks[0]) != 2 or len(genHooks[0][0]) != 4 or len(genHooks[0][1]) < 1:
		printerr("malformed hook " + str(genHooks[0]) + ", removing")
		genHooks.remove(0)
		return 0
	var x = genHooks[0][0][0]
	var y = genHooks[0][0][1]
	var z = genHooks[0][0][2]
	var symbol = genHooks[0][0][3]
	var dir = genHooks[0][1][0]
	match symbol:
		0:
			print("generating start room at " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
			genStart(x, y, z, dir)
		1:
			print("generating 5ft passage at " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
			gen5pass(x, y, z, dir)
		2:
			print("generating 10ft passage at " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
			gen10pass(x, y, z, dir)
		3:
			print("generating 20ft passage at " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
			gen20pass(x, y, z, dir)
		4:
			print("generating 30ft passage at " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
			gen30pass(x, y, z, dir)
		5:
			if len(genHooks[0][1] != 4):
				printerr("malformed 40ft passage hook " +  str(genHooks[0]) + ", removing")
			else:
				var pillars = genHooks[0][1][1]
				var h = genHooks[0][1][2]
				var gallery = genHooks[0][1][2]
				print("generating 40ft passage (" + str(pillars) + "/" + str(h) + "/" + str(gallery) +
						") at " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
				gen40pass(x, y, z, dir, pillars, h, gallery)
		6:
			print("generating door at " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
			if len(genHooks[0][1]) == 2:
				var force = genHooks[0][1][1]
				print("forcing door type " + str(force))
				genDoor(x, y, z, dir, force)
			else:
				genDoor(x, y, z, dir)
		7:
			print("generating beyond door at " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
			genPastDoor(x, y, z, dir)
		8:
			print("generating chamber at " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
			genRoom(x, y, z, dir)
		9:
			print("generating chamber exit at " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
			genRoomExit(x, y, z, dir)
		10:
			print("generating stairs at " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
			genStairs(x, y, z, dir)
		11:
			print("choosing passage for " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
			choosePass(x, y, z, dir)
		12:
			print("choosing side passage for " + str(x) +  "/" + str(y) + "/" + str(z) + "|" + str(dir))
			chooseSidePass(x, y, z, dir)
		_:
			printerr("found unknown gen symbol " + str(symbol) + " at " + str(x) + 
					"/" + str(y) + "/" + str(z) + "|" + str(dir) + ", removing")
	genHooks.remove(0)
	return 0

func genStart(x:int, y:int, z:int, dir:int):
	pass

func gen5pass(x:int, y:int, z:int, dir:int):
	var exclude = [2, 3, 4, 6, 7, 8, 9, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20]
	var bounds = dirSum2([3, 6, 0, 0], dir)
	var origin = dirSum2([0, 0, 1, 0], dir)
	if not checkArray(prismArray(bounds[0], 3, bounds[1], origin[0] + x, y, origin[1] + z)):
		exclude.append(1)
		exclude.append(5)
	match roll(20, exclude):
		1:
			print("30ft straight, continue")
#			bounds = dirSum2([3, 7, 0, 0], dir)
#			origin = dirSum2([0, 0, 1, 0], dir)
#			$tiles.setPlane(PLANE_XZ, bounds[0], bounds[1], origin[0] + x, y - 1, origin[1] + z, 2)
#			bounds = dirSum2([0, 6, 0, 0], dir)
#			$tiles.setPrism(bounds[0], 2, bounds[1], origin[0] + x, y, origin[1] + z, 1)
#			origin = dirSum2([1, 0, 0, 0], dir)
#			$tiles.setPrism(bounds[0], 2, bounds[1], origin[0] + x, y, origin[1] + z, 1)
#			bounds = dirSum2([5, 6, 0, 0], dir)
#			origin = dirSum2([0, 0, 2, 0], dir)
#			$"tile-metadata".setPrism(bounds[0], 2, bounds[1], origin[0] + x, y, origin[1] + z, 1)
			passageBase([3, 7, 0, 0], x, y, z, dir)
#			var disp = dirSum2([0, 6, 0, 0], dir)
#			genHooks.append([
#				[disp[0] + x, y, disp[1] + z, 1],
#			[dir]])
			newHooks([[0, 6, 0, 0]], [1], x, y, z, dir)
		5:
			print("20ft straight to door")
			passageBase([3, 5, 0, 0], x, y, z, dir)
			newHooks([[0, 4, 0, 0]], [6], x, y, z, dir)
		10:
			print("20ft straight to possible secret door")
			passageBase([3, 5, 0, 0], x, y, z, dir)
			if roll(10) == 10:
				newHooks([[0, 4, 0, 0]], [6], x, y, z, dir, [[5]])
			else:
				bounds = dirSum2([3, 0, 0, 0], dir)
				origin = dirSum2([0, 4, 1, 0], dir)
				$tiles.setPrism(bounds[0], 2, bounds[1], origin[0] + x, y, origin[1] + z, 1)
				bounds = dirSum2([5, 2, 0, 0], dir)
				origin = dirSum2([0, 4, 2, 0], dir)
				$"tile-metadata".setPrism(bounds[0], 2, bounds[1], origin[0] + x, y, origin[1] + z, 1)
		_:
			print("no space for anything")

func gen10pass(x:int, y:int, z:int, dir:int):
	pass

func gen20pass(x:int, y:int, z:int, dir:int):
	pass

func gen30pass(x:int, y:int, z:int, dir:int):
	pass

func gen40pass(x:int, y:int, z:int, dir:int, pillar:int, h:int, gallery:bool):
	pass

#forces:
#	0: none
#	1: wooden
#	2: stone
#	3: iron
#	4: portcullis
#	5: secret
#will probably only use secret, including others for completion
func genDoor(x:int, y:int, z:int, dir:int, force:int = 0):
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

# ----- GENERATION HELPERS -----

func passageBase(fbounds:Array, x:int, y:int, z:int, dir:int, h:int = 2):
	var bounds = dirSum2(fbounds, dir)
	var origin = dirSum2([0, 0, 1, 0], dir)
	$tiles.setPlane(PLANE_XZ, bounds[0], bounds[1], origin[0] + x, y - 1, origin[1] + z, 2)
	bounds = dirSum2([0, fbounds[1] - 1, 0, 0], dir)
	$tiles.setPrism(bounds[0], 2, bounds[1], origin[0] + x, y, origin[1] + z, 1)
	origin = dirSum2([fbounds[0] - 2, 0, 0, 0], dir)
	$tiles.setPrism(bounds[0], 2, bounds[1], origin[0] + x, y, origin[1] + z, 1)
	bounds = dirSum2([fbounds[0] + 2, fbounds[1] - 1, 0, 0], dir)
	origin = dirSum2([0, 0, 2, 0], dir)
	$"tile-metadata".setPrism(bounds[0], 2, bounds[1], origin[0] + x, y, origin[1] + z, 1)

func newHooks(disps:Array, vals:Array, x:int, y:int, z:int, dir:int, extras:Array = [[]]):
	for i in len(disps):
		var disp = dirSum2(disps[i], dir)
		var arr2 = [dir]
		for extra in extras[i]:
			arr2.append(extra)
		genHooks.append([
			[disp[0] + x, y, disp[1] + z, vals[i]],
		arr2])

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

# ----- DIRECTION HANDLING -----

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

#probably won't end up using this one, less flexible
func dirSum1(amts:Array, xz: int, dir:int) -> int:
	return right(amts[0], dir)[xz] + forward(amts[1], dir)[xz] + left(amts[2], dir)[xz] + back(amts[3], dir)[xz]

func dirSum2(amts:Array, dir:int) -> Array:
	var rgt = right(amts[0], dir)
	var fwd = forward(amts[1], dir)
	var lft = left(amts[2], dir)
	var bck = back(amts[3], dir)
	return [rgt[0] + fwd[0] + lft[0] + bck[0], rgt[1] + fwd[1] + lft[1] + bck[1]]
