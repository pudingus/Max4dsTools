MafParams_def = attributes "MafParams"
attribID:#(0x4c8354c9, 0x47113d19)
version:2 
remap:#(#(#userParams), #(#strParams))
(
	parameters main
	(
		objectType type:#string default:""


		 --only visual types
		renderFlags type:#integer default:0    
		renderFlags2 type:#integer default:42
		
		--all objects
		cullFlags type:#integer default:9
		strParams type:#string  default:""

		--LOD
		lodDist type:#float default:0.0
		dontOptimize type:#boolean default:false


		--Portal
		nearRange type:#float default:0.0
		farRange type:#float default:10.0


		--Billboard
		rotAxis type:#integer default:1
		rotMode type:#integer default:1
		
		
		--bone
		boneId type:#integer
		linkedBoneId type:#integer
		--boneMatrix type:#floatTab tabsize:16
	)	
)