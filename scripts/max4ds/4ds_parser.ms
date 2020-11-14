rollout MafiaTools_4dsParser "" ( --module
    
    local ReadMatrix
    local ReadHeader
    local ReadMaterial
    local ReadObject
    local ReadMesh
    local ReadSkin
    local ReadMorph
    local ReadBillboard
    local ReadGlow
    local ReadMirror
    local ReadDummy
    local ReadSector
    local ReadTarget
    local ReadBone
    local ReadOccluder
    local ReadProjector
    local ReadLight
    local ReadEmitor
    
    local Write4ds
    local WriteHeader
    local WriteMaterial
    local WriteObject
    local WriteMesh
    local WriteSkin
    local WriteBillboard
    local WriteSector
    local WriteDummy
    local WriteTarget
    local WriteBone
    local WriteGlow
    local WriteMirror
    local WriteMorph
    local WriteOccluder
    
    -------------------------------------------------
    
    
    fn ReadU8 f = (
        local result = ReadByte f #unsigned
        if result == undefined then throw "Unexpected end of file. Read 'undefined'"
        else result
    )
    
    fn ReadU16 f = (
        local result = ReadShort f #unsigned
        if result == undefined then throw "Unexpected end of file. Read 'undefined'"
        else result
    )
    
    fn ReadU32 f = (
        local result = ReadLong f #unsigned
        if result == undefined then throw "Unexpected end of file. Read 'undefined'"
        else result
    )
    
    fn ReadU64 f = (
        local result = ReadLongLong f #unsigned
        if result == undefined then throw "Unexpected end of file. Read 'undefined'"
        else result
    )
    
    fn ReadFloatSafe f = (
        local result = ReadFloat f
        if result == undefined then throw "Unexpected end of file. Read 'undefined'"
        else result
    )
    
    
    fn WriteU8 f val = (
        if not isKindOf val Number then throw "Write error. Value is not a number, got: " val
        if val > 255 or val < 0 then throw "Write error. Value out of U8 range! Value: " val
        local result = WriteByte f val
        if result != true then throw "Unknown write error"
        else result
    )
    
    fn WriteU16 f val = (
        if not isKindOf val Number then throw "Write error. Value is not a number, got: " val
        if val > 65535 or val < 0 then throw "Write error. Value out of U16 range! Value: " val
        local result = WriteShort f val
        if result != true then throw "Unknown write error"
        else result
    )
    
    fn WriteU32 f val = (
        if not isKindOf val Number then throw "Write error. Value is not a number, got: " val
        local result = WriteLong f val
        if result != true then throw "Unknown write error"
        else result
    )
    
    fn WriteU64 f val = (
        if not isKindOf val Number then throw "Write error. Value is not a number, got: " val
        local result = WriteLongLong f val
        if result != true then throw "Unknown write error"
        else result
    )
    
    -------------------------------------------------
    
    fn ReadText f = (
        local len = ReadU8 f

        local result
        if len > 0 then (
            local fmt = "%"
            local ss = StringStream ""
            for i = 1 to len do (
                format fmt (bit.intAsChar(ReadU8 f)) to:ss
            )
            result = ss as string
        )
        result
    )
    
    fn WriteText f txt = (
        local count = 0
        if txt != undefined then count = txt.count

        if count > 255 then (
            count = 255
            throw "String is over the maximum of 255 characters: " txt
        )
        WriteU8 f count
        for i = 1 to count do (
            WriteU8 f (bit.charasint txt[i])
        )

        count
    )
    
    -------------------------------------------------

    fn ReadPoint3 f = (
        local x = ReadFloatSafe f
        local y = ReadFloatSafe f
        local z = ReadFloatSafe f
        [x, z, y]
    )    
    
    fn WritePoint3 f p3 = (
        WriteFloat f p3.x
        WriteFloat f p3.z
        WriteFloat f p3.y
    )
    
    fn WritePoint4 f p3 = (
        WriteFloat f p3.x
        WriteFloat f p3.z
        WriteFloat f p3.y
        WriteFloat f 0.0
    )
    
    fn ReadPoint4 f = (
        local x = ReadFloatSafe f
        local y = ReadFloatSafe f
        local z = ReadFloatSafe f
        local w = ReadFloatSafe f
        [x, z, y]
    )
    
    -------------------------------------------------

    fn ReadColor3 f = (
        local r = (ReadFloatSafe f) * 255
        local g = (ReadFloatSafe f) * 255
        local b = (ReadFloatSafe f) * 255
        color r g b
    )
    
    fn ReadColor4 f = (
        local r = (ReadFloatSafe f) * 255
        local g = (ReadFloatSafe f) * 255
        local b = (ReadFloatSafe f) * 255
        local a = (ReadFloatSafe f) * 255
        color r g b
    )
    
    fn WriteColor3 f clr = (
        WriteFloat f (clr.r / 255.0)
        WriteFloat f (clr.g / 255.0)
        WriteFloat f (clr.b / 255.0)
    )
    
    fn WriteColor4 f clr = (
        WriteFloat f (clr.r / 255.0)
        WriteFloat f (clr.g / 255.0)
        WriteFloat f (clr.b / 255.0)
        WriteFloat f 0.0
    )
    
    -------------------------------------------------
    
    fn ReadQuatWXYZ f = (
        local rw = ReadFloatSafe f
        local rx = ReadFloatSafe f
        local ry = ReadFloatSafe f
        local rz = ReadFloatSafe f
        local qt = quat rx rz ry rw
        inverse qt
    )
    
    fn ReadQuatXYZW f = (
        local rx = ReadFloatSafe f
        local ry = ReadFloatSafe f
        local rz = ReadFloatSafe f
        local rw = ReadFloatSafe f
        local qt = quat rx rz ry rw
        inverse qt
    )
    
    fn WriteQuatWXYZ f q = (
        WriteFloat f q.w
        WriteFloat f q.x
        WriteFloat f q.z
        WriteFloat f q.y
    )
    
    fn WriteQuatXYZW f q = (
        WriteFloat f q.x
        WriteFloat f q.z
        WriteFloat f q.y
        WriteFloat f q.w
    )
    
    -------------------------------------------------
    
    fn ReadFace f = (
        local a = ReadU16 f
        local b = ReadU16 f
        local c = ReadU16 f
        [a+1, c+1, b+1]       --face vertex indexes are 1-based in 3ds Max
    )
    
    fn WriteFace f face = (
        local a = (face[1] - 1) as integer  --vertices are indexed from 0 in 4ds, from 1 in max
        local b = (face[3] - 1) as integer
        local c = (face[2] - 1) as integer
        WriteU16 f a
        WriteU16 f b
        WriteU16 f c
    )

    -------------------------------------------------
    
    fn ReadUV f = (
        local x = ReadFloatSafe f
        local y = ReadFloatSafe f
        [x, 1-y, 0]
    )
    
    fn WriteUV f uv = (
        WriteFloat f uv.x
        WriteFloat f (1 - uv.y)
    )

    -------------------------------------------------
    
    fn ReadMatrix f = (
        local mtr = #()
        for m = 1 to 4 do (
            mtr[m] = #()
            for n = 1 to 4 do mtr[m][n] = ReadFloatSafe f
        )

        local row1 = [mtr[1][1], mtr[1][3], mtr[1][2]]
        local row2 = [mtr[3][1], mtr[3][3], mtr[3][2]]
        local row3 = [mtr[2][1], mtr[2][3], mtr[2][2]]
        local row4 = [mtr[4][1], mtr[4][3], mtr[4][2]]

        matrix3 row1 row2 row3 row4
    )
    
    fn WriteMatrix f mat3 = (
        local rows = #()
        append rows #(mat3.row1.x, mat3.row1.z, mat3.row1.y, 0)
        append rows #(mat3.row3.x, mat3.row3.z, mat3.row3.y, 0) -- thanks Duelist
        append rows #(mat3.row2.x, mat3.row2.z, mat3.row2.y, 0)
        append rows #(mat3.row4.x, mat3.row4.z, mat3.row4.y, 1)

        for row in rows do (
            for n = 1 to 4 do WriteFloat f row[n]
        )
    )

    -------------------------------------------------
    
    struct T4ds (
        materials = #(),  --array of TMaterial
        objects = #(),   --array of TObject
        allow5ds   --bool
    )   
    
    fn Read4ds f = (
        local m4ds
        
        local fourcc = ReadU32 f
        if fourcc != 5456948 then return undefined
        
        local version = ReadU16 f
        local filetime = ReadU64 f
        version = 
            if version == 29 or version == 27 then #mafia
            else if version == 41 then #hd2
            else if version == 42 then #chameleon
        
        if version == #mafia or version == #chameleon or version == #hd2 then (
            m4ds = T4ds()
            local numMats = ReadU16 f
            for i = 1 to numMats do (
                --format "%: " i
                append m4ds.materials (ReadMaterial f version)
            )

            local numObjects = ReadU16 f
            for i = 1 to numObjects do (
                --format "%: " i
                append m4ds.objects (ReadObject f version)
            )
            
            m4ds.allow5ds = (ReadU8 f) > 0
        )
        m4ds
    )
    
    fn Write4ds f m4ds version = (
        WriteU32 f 5456948     -- 4DS
        
        local versionInt = case version of (
            #mafia: 29
            #hd2: 41
            #chameleon: 42
            default: throw "invalid version, got: " version
        )
        
        WriteU16 f versionInt
        
        local DateTime = dotNetClass "DateTime"
        local filetime = DateTime.UtcNow.ToFiletime()        
        WriteU64 f filetime        

        WriteU16 f m4ds.materials.count
        for mmat in m4ds.materials do (
            WriteMaterial f mmat version
        )

        WriteU16 f m4ds.objects.count
        for mobj in m4ds.objects do (
            WriteObject f mobj version
        )        

        WriteU8 f (if m4ds.allow5ds then 1 else 0)
    )

    -------------------------------------------------    
    
    struct TMaterial (
        flags,   --u32
        ambient,  --color (float[3])
        diffuse,  --color (=||=)
        specular = white, --color (HD2, Chameleon only)
        emission,  --color
        opacity,  --float
        specularity = 0.0,  --float (HD2, Chameleon only)
        envMapAmount,  --float
        envMapName, --pstring
        diffMapName,    --pstring
        alphaMapName,   --pstring
        animFrames, --u32
        animPeriod  --u32
    )
    
    fn ReadMaterial f version = (
        local mmat = TMaterial()
        mmat.flags = ReadU32 f
        
        local ReadColor = if version == #mafia then ReadColor3 else ReadColor4
        
        mmat.ambient = ReadColor f
        mmat.diffuse = ReadColor f
        
        if version == #mafia then (
            mmat.emission = ReadColor f
        )
        else (
            mmat.specular = ReadColor f
            mmat.emission = ReadColor f
            mmat.specularity = ReadFloatSafe f
        )

        mmat.opacity = ReadFloatSafe f
        if bit.get mmat.flags 20 then (  --env map enabled
            mmat.envMapAmount = ReadFloatSafe f
            mmat.envMapName = ReadText f
        )
        mmat.diffMapName = ReadText f
        if (mmat.diffMapName != undefined) and (bit.get mmat.flags 31) and not (bit.get mmat.flags 25) then (
            mmat.alphaMapName = ReadText f
        )

        if bit.get mmat.flags 27 then (
            mmat.animFrames = ReadU32 f
            ReadU16 f
            mmat.animPeriod = ReadU32 f
            ReadU32 f
            ReadU32 f
        )
        
        --format "mat diff: %, env: %, alpha: % \n" mmat.diffMapName mmat.envMapName mmat.alphaMapName 
        
        mmat
    )
    
    fn WriteMaterial f mmat version = (
        WriteU32 f mmat.flags
        
        local WriteColor = if version == #mafia then WriteColor3 else WriteColor4       
        
        WriteColor f mmat.ambient
        WriteColor f mmat.diffuse
        
        if version == #mafia then (
            WriteColor f mmat.emission
        )
        else (
            WriteColor f mmat.specular
            WriteColor f mmat.emission
            WriteFloat f mmat.specularity            
        )        
        
        WriteFloat f mmat.opacity

        if bit.get mmat.flags 20 then (     -- env map
            WriteFloat f mmat.envMapAmount
            WriteText f mmat.envMapName
        )
        local count = WriteText f mmat.diffMapName

        if count > 0 and bit.get mmat.flags 31 then (   -- alpha map
            WriteText f mmat.alphaMapName
        )

        if bit.get mmat.flags 27 then (     -- animated
            WriteU32 f mmat.animFrames
            WriteU16 f 0
            WriteU32 f mmat.animPeriod
            WriteU32 f 0
            WriteU32 f 0
        )

    )
    
    -------------------------------------------------    
    
    struct TObject (
        objectType,
        visualType,
        renderFlags = 0,
        renderFlags2 = 0,
        parentId,    -- 0 == no parent, 1..N == parent obj id
        offset,
        scl,
        rot,
        cullFlags,
        name,
        strParams,
        
        --definitions----
        mesh,
        skin,
        morph,
        billboard,
        glow,
        mirror,
        sector,
        dummy,
        target,
        bone,
        occluder,

        fn GetMatrix = (
            local s = scaleMatrix scl
            local r = rot as matrix3
            local t = transMatrix offset
            (s * r * t)
        ),
        
        fn getType = (
            case objectType of (
                1: case visualType of (
                    0: #mesh
                    1: #litmesh
                    2: #singlemesh
                    3: #singlemorph
                    4: #billboard
                    5: #morph
                    6: #glow
                    7: #projector
                    8: #mirror
                    9: #emitor
                )
                2: #light
                5: #sector
                6: #dummy
                7: #target
                10: #bone
                12: #occluder
            )
        )
    )    
    
    fn ReadObject f version = (
        local mobj = TObject()

        mobj.objectType = ReadU8 f

        if mobj.objectType == 1 then (  --visual object
            mobj.visualType = ReadU8 f
            mobj.renderFlags = ReadU8 f
            mobj.renderFlags2 = ReadU8 f
        )
        mobj.parentId = ReadU16 f
        
        mobj.offset = ReadPoint3 f
        
        if version == #mafia then (
            mobj.scl = ReadPoint3 f
            mobj.rot = ReadQuatWXYZ f
        )
        else (
            mobj.rot = ReadQuatXYZW f
            mobj.scl = ReadPoint3 f
        )
        
        if version == #hd2 then ReadFloatSafe f

        mobj.cullFlags = ReadU8 f
        mobj.name = ReadText f
        mobj.strParams = ReadText f
        
        --format "%, type: %\n" mobj.name (mobj.getType())

        case mobj.objectType of (
            1: case mobj.visualType of (
                0: mobj.mesh = ReadMesh f version  --standardmesh
                1: mobj.mesh = ReadMesh f version  --litmesh
                2: (  --singlemesh
                    mobj.mesh = ReadMesh f version
                    mobj.skin = ReadSkin f mobj.mesh.lods.count version
                )
                3: (  --singlemorph
                    mobj.mesh = ReadMesh f version
                    mobj.skin = ReadSkin f mobj.mesh.lods.count version
                    mobj.morph = ReadMorph f version
                )
                4: (
                    mobj.mesh = ReadMesh f version
                    mobj.billboard = ReadBillboard f
                )
                5: ( --morph
                    mobj.mesh = ReadMesh f version
                    mobj.morph = ReadMorph f version
                )
                6: mobj.glow = ReadGlow f version
                7: ReadProjector f
                8: mobj.mirror = ReadMirror f version
                9: ReadEmitor f
                default: throw "unknown visual type! value: " mobj.visualType
            )
            2: ReadLight f
            5: mobj.sector = ReadSector f version
            6: mobj.dummy = ReadDummy f version
            7: mobj.target = ReadTarget f
            10: mobj.bone = ReadBone f version
            12: mobj.occluder = ReadOccluder f version
            default: throw "unknown object type! value: " mobj.objectType
        )

        mobj
    )
    
    fn WriteObject f mobj version = (
        WriteU8 f mobj.objectType

        if mobj.objectType == 1 then (
            WriteU8 f mobj.visualType
            WriteU8 f mobj.renderFlags
            WriteU8 f mobj.renderFlags2
        )

        WriteU16 f mobj.parentId
        
        WritePoint3 f mobj.offset
        
        if version == #mafia then (            
            WritePoint3 f mobj.scl
            WriteQuatWXYZ f mobj.rot
        )
        else (
            WriteQuatXYZW f mobj.rot
            WritePoint3 f mobj.scl
        )
        
        if version == #hd2 then WriteFloat f 0.0
        
        WriteU8 f mobj.cullFlags
        WriteText f mobj.name
        WriteText f mobj.strParams

        case mobj.objectType of (
            1: case mobj.visualType of (
                0: WriteMesh f mobj.mesh version
                2: (
                    WriteMesh f mobj.mesh version
                    WriteSkin f mobj.skin version
                )
                3: (
                    WriteMesh f mobj.mesh version
                    WriteSkin f mobj.skin version
                    WriteMorph f mobj.morph version
                )
                4: (
                    WriteMesh f mobj.mesh version
                    WriteBillboard f mobj.billboard
                )
                5: (
                    WriteMesh f mobj.mesh version
                    WriteMorph f mobj.morph version
                )
                6: WriteGlow f mobj.glow version
                8: WriteMirror f mobj.mirror version
                default: throw "invalid visual type"
            )
            5: WriteSector f mobj.sector version
            6: WriteDummy f mobj.dummy version
            7: WriteTarget f mobj.target
            10: WriteBone f mobj.bone version
            12: WriteOccluder f mobj.occluder version
            default: throw "invalid object type"
        )
    )
    
    -------------------------------------------------

    struct TMesh (
        instanceId,    -- 0 == this mesh is unique, 1..N == id of obj to instance
        lods = #()
    )
    
    struct TFacegroup (
        faceIds = #(),   -- array of 1-based ids
        matId   -- 0 == no material, 1..N == material
    )
    
    struct TLod (
        distance,
        mesh,
        facegroups = #()
    )    
    
    fn ReadMesh f version = (
        local mmesh = TMesh()
        mmesh.instanceId = ReadU16 f

        if mmesh.instanceId == 0 then (
            local numlods = ReadU8 f
            struct TVert (pos, normal, uv)
            
            for lodId = 1 to numlods do (
                local mlod = TLod()
                mlod.distance = ReadFloatSafe f
                
                if version == #hd2 or version == #chameleon then (
                    local numExtraData = ReadU32 f
                )
                
                local numVerts = ReadU16 f                
                
                local verts = for i = 1 to numVerts collect (
                    local vert = ReadPoint3 f
                    local normal = ReadPoint3 f
                    local uv = ReadUV f
                    
                    TVert pos:vert normal:normal uv:uv
                )
                
                if version == #hd2 or version == #chameleon then ( 
                    for i = 1 to numExtraData * numVerts do ReadFloatSafe f
                )
                
                local faces = #()
                local prevTotal = 0
                local numFacegroups = ReadU8 f
                for i = 1 to numFacegroups do (
                    local fcgrp = TFacegroup()
                    local grpNumFaces = ReadU16 f   --number of faces in this facegroup                                         
                    
                    for j = 1 to grpNumFaces do (                                                        
                        append faces (ReadFace f)     
                        local faceId = prevTotal + j                       
                        append fcgrp.faceIds faceId
                    )
                    fcgrp.matId = ReadU16 f

                    append mlod.facegroups fcgrp    
                    prevTotal = prevTotal + grpNumFaces
                )                  
                
                
                local tr = TriMesh()
                setNumVerts tr numverts
                setNumTVerts tr numverts  
                setNumFaces tr faces.count
                for i = 1 to numverts do (
                    setVert tr i verts[i].pos
                    setTVert tr i verts[i].uv
                    setNormal tr i verts[i].normal
                )
                
                if numverts != 0 then buildTVFaces tr
                for i = 1 to faces.count do (
                    setFace tr i faces[i]                        
                    setTVFace tr i faces[i]
                    for v = 1 to 3 do setEdgeVis tr i v true
                )

                mlod.mesh = tr
                append mmesh.lods mlod
            )            
        )

        mmesh
    )

    fn WriteMesh f mmesh version = (
        WriteU16 f mmesh.instanceId

        if mmesh.instanceId == 0 then (
            WriteU8 f mmesh.lods.count
            for lod in mmesh.lods do (
                WriteFloat f lod.distance
                
                if version == #hd2 or version == #chameleon then (
                    WriteU32 f 0   --num extra data
                )
                
                WriteU16 f lod.mesh.numverts

                for i = 1 to lod.mesh.numverts do (
                    WritePoint3 f (getVert lod.mesh i)
                    WritePoint3 f (getNormal lod.mesh i)
                    WriteUV f (getTVert lod.mesh i)
                )

                WriteU8 f lod.facegroups.count
                for facegroup in lod.facegroups do (
                    WriteU16 f facegroup.faceIds.count
                    for faceId in facegroup.faceIds do (
                        WriteFace f (getFace lod.mesh faceId)
                    )
                    WriteU16 f (facegroup.matId - 1)
                )
            )
        )
    )
    
    -------------------------------------------------
    
    struct TWeight (
        boneId,
        weight
    )

    struct TSkinCommon (
        parentIds = #(),
        jointInfo = #(),   --todo: use this when reading, must have atleast 1 item, root bone must be first
        weights = #()    --array of #(boneId, weight)
    )
    
    struct TJointInfo (
        matrix,
        dmin,
        dmax
    )
    
    fn ReadSkinCommonMafia f numlods = (
        for l = 1 to numLods collect (
            local numGroups = ReadU8 f
            local numW1Verts = ReadU32 f

            local dmin = ReadPoint3 f
            local dmax = ReadPoint3 f
            
            local weights = #()
            
            local parentIds = #()

            for i = 1 to numGroups do (
                local matrix = ReadMatrix f

                local numW1Verts = ReadU32 f
                local numWeights = ReadU32 f
                local parentId = (ReadU32 f) + 1

                local dmin = ReadPoint3 f
                local dmax = ReadPoint3 f
                
                local boneId = i + 1
                
                for w = 1 to numW1Verts do (
                    append weights #(boneId, 1.0)
                )

                for w = 1 to numWeights do (
                    local weight = ReadFloatSafe f
                    
                    append weights #(boneId, weight)
                )
                
                parentIds[boneId] = parentId
            )
            
            for w = 1 to numW1Verts do (
                append weights #(1, 1.0)
            )
            
            TSkinCommon parentIds:parentIds weights:weights
        )
    )
    
    fn WriteSkinCommonMafia f mskins = (
        for mskin in mskins do (
            struct VGroupMafia (
                numW1Verts = 0,
                weights = #()
            )
            
            local groups = #()
            for i = 2 to mskin.jointInfo.count do (
                groups[i] = VGroupMafia()
            )
            
            local numW1Verts = 0
            
            for weight in mskin.weights do (
                if weight.boneId == 1 then (
                    numW1Verts += 1
                )
                else (
                    local grp = groups[weight.boneid]
                               
                    if weight.weight == 1.0 then (
                        grp.numW1verts += 1
                    )
                    else (
                        append grp.weights weight.weight
                    )
                )
            )
            
            WriteU8 f (mskin.jointInfo.count - 1)
            WriteU32 f numW1Verts
            WritePoint3 f mskin.jointInfo[1].dmin
            WritePoint3 f mskin.jointInfo[1].dmax
            
            for i = 2 to groups.count do (
                local grp = groups[i]
                WriteMatrix f mskin.jointInfo[i].matrix
                WriteU32 f grp.numW1Verts
                WriteU32 f grp.weights.count
                WriteU32 f (mskin.parentIds[i] - 1)
                WritePoint3 f mskin.jointInfo[i].dmin
                WritePoint3 f mskin.jointInfo[i].dmax
                for weight in grp.weights do (
                    WriteFloat f weight
                )
            )
        )
    )
    
    fn ReadSkinCommonChameleon f numlods version = (
        local numGroups = ReadU8 f
        local ReadPoint = if version == #hd2 then ReadPoint4 else ReadPoint3
        local dmin = ReadPoint f
        local dmax = ReadPoint f
        local parentIds = for i = 1 to numGroups collect (
            (ReadU8 f) + 1
        )        
        
        local parentIds2 = #()
                
        for i = 1 to numGroups do (
            local matrix = ReadMatrix f
            local dmin = ReadPoint f
            local dmax = ReadPoint f
            
            parentIds2[i + 1] = parentIds[i]
        )
        
        for i = 1 to numlods collect (
            local numWeights = ReadU32 f
            local joints = #()
            local weights = #()
            for j = 1 to numWeights do (
                local boneId = (ReadU8 f) + 1
                local weight = 1.0 / 255.0 * (ReadU8 f)
                
                append weights #(boneid, 1.0 - weight)
            )      
            TSkinCommon parentIds:parentIds2 weights:weights
        )
    )
    
    fn WriteSkinCommonChameleon f mskins version = (
        local WritePoint = if version == #hd2 then WritePoint4 else WritePoint3
        
        WriteU8 f (mskins[1].jointInfo.count - 1)   --numGroups
        WritePoint f mskins[1].jointInfo[1].dmin  --min
        WritePoint f mskins[1].jointInfo[1].dmax   --max
        local parentIds = for i = 2 to mskins[1].parentIds.count do (
           WriteU8 f (mskins[1].parentIds[i] - 1)
        )
        
        for i = 2 to mskins[1].jointInfo.count do (
            WriteMatrix f mskins[1].jointInfo[i].matrix
            WritePoint f mskins[1].jointInfo[i].dmin
            WritePoint f mskins[1].jointInfo[i].dmax
        )
        
        for mskin in mskins do (
            WriteU32 f mskin.weights.count
            for weight in mskin.weights do (
                WriteU8 f (weight.boneid - 1)
                WriteU8 f ((1.0 - weight.weight) * 255)
            )
        )
    )
    
    -------------------------------------------------    
   
    --------------    
    
    fn ReadSkin f numlods version = (
        if version == #mafia then (
            ReadSkinCommonMafia f numlods
        )
        else (
            ReadSkinCommonChameleon f numlods version
        )
    )

    fn WriteSkin f mskins version = (
        if version == #mafia then (
            WriteSkinCommonMafia f mskins
        )
        else (
            WriteSkinCommonChameleon f mskins version
        )
    )

    -------------------------------------------------
    
    struct TMorph (
        numTargets,    --num targets per region
        numRegions,
        lods = #(),
        dmin,
        dmax,
        center,
        dist 
    )
    
    struct TMorphLod (
        regions = #()     --array of TMorphRegion
    )
    
    struct TMorphRegion (
        vertices = #()      --array of TMorphVertex
    )
    
    struct TMorphVertex (
        points = #(),   --array of TMorphedPoint, count=TMorph.numTargets
        index   --vertex index, 1-based, u16
    )
    
    struct TMorphedPoint (
        pos,    --point3
        normal  --point3
    )
    
    fn ReadMorph f version = (
        local morph = TMorph()
        morph.numTargets = ReadU8 f

        if morph.numTargets > 0 then (
            morph.numRegions = ReadU8 f
            local numLods = ReadU8 f
            
            for lodId = 1 to numLods do (
                local lod = TMorphLod()
                for i = 1 to morph.numRegions do   (
                    local region = TMorphRegion()
                    local numVerts = ReadU16 f
    
                    for v = 1 to numVerts do (
                        local vert = TMorphVertex()
    
                        for t = 1 to morph.numTargets do (
                            local point = TMorphedPoint()
                            point.pos = ReadPoint3 f
                            point.normal = ReadPoint3 f
                            append vert.points point
                        )
                        append region.vertices vert
                    )
    
                    if (morph.numTargets * numVerts) > 0 then ReadU8 f  --unknown
    
                    for v = 1 to numVerts do (
                        region.vertices[v].index = (ReadU16 f) + 1
                    )
    
                    append lod.regions region
                )
                append morph.lods lod
            )

            if version == #hd2 then (
                morph.dmin = ReadPoint4 f
                morph.dmax = ReadPoint4 f
                morph.center = ReadPoint3 f
                morph.dist = ReadFloatSafe f
            )
            else (            
                morph.dmin = ReadPoint3 f
                morph.dmax = ReadPoint3 f
                morph.center = ReadPoint3 f
                morph.dist = ReadFloatSafe f
            )            
        )
        morph
    )
    
    fn WriteMorph f morph version = (
        WriteU8 f morph.numTargets
        
        if morph.numTargets > 0 then (
            WriteU8 f morph.numRegions
            WriteU8 f morph.lods.count
            
            for lod in morph.lods do (
                if lod.regions.count != morph.numRegions then throw "morph.numRegions and lod.regions.count mismatch"
                
                for region in lod.regions do (
                    WriteU16 f region.vertices.count
                    for vert in region.vertices do (
                        if vert.points.count != morph.numTargets then throw "numTargets and points.count mismatch"
                        for point in vert.points do (
                            WritePoint3 f point.pos
                            WritePoint3 f point.normal
                        )
                    )
                    if region.vertices.count * morph.numTargets > 0 do WriteU8 f 1 --unknown
                    
                    for vert in region.vertices do (
                        WriteU16 f (vert.index - 1)
                    )
                )
            )
            
            if version == #hd2 then (
                WritePoint4 f morph.dmin
                WritePoint4 f morph.dmax
                WritePoint3 f morph.center
                WriteFloat f morph.dist
            )
            else (
                WritePoint3 f morph.dmin
                WritePoint3 f morph.dmax
                WritePoint3 f morph.center
                WriteFloat f morph.dist
            )            
        )
    )
    
    -------------------------------------------------
    
    struct TBillboard (
        rotAxis,   -- u8, 1-based
        rotMode   -- u32, 1-based
    )
    
    fn ReadBillboard f = (
        local mbillboard = TBillboard()
        mbillboard.rotAxis = (ReadU32 f) + 1
        mbillboard.rotMode = (ReadU8 f) + 1

        mbillboard
    )
    
    fn WriteBillboard f mbillboard = (
        WriteU8 f (mbillboard.rotAxis - 1)
        WriteU32 f (mbillboard.rotMode - 1)
    )
    
    -------------------------------------------------    

    struct TGlow (
        position,  --float, screen offset
        
        -- u16, 0 == no_texture, 1..N == materials
        -- zero is invalid here, crashes the game
        matId  
    )
    
    fn ReadGlow f version = (
        local glows = #()
        local numGlows = ReadU8 f

        for i = 1 to numGlows do (
            local glow = TGlow()
            glow.position = ReadFloatSafe f
            if version != #mafia do ReadFloatSafe f
            glow.matId = ReadU16 f

            append glows glow
        )

        glows
    )

    fn WriteGlow f mglows version = (
        WriteU8 f mglows.count
        for mglow in mglows do (
            WriteFloat f mglow.position
            if version != #mafia do WriteFloat f 0.0
            WriteU16 f mglow.matId
            if mglow.matId == 0 do throw "TGlow.matId cannot be zero"
        )
    )
    
    -------------------------------------------------
    
    struct TMirror (
        dmin,  --p3
        dmax,  --p3
        unknown = #(), --float[4]
        matrix,   --matrix3
        backColor,  --float[3]
        drawDistance,  --float
        mesh
    )
    
    fn ReadMirror f version = (
        local mirr = TMirror()
        
        local ReadPoint = if version == #hd2 then ReadPoint4 else ReadPoint3  
        local ReadColor = if version == #hd2 then ReadColor4 else ReadColor3 

        mirr.dmin = ReadPoint f
        mirr.dmax = ReadPoint f
        for i = 1 to 4 do mirr.unknown[i] = ReadFloatSafe f        
        mirr.matrix = ReadMatrix f
        mirr.backColor = ReadColor f
        
        mirr.drawDistance = ReadFloatSafe f

        local tr = TriMesh()        
        tr.numVerts = ReadU32 f
        tr.numFaces = ReadU32 f
                
        for vertId = 1 to tr.numVerts do (
            setVert tr vertId (ReadPoint f)
        )        
        
        for faceId = 1 to tr.numFaces do (
            setFace tr faceId (ReadFace f)
            for c = 1 to 3 do setEdgeVis tr faceId c true
        )

        mirr.mesh = tr

        mirr
    )
    
    fn WriteMirror f mirr version = (
        local WritePoint = if version == #hd2 then WritePoint4 else WritePoint3
        local WriteColor = if version == #hd2 then WriteColor4 else WriteColor3
        
        
        WritePoint f mirr.dmin
        WritePoint f mirr.dmax
        
        for i = 1 to 4 do WriteFloat f mirr.unknown[i]
        
        WriteMatrix f mirr.matrix
        WriteColor f mirr.backColor
        WriteFloat f mirr.drawDistance
        
        local tr = mirr.mesh
        WriteU32 f tr.numverts
        WriteU32 f tr.numfaces
        
        for i = 1 to tr.numverts do (
            local vert = getVert tr i
            WritePoint f vert
        )
        
        for i = 1 to tr.numfaces do (
            local face = getFace tr i
            WriteFace f face
        )
    )
    
    
    -------------------------------------------------
    
    struct TDummy (
        dmin,
        dmax
    )
    
    fn ReadDummy f version = (
        local mDummy = TDummy()
        
        local ReadPoint = if version == #hd2 then ReadPoint4 else ReadPoint3        
        
        mDummy.dmin = ReadPoint f
        mDummy.dmax = ReadPoint f
        mDummy
    )
    
    fn WriteDummy f mdummy version = (
        local WritePoint = if version == #hd2 then WritePoint4 else WritePoint3
        
        WritePoint f mdummy.dmin
        WritePoint f mdummy.dmax
    )
    
    -------------------------------------------------
    
    struct TSector (
        mesh,
        dmin,
        dmax,
        portals = #() --array of TPortal
    )

    struct TPortal (
        nearRange,
        farRange,
        mesh
    )
    
    fn ReadSector f version = (
        local msector = TSector()

        ReadU32 f --always 2049
        ReadU32 f --always 0

        local tr = TriMesh()        
        tr.numVerts = ReadU32 f
        tr.numFaces = ReadU32 f
        
        local ReadPoint = if version == #hd2 then ReadPoint4 else ReadPoint3  
        
        if version != #mafia then (
            msector.dmin = ReadPoint f
            msector.dmax = ReadPoint f
        )

        for vertId = 1 to tr.numVerts do (
            setVert tr vertId (ReadPoint f)
        )

        for faceId = 1 to tr.numFaces do (
            setFace tr faceId (ReadFace f)
            setFaceSmoothGroup tr faceId 0
            for c = 1 to 3 do setEdgeVis tr faceId c true
        )

        msector.mesh = tr
        if version == #mafia then (
            msector.dmin = ReadPoint f
            msector.dmax = ReadPoint f
        )

        local numPortals = ReadU8 f

        for i = 1 to numPortals do (
            local mportal = TPortal()
            local trp = TriMesh()
            trp.numVerts = ReadU8 f
            for j = 1 to 5 do ReadU32 f
            mportal.nearRange = ReadFloatSafe f
            mportal.farRange = ReadFloatSafe f
            
            if version != #mafia then ReadU32 f

            for vertId = 1 to trp.numVerts do (
                setVert trp vertId (ReadPoint f)
            )
            mportal.mesh = trp
            append msector.portals mportal
        )


        msector
    )
    
    fn WriteSector f sector version = (
        WriteU32 f 2049    --unknown
        WriteU32 f 0       --unknown

        local smesh = sector.mesh

        WriteU32 f smesh.numVerts
        WriteU32 f smesh.numFaces
        
        local WritePoint = if version == #hd2 then WritePoint4 else WritePoint3
        
        if version != #mafia then (
            WritePoint f sector.dmin
            WritePoint f sector.dmax
        )

        for i = 1 to smesh.numVerts do (
            local vert = getVert smesh i
            WritePoint f vert
        )

        for i = 1 to smesh.numFaces do (
            local face = getFace smesh i
            WriteFace f face
        )

        if version == #mafia then (
            WritePoint f sector.dmin
            WritePoint f sector.dmax
        )
        WriteU8 f sector.portals.count

        for portal in sector.portals do (
            WriteU8 f portal.mesh.numVerts
            WriteU32 f 4   --unknown
            for i = 1 to 4 do WriteU32 f 0 --unknown

            WriteFloat f portal.nearRange
            WriteFloat f portal.farRange
            
            if version != #mafia then WriteU32 f 0           
            
            for vertId = 1 to portal.mesh.numVerts do (
                WritePoint f (getVert portal.mesh vertId)
            )
        )
    )
    
    -------------------------------------------------

    struct TTarget (
        unk1,
        unk2,
        linkIds = #()   --array of u16, 1-based ids
    )    

    fn ReadTarget f = (
        local mTarget = TTarget()

        mTarget.unk1 = ReadU8 f
        mTarget.unk2 = ReadU8 f
        local numLinks = ReadU8 f

        for i = 1 to numLinks do (
            append mTarget.linkIds (ReadU16 f)
        )

        mTarget
    )

    fn WriteTarget f mtarget = (
        WriteU16 f 0
        WriteU8 f mtarget.linkIds.count

        for linkId in mtarget.linkIds do (
            WriteU16 f linkId
        )
    )
    
    -------------------------------------------------    
    
    struct TBone (
        matrix,
        boneId   --1-based
    )
    
    fn ReadBone f version = (
        local mbone = TBone()
        if version == #mafia do 
            mbone.matrix = ReadMatrix f
            
        mbone.boneId = (ReadU32 f) + 1
        mbone
    )

    fn WriteBone f mbone version = (
        if version == #mafia do 
            WriteMatrix f mbone.matrix

        WriteU32 f (mbone.boneId - 1)
    )   
    
    -------------------------------------------------
    
    struct TOccluder (
        mesh
    )
        
    fn ReadOccluder f version = (
        local tr = TriMesh()
        tr.numVerts = ReadU32 f
        tr.numFaces = ReadU32 f
        
        local ReadPoint = if version == #hd2 then ReadPoint4 else ReadPoint3  
        
        for vertId = 1 to tr.numVerts do (
            setVert tr vertId (ReadPoint f)
        )
        
        for faceId = 1 to tr.numFaces do (
            setFace tr faceId (ReadFace f)
            setFaceSmoothGroup tr faceId 0
            for c = 1 to 3 do setEdgeVis tr faceId c true
        )
        TOccluder mesh:tr
    )
    
    fn WriteOccluder f ocl version = (
        local tr = ocl.mesh
        WriteU32 f tr.numVerts
        WriteU32 f tr.numFaces 
        
        local WritePoint = if version == #hd2 then WritePoint4 else WritePoint3        
        
        for vertId = 1 to tr.numVerts do (
            WritePoint f (getVert tr vertId)
        )
        
        for faceId = 1 to tr.numFaces do (
            WriteFace f (getFace tr faceId)
        )
    )
    
    -------------------------------------------------
    
    fn ReadProjector f = (
        ReadU32 f
    )
    
    fn ReadLight f = (
        for i = 1 to 21 do ReadU32 f
    )
    
    fn ReadEmitor f = (
        ReadU32 f
        ReadU8 f
    )
)