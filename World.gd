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

func _ready():
	rng.randomize()

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
	var x = genHooks[0][0]
	var y = genHooks[0][1]
	var z = genHooks[0][2]
	match genHooks[0][3]:
		0:
			pass
		1:
			pass
		2:
			pass
		3:
			pass
		4:
			pass
		5:
			pass
		6:
			pass
		7:
			pass
		8:
			pass
		9:
			pass
		10:
			pass
		11:
			pass
		12:
			pass
		var symbol:
			printerr("found unexpected gen symbol " + symbol + " at " + str(x) + 
					"/" + str(y) + "/" + str(z) + ", removing")
			genHooks.remove(0)
