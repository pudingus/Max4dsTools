plugin material MafMat4
name:"4DS Material v4"
classID:#(0x61cbf531, 0x2197994)
extends:Standard replaceUI:true version:2 remap:#(#(#isAnimatedM,#useMips,#useColoring,#useColorKey,#useAddBlend),#(#animatedDiffuse,#mipMapping,#colored,#colorKey,#additiveMixing))
(
	parameters main rollout:params
	(

		ambient type:#color ui:ambient
		on ambient set val do delegate.ambient = val
			
		diffuse type:#color ui:diffuse
		on diffuse set val do delegate.diffuse = val
			
		emission type:#color ui:emission animatable:true
		on emission set val do delegate.selfIllumColor = val
		
		
		opacity type:#integer ui:opacity
		on opacity set val do delegate.opacity = val
		
		diffuseMapEnable type:#boolean ui:diffuseMapEnable	
		on diffuseMapEnable set val do delegate.diffuseMapEnable = val
			
		'Diffuse Map' type:#texturemap ui:diffuseMap
		on 'Diffuse Map' set val do delegate.diffuseMap = val		
		
		envMapEnable type:#boolean ui:envMapEnable
		on envMapEnable set val do delegate.reflectionMapEnable = val

		envMapAmount type:#integer ui:envMapAmount
		on envMapAmount set val do delegate.reflectionMapAmount = val

		'Env Map' type:#texturemap ui:envMap
		on 'Env Map' set val do delegate.reflectionMap = val
			
		
		alphaMapEnable type:#boolean ui:alphaMapEnable		
		on alphaMapEnable set val do delegate.opacityMapEnable = val
		'Alpha Map' type:#texturemap ui:alphaMap
		on 'Alpha Map' set val do delegate.opacityMap = val


		twoSided type:#boolean ui:twoSided
		on twoSided set val do delegate.twoSided = val			
		


		--19 - Diffuse Map
		colored 	type:#boolean 	default:false 	ui:colored		--28
		mipMapping 		type:#boolean 	default:true 	ui:mipMapping 			--24
		animatedDiffuse  	type:#boolean 	default:false 		ui:animatedDiffuse	--27  --animovaná textura difuze
		animFrames 		type:#integer 	default:1 		ui:animFrames
		animPeriod 		type:#integer 	default:1 		ui:animPeriod

		--20 - Environment Map
		envOverlay type:#boolean default:false ui:envOverlay		--9
		envMultiply type:#boolean default:false ui:envMultiply	--10
		envAdditive type:#boolean default:false ui:envAdditive	--11
		YProj type:#boolean default:false ui:YProj				--13
		YDetail type:#boolean default:false ui:YDetail			--14
		ZDetail type:#boolean default:false ui:ZDetail			--15

		--16 - Additional Effect
		addEffect type:#boolean default:false ui:addEffect		--16
		colorKey type:#boolean default:false ui:colorKey	--30
		additiveMixing type:#boolean default:false ui:additiveMixing	--32

		animatedAlpha type:#boolean default:false ui:animatedAlpha
	)
	rollout params "4DS Params"
	(		
		colorpicker ambient "Ambient" across:2
		colorpicker emission "Emission"
		colorpicker diffuse "Diffuse" across:2	 offset:[5,0]	
		spinner opacity "Opacity  " type:#integer align:#left fieldwidth:30 type:#integer 
		
		--label ui_diffuseMap			"Diffuse Map"
		label a ""
		
		group "Diffuse Map" (
			checkbox diffuseMapEnable "Enable diffuse map " across:2
			mapbutton diffuseMap	"diff" tooltip:"kek" width:165 height:17 align:#right
			--label aa ""
			
			label bb ""
			checkbox twoSided 			"2-Sided" 		align:#left across:2
			checkbox animatedDiffuse 	"Animated" 		align:#left 	
			
			checkbox colored 			"Colored" 		across:2
			spinner animFrames 			"Frames" 		range:[0,1000,1] align:#left fieldwidth:40 type:#integer	offset:[3,2]

			
			checkbox mipMapping 		"Mip mapping" 	align:#left across:2	
			spinner animPeriod 			"Period " 		range:[0,3600000,1] align:#left fieldwidth:40 type:#integer offset:[5,0]
			label afasfa ""
		)
		
		label b ""
		group "Environment Map" (
			checkbox envMapEnable "Enable env. map" across:3
			spinner envMapAmount "" fieldwidth:30 type:#integer align:#left
			mapbutton envMap 	"Environment map" width:165 height:17 align:#right 
			
			label bbc ""			

			checkbox envOverlay		"Overlay" 		across:2
			checkbox YProj 			"Y proj" 
			
			checkbox envMultiply 	"Multiply" 		across:2
			checkbox YDetail		"Y detail" 	
			
			checkbox envAdditive  	"Additive" 		across:2
			checkbox ZDetail		"Z detail" 				
		)
		
		label c ""
		group "Add Effect" (
			checkbox addEffect		"Add effect" 		align:#left fieldwidth:48
			checkbox alphaMapEnable "Enable alpha map" 	across:2
			mapbutton alphaMap 		"Alpha map"    		width:165 height:17 align:#right
			checkbox animatedAlpha	"Animated alpha map" aligh:#left
			checkbox colorKey		"Color key" 		align:#left fieldwidth:48
			checkbox additiveMixing	"Additive mixing"	align:#left fieldwidth:48
		)
		label d ""
		groupBox group1 "" pos:[160,124] width:120 height:75 
	)
	
	on create do (
		delegate.adLock = false
	)

	on update do (
		--format "update lol version: % \n" version

		if version == 1 then (
			delegate.adLock = false

			ambient = delegate.ambient
			diffuse = delegate.diffuse
			emission = delegate.selfIllumColor
			
			opacity = delegate.opacity

			diffuseMapEnable = delegate.diffuseMapEnable
			'Diffuse Map' = delegate.diffuseMap

			envMapEnable = delegate.reflectionMapEnable
			envMapAmount = delegate.reflectionMapAmount
			'Env Map' = delegate.reflectionMap

			alphaMapEnable = delegate.opacityMapEnable
			'Alpha Map' = delegate.opacityMap

			twoSided = delegate.twoSided

		)
	)
)