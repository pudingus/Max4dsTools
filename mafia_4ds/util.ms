fn GetModByClass obj mclass = (    --to support versions prior 2013
	local found = false	
	local foundMod
	for modd in obj.modifiers while not found do (
		if classof modd == mclass then (
			found = true
			foundMod = modd
		)
	)
	foundMod
)

fn IsGeometry obj = (
	Superclassof obj == GeometryClass and ClassOf obj != TargetObject
)

fn containsItem array value = (
	(findItem array value) > 0
)