return function(TweenService)
    local liveTweens = setmetatable({}, { __mode = "k" })

    local function detachTween(registry, animation)
        for property, current in pairs(registry) do
            if current == animation then registry[property] = nil end
        end
    end

    local function tween(instance, duration, properties, style, direction)
        local registry = liveTweens[instance] or {}
        local conflicts = {}
        for property in pairs(properties) do
            local previous = registry[property]
            if previous then conflicts[previous] = true end
        end
        for previous in pairs(conflicts) do
            detachTween(registry, previous)
            previous:Cancel()
        end

        local animation = TweenService:Create(instance, TweenInfo.new(
            duration,
            style or Enum.EasingStyle.Quad,
            direction or Enum.EasingDirection.Out
        ), properties)

        liveTweens[instance] = registry
        for property in pairs(properties) do
            registry[property] = animation
        end

        animation.Completed:Once(function()
            detachTween(registry, animation)
            if next(registry) == nil and liveTweens[instance] == registry then
                liveTweens[instance] = nil
            end
        end)
        animation:Play()
        return animation
    end

    local function killTween(instance, property)
        local registry = liveTweens[instance]
        if not registry then return end
        local animation = registry[property]
        if not animation then return end

        detachTween(registry, animation)
        animation:Cancel()
    end

    local function completed(animation, callback)
        if animation.PlaybackState == Enum.PlaybackState.Completed then
            callback()
            return
        end
        if animation.PlaybackState == Enum.PlaybackState.Cancelled then return end
        animation.Completed:Once(function(playback)
            if playback == Enum.PlaybackState.Completed then callback() end
        end)
    end

    return {
        Tween = tween,
        Cancel = killTween,
        Completed = completed,
    }
end
