local _, ns = ...
function ns.Normalize(text)
    text = text:gsub('|c%x%x%x%x%x%x%x%x', ''):gsub('|r', '')
    text = text:gsub('|H.-|h(.-)|h', '%1'):gsub('|T.-|t', ' '):gsub('|A.-|a', ' ')
    -- Remove common invisible characters, preserving adjacent letters.
    text = text:gsub('\226\128\139', ''):gsub('\226\128\140', ''):gsub('\226\128\141', '')
    text = text:gsub('\239\187\191', ''):lower()
    text = text:gsub('[%p%c%s]+', ' '):gsub('^ +', ''):gsub(' +$', '')
    return text
end
local function add(index, phrase)
    local first = phrase:match('^(%S+)')
    if not first then return end
    index[first] = index[first] or {}
    index[first][#index[first] + 1] = phrase
end
function ns.Compile(db)
    local index, catalog = {}, {}
    local disabled = db.disabledTerms or {}
    local function ingest(list, aggressive)
        for phrase in list:gmatch('[^;]+') do
            phrase = ns.Normalize(phrase)
            if phrase ~= '' then catalog[phrase] = catalog[phrase] or {enabled=false} end
            if phrase ~= '' then catalog[phrase][aggressive and 'aggressive' or 'core']=true end
            if phrase ~= '' and (not aggressive or db.mode=='aggressive' or (db.enabledTerms or {})[phrase]) and not db.ignored[phrase] and not disabled[phrase] then
                add(index, phrase); catalog[phrase].enabled=true
            end
        end
    end
    ingest(ns.core)
    ingest(ns.aggressive, true)
    for phrase, enabled in pairs(db.custom) do
        if enabled and type(phrase) == 'string' then
            local term = ns.Normalize(phrase)
            if term ~= '' then
                catalog[term] = catalog[term] or {enabled=false}
                catalog[term].custom=true
                if not disabled[term] then add(index, term); catalog[term].enabled=true end
            end
        end
    end
    for term in pairs(db.deletedTerms or {}) do catalog[term]=nil end
    -- Rebuild from the effective catalog so deletions suppress every source.
    index={}
    for term, info in pairs(catalog) do if info.enabled then add(index,term) end end
    ns.index = index
    ns.termCatalog = catalog
end
function ns.Match(message)
    local normalized = ns.Normalize(message)
    local padded = ' ' .. normalized .. ' '
    local seen = {}
    for word in normalized:gmatch('%S+') do
        if not seen[word] then
            seen[word] = true
            for _, phrase in ipairs(ns.index[word] or {}) do
                if padded:find(' ' .. phrase .. ' ', 1, true) then return true, phrase end
            end
        end
    end
    return false
end
