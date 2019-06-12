plugin material MafMat
name:"4DS Material"
classID:#(0x61cbf531, 0x2197994)
extends:Standard
(
	parameters main rollout:params
	(
		useMips type:#boolean default:true ui:ui_useMips --24
		useAddBlend type:#boolean default:false ui:ui_useAddBlend --32
		useAddRefl type:#boolean default:false ui:ui_useAddRefl --11
		diffReflAxis type:#boolean default:false ui:ui_diffReflAxis --13
		useColorKey type:#boolean default:false ui:ui_useColorKey --30
		useAnim type:#boolean default:false ui:ui_useAnim --27
		useAnimAlpha type:#boolean default:false ui:ui_useAnimAlpha --26
		animFrames type:#integer default:1 ui:ui_animFrames
		animDelay type:#integer default:1 ui:ui_animDelay
		--	on useMips changed val do delegate.cellColor = val
	)
	rollout params "4DS Params"
	(
		checkbox ui_useMips "Mipmapping" align:#left fieldwidth:48
		checkbox ui_useAddBlend "Additive blending" align:#left fieldwidth:48
		checkbox ui_useAddRefl "Additive reflection" align:#left fieldwidth:48
		checkbox ui_diffReflAxis "Different reflection axis" align:#left fieldwidth:48
		checkbox ui_useColorKey "Color key" align:#left fieldwidth:48
		checkbox ui_useAnim "Animated" align:#left fieldwidth:48
		checkbox ui_useAnimAlpha "Animate opacity" align:#left fieldwidth:48
		spinner ui_animFrames "Frames" range:[0,1000,1] align:#left fieldwidth:40
		spinner ui_animDelay "Delay" range:[0,3600000,1] align:#left fieldwidth:40
	)
)