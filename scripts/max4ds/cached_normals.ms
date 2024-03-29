plugin modifier CachedNormals
name:"Cached Normals"
classID:#(0x580d250, 0x35f8095)
replaceUI:true version:1 invisible:true
(
    parameters main rollout:rltParams
    (
        normals type:#point3Tab tabsizevariable:true
        normalFaces type:#point3Tab tabsizevariable:true
    )

    rollout rltParams "Parameters" (
        label lblDeprecated "Deprecated" height:20
        label lblInfo "- Can be exported\n  only by the 4ds exporter\n- Not displayed in viewport\n  or in renders" height:60
        button btnEditNormals "Convert to Edit Normals"
        
        on rltParams open do (
            if nspec == undefined then (
                lblDeprecated.visible = false
            )
        )

        on btnEditNormals pressed do (
            try (
                undo "Convert cached normals" on (
                    local index = modPanel.getModifierIndex $ this

                    local norm = EditNormals()
                    norm.displayLength = 0.1
                    addModifier $ norm before:(index-1)
                    modPanel.setCurrentObject norm

                    disableRefMsgs()

                    local numfaces = amin #(normalFaces.count, $.numfaces)

                    local numNormals = norm.getnumnormals()
                    norm.Break selection:#{1..numNormals}

                    for i = 1 to numfaces do (
                        local nface = normalFaces[i]
                        for v = 1 to 3 do (
                            local nvertId = nface[v] as integer
                            local normal = normals[nvertId]
                            norm.setNormalId i v nvertId
                            norm.setNormal nvertId normal
                        )
                    )
                    numNormals = norm.getnumnormals()
                    norm.MakeExplicit selection:#{1..numNormals}
                    enableRefMsgs()
                    norm.RebuildNormals()

                    deleteModifier $ this
                    modPanel.setCurrentObject norm
                )
            )
            catch (
                local ex = getCurrentException()
                enableRefMsgs()
                messageBox ("Error occured\n" + ex) icon:#critical
            )
        )
    )
)
