extends Spatial

#array of all existing multimeshes' ids
var cMeshes:PoolIntArray = [0]
var cArr:Array = [
	[
		[2, 1],
		[1, 2]
	],[
		[1, 2],
		[2, 1]
	]
] setget ,getCArr
export (String) var chunkGroup:String = "tiles"

enum {AXIS_X, AXIS_Y, AXIS_Z}
enum {PLANE_YZ, PLANE_XZ, PLANE_XY}

func getCArr() -> Array:
	return cArr

func _ready():
	pass
#	updateFull()
#	yield(get_tree().create_timer(5), "timeout")
#	setPrism(5, 5, 5, 0, 0, 0, 1)
#	setLine(AXIS_Y, 5, 5, 0, 5, 2)
#	setPlane(PLANE_XZ, 6, 6, 0, 4, 0, 2)

#create a multimesh instance in pool if it does not already exist, return it
func getMultiMeshNode(id:int) -> MultiMeshInstance:
	if id in cMeshes:
		return null if id == 0 else get_node("mmn-id" + str(id)) as MultiMeshInstance
	var newmmn:MultiMeshInstance = MultiMeshInstance.new()
	var newmm:MultiMesh = MultiMesh.new()
	newmm.set_mesh(load("res://" + chunkGroup + "/mesh" + str(id) + ".tres"))
	newmm.set_transform_format(1) #set to a 3D transform
	newmmn.multimesh = newmm
	newmmn.set_name("mmn-id" + str(id))
	$".".add_child(newmmn)
	cMeshes.append(id)
	return newmmn

#get value of cArr[i][j][k], creating zeros so that it will exist if it doesn't
func getCArrVal(x:int, y:int, z:int) -> int:
	for _i in range(len(cArr) - 1, x):
		cArr.append([])
	for _j in range(len(cArr[x]) - 1, y):
		cArr[x].append([])
	for _k in range(len(cArr[x][y]) - 1, z):
		cArr[x][y].append(0)
	return cArr[x][y][z]

func tileExists(x:int, y:int, z:int) -> bool:
	return len(cArr) > x and len(cArr[x]) > y and len(cArr[x][y]) > z

#delete and rebuild the multimesh pool from newArr
func updateFull(newArr:Array = cArr):
	for child in get_children():
		if child.name.begins_with("mmn-id"):
			#because if we don't set the name to something else, the new nodes can
			#have weird messed up names (due to the queue), which breaks getMultiMeshNode
			child.set_name("FREED")
			child.queue_free()
	cMeshes = [0]
	
	for i in len(newArr):
		for j in len(newArr[i]):
			for k in len(newArr[i][j]):
				#not using setSingle because that's heavier than i need for this
				if newArr[i][j][k] <= 0:
					continue
				var newmmn:MultiMeshInstance = getMultiMeshNode(newArr[i][j][k])
				addToMmesh(newmmn.multimesh, Transform(Basis(), Vector3(i, j, k)))
	cArr = newArr

func updateTile(x:int, y:int, z:int):
	setSingle(x, y, z, cArr[x][y][z])

#set a single tile located in array at i, j, k
func setSingle(i:int, j:int, k:int, nval:int):
	var cval:int = getCArrVal(i, j, k)
	if nval == cval:
		return
	if nval != 0: #if setting to zero, don't need to make a new tile
		addToMmesh(getMultiMeshNode(nval).get_multimesh(), Transform(Basis(), Vector3(i, j, k)))
	if cval == 0: #if setting from zero, don't need to remove a tile
		cArr[i][j][k] = nval
		return
	var cmmesh:MultiMesh = getMultiMeshNode(cval).get_multimesh()
	var foundindex:int = -1
	for index in cmmesh.get_instance_count():
		if cmmesh.get_instance_transform(index) == Transform(Basis(), Vector3(i, j, k)):
			foundindex = index
			break
	removeFromMmesh(cmmesh, foundindex)
	cArr[i][j][k] = nval

#set a rect. prism of tiles
#somehow this is the basic function for the other two
func setPrism(lx:int, ly:int, lz:int, sx:int, sy:int, sz:int, nval:int):
	#cut off negative lengths so they don't go out of array bounds at 0
	lx = max(lx, -sx) as int
	ly = max(ly, -sy) as int
	lz = max(lz, -sz) as int
	#gotta make sure negative lengths work, just in case
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

#have to do this shit because updating the number of instances in a multimesh loses all the transforms
func addToMmesh(mmesh:MultiMesh, newtransform:Transform):
	var cTransformList:Array = []
	for i in mmesh.get_instance_count():
		cTransformList.append(mmesh.get_instance_transform(i))
	mmesh.instance_count += 1
	cTransformList.append(newtransform)
	for i in len(cTransformList):
		mmesh.set_instance_transform(i, cTransformList[i])

func removeFromMmesh(mmesh:MultiMesh, index:int):
	var cTransformList:Array = []
	for i in mmesh.get_instance_count():
		cTransformList.append(mmesh.get_instance_transform(i))
	mmesh.instance_count -= 1
	cTransformList.remove(index)
	for i in len(cTransformList):
		mmesh.set_instance_transform(i, cTransformList[i])
