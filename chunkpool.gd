extends Spatial

#this seems to be the fastest chunk size to deal with
export (int) var chunkSizeX:int = 8
export (int) var chunkSizeY:int = 8
export (int) var chunkSizeZ:int = 8
#which folder the chunks should look for mesh data in
export (String) var chunkGroup:String = "tiles"
var chunks:Array = []

enum {AXIS_X, AXIS_Y, AXIS_Z}
enum {PLANE_YZ, PLANE_XZ, PLANE_XY}

func _ready():
	pass
#	setPrism(5, 5, 5, -2, -2, -2, 1)
#	setPrism(3, 3, 3, -1, -1, -1, 2)
#	setSingle(0, 0, 0, 0)

#i really don't think i need this, keeping the base here in case i do
#doesn't actually work rn
func getWorldArr() -> Array:
	var worldArr:Array = []
	var cArrArr:Array = []
	chunks.sort_custom(sorter, "sortChunks")
	for chunkName in chunks:
		cArrArr.append(get_node("chunk at " + chunkName).getCArr())
	print(cArrArr)
	print(worldArr)
	return worldArr

func getTileAt(x:int, y:int, z:int) -> int:
	var chunkIn:Spatial = getChunk(normccoords(x, chunkSizeX), normccoords(y, chunkSizeY), normccoords(z, chunkSizeZ))
	if chunkIn.tileExists(normval(x, chunkSizeX), normval(y, chunkSizeY), normval(z, chunkSizeZ)):
		return chunkIn.getCArrVal(normval(x, chunkSizeX), normval(y, chunkSizeY), normval(z, chunkSizeZ))
	return 0

func updateFull():
	var cArrArr = []
	for child in get_children():
		if child.name.begins_with("chunk at "):
			#again, fixing weird messed-up names due to queue_free not being instant
			cArrArr.append(child.getCArr())
			child.set_name("FREED")
			child.queue_free()
	var chunksbk:Array = chunks
	chunks = []
	
	for i in len(chunksbk):
		var chunkcoords:PoolStringArray = chunksbk[i].split("_")
		getChunk(int(chunkcoords[0]), int(chunkcoords[1]), int(chunkcoords[2])).updateFull(cArrArr[i])

func updateChunk(x:int, y:int, z:int):
	getChunk(x, y, z).updateFull()

func updateTile(x:int, y:int, z:int):
	var chunkIn:Spatial = getChunk(normccoords(x, chunkSizeX), normccoords(y, chunkSizeY), normccoords(z, chunkSizeZ))
	chunkIn.updateTile(normval(x, chunkSizeX), normval(y, chunkSizeY), normval(z, chunkSizeZ))

#don't use this, makes chunk init take waaaay too long
func initChunkArr(with:int = 0) -> Array:
	var out:Array = []
	for i in chunkSizeX:
		out.append([])
		for j in chunkSizeY:
			out[i].append([])
			for k in chunkSizeZ:
				out[i][j].append(with)
	return out

func getChunk(x:int, y:int, z:int) -> Spatial:
	var chunkName:String = str(x) + "_" + str(y) + "_" + str(z)
	if chunkName in chunks:
		return get_node("chunk at " + chunkName) as Spatial
	var newchunkscene:PackedScene = preload("res://chunk.tscn")
	var newchunk = newchunkscene.instance()
	$".".add_child(newchunk)
	newchunk.set_name("chunk at " + chunkName)
	newchunk.chunkGroup = chunkGroup
	newchunk.updateFull([])
	newchunk.set_transform(Transform(Basis(), Vector3(x * chunkSizeX, y * chunkSizeY, z * chunkSizeZ)))
	chunks.append(chunkName)
	return newchunk

#normalize negative values of x, y, z to what they should be
func normval(val:int, normby:int) -> int:
	var nval:int = val % normby
	if val < 0:
		nval += normby
		nval %= normby
	return nval

#normalize negative values of x, y, z to provide the correct chunk coords
func normccoords(val:int, normby:int) -> int:
	if val < 0:
		val += 1
		val /= normby
		val -= 1
	else:
		val /= normby
	return val

func setSingle(x:int, y:int, z:int, nval:int):
	var chunkIn:Spatial = getChunk(normccoords(x, chunkSizeX), normccoords(y, chunkSizeY), normccoords(z, chunkSizeZ))
	chunkIn.setSingle(normval(x, chunkSizeX), normval(y, chunkSizeY), normval(z, chunkSizeZ), nval)

#set a rect. prism of tiles
#somehow this is the basic function for the other two
func setPrism(lx:int, ly:int, lz:int, sx:int, sy:int, sz:int, nval:int):
	for x in range(min(lx, 0), max(lx, 0)):
		for y in range(min(ly, 0), max(ly, 0)):
			for z in range(min(lz, 0), max(lz, 0)):
				setSingle(x + sx, y + sy, z + sz, nval)

#set a line of tiles along axis specified by AXIS_X, etc, starting at s[xyz]
func setLine(axis:int, length:int, sx:int, sy:int, sz:int, nval:int):
	var lx = 1
	var ly = 1
	var lz = 1
	match axis:
		AXIS_X:
			lx = length
		AXIS_Y:
			ly = length
		AXIS_Z:
			lz = length
		_:
			return
	setPrism(lx, ly, lz, sx, sy, sz, nval)

#set a plane of tiles on plane specified by PLANE_XY, etc, starting at s[xyz]
#length1 is first in pair (XY, XZ, YZ) and length2 is second
#may not end up using this one much
func setPlane(plane:int, length1:int, length2:int, sx:int, sy:int, sz:int, nval:int):
	var lx = 1
	var ly = 1
	var lz = 1
	match plane:
		PLANE_XY:
			lx = length1
			ly = length2
		PLANE_XZ:
			lx = length1
			lz = length2
		PLANE_YZ:
			ly = length1
			lz = length2
		_:
			return
	setPrism(lx, ly, lz, sx, sy, sz, nval)

#because default sort isn't good enough
class sorter:
	static func sortChunks(a:String, b:String) -> bool:
		var aArr:PoolStringArray = a.split("_", false)
		var bArr:PoolStringArray = b.split("_", false)
		if int(aArr[0]) < int(bArr[0]):
			return true
		elif int(aArr[0]) > int(bArr[0]):
			return false
		elif int(aArr[1]) < int(bArr[1]):
			return true
		elif int(aArr[1]) > int(bArr[1]):
			return false
		elif int(aArr[2]) < int(bArr[2]):
			return true
		return false
