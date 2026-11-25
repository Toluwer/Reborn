return function(Core, Theme, state, gui, windowFrame, connect)
    local GEO = Theme.Geometry
    local killTween = Core.killTween
    local open = state.openPops

    local function find(pop)
        for index, record in ipairs(open) do
            if record.pop == pop then
                return record, index
            end
        end
        return nil
    end

    local function unregisterPop(pop)
        local _, index = find(pop)
        if index then table.remove(open, index) end
    end

    local function registerPop(row, pop, setOpen, popH, popW, alignRight)
        unregisterPop(pop)
        table.insert(open, {
            row = row,
            pop = pop,
            popH = popH,
            popW = popW,
            alignRight = alignRight == true,
            close = function() setOpen(false) end,
        })
    end

    local function closePop(pop)
        local record = find(pop)
        if record then record.close() end
    end

    local function closeAll(except)
        for i = #open, 1, -1 do
            local record = open[i]
            if record.pop ~= except then
                record.close()
            end
        end
    end

    local function contains(element, point)
        local position = element.AbsolutePosition
        local size = element.AbsoluteSize
        return point.X >= position.X - 1 and point.X <= position.X + size.X + 1
            and point.Y >= position.Y - 1 and point.Y <= position.Y + size.Y + 1
    end

    local function closeOutside(point)
        for i = #open, 1, -1 do
            local record = open[i]
            if not contains(record.row, point) and not contains(record.pop, point) then
                record.close()
            end
        end
    end

    local function mountPop(row, pop, popH, popW, alignRight)
        local rp, rs = row.AbsolutePosition, row.AbsoluteSize
        local wp = windowFrame.AbsolutePosition
        local wb = wp.Y + windowFrame.AbsoluteSize.Y
        local topMin = wp.Y + GEO.Header + 8
        local capH = (wb - 8) - topMin
        if capH > 0 and popH > capH then popH = capH end
        local x = alignRight and (rp.X + rs.X - GEO.RowPad - popW) or rp.X
        local y = rp.Y + rs.Y + 6
        if y + popH > wb - 8 then
            y = rp.Y - popH - 6
            if y < topMin then
                y = topMin
            end
        end
        pop.Parent = gui
        pop.ZIndex = 45
        pop.AnchorPoint = Vector2.new(0, 0)
        pop.Size = UDim2.new(0, popW, 0, popH)
        return x, y, popH
    end

    local function trackTabScroll(tab)
        local scroller = tab._scroller
        local lastCanvasY = scroller.CanvasPosition.Y
        connect(scroller:GetPropertyChangedSignal("CanvasPosition"), function()
            local cy = scroller.CanvasPosition.Y
            local d = cy - lastCanvasY
            lastCanvasY = cy
            if d == 0 or state.activeTab ~= tab then return end
            local wp = windowFrame.AbsolutePosition
            local wb = wp.Y + windowFrame.AbsoluteSize.Y
            local topMin = wp.Y + GEO.Header + 8
            for i = #open, 1, -1 do
                local p = open[i]
                local pos = p.pop.Position
                local ny = pos.Y.Offset - d
                local pb = ny + (p.popH or 0)
                if pb < topMin + 4 or ny > wb - 12 then
                    p.close()
                else
                    killTween(p.pop, "Position")
                    p.pop.Position = UDim2.new(0, pos.X.Offset, 0, ny)
                end
            end
        end)
    end

    return {
        Register = registerPop,
        Unregister = unregisterPop,
        Close = closePop,
        CloseAll = closeAll,
        CloseOutside = closeOutside,
        Contains = contains,
        Mount = mountPop,
        TrackScroll = trackTabScroll,
    }
end
