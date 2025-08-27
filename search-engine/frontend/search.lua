local searchBtn = gurt.select('#searchButton')
local luckyBtn = gurt.select('#luckyButton')
local searchQuery = gurt.select('#searchQuery')
local loading = gurt.select('#loading')
local results = gurt.select('#results')
local stats = gurt.select('#stats')

local function showLoading()
    loading.classList:remove('hidden')
    results.text = ''
    stats.text = ''
end

local function displayResults(data)
    loading.classList:add('hidden')
    results.text = ''
    
    if not data.results or #data.results == 0 then
        local noResultsItem = gurt.create('div', {
            text = 'No results found for your query.',
            style = 'result-item'
        })
        results:append(noResultsItem)
        stats.text = 'No results found'
        return
    end
    
    for i, result in ipairs(data.results) do
        local resultItem = gurt.create('div', { style = 'result-item' })
        
        resultItem:on('click', function()
            gurt.location.goto(result.url)
        end)
        
        local headerDiv = gurt.create('div', { style = 'result-header' })
        
        if result.icon and result.icon ~= '' then
            local iconImg = gurt.create('img', {
                src = result.icon,
                style = 'result-icon',
                alt = 'Site icon'
            })
            headerDiv:append(iconImg)
        end
        
        local titleDiv = gurt.create('p', {
            text = result.title or result.url,
            style = 'result-title'
        })
        
        headerDiv:append(titleDiv)
        
        local urlDiv = gurt.create('p', {
            text = result.url,
            style = 'result-url'
        })
        
        local previewText = result.preview or result.description or ''
        if #previewText > 150 then
            previewText = previewText:sub(1, 147) .. '...'
        end
        
        local previewDiv = gurt.create('p', {
            text = previewText,
            style = 'result-preview'
        })
        
        resultItem:append(headerDiv)
        resultItem:append(urlDiv)
        resultItem:append(previewDiv)
        
        results:append(resultItem)
    end
    
    local resultCount = #data.results
    local totalResults = data.total_results or resultCount
    stats.text = 'Found ' .. totalResults .. ' result' .. (totalResults == 1 and '' or 's')
end

local function performSearch(query)
    if not query or query == '' then
        return
    end

    showLoading()
    
    local url = '/api/search?q=' .. urlEncode(query) .. '&per_page=20'
    local response = fetch(url, {
        method = 'GET'
    })
    
    if response:ok() then
        local data = response:json()
        displayResults(data)
    else
        loading.classList:add('hidden')
        results.text = ''
        stats.text = 'Search failed: ' .. response.status .. ' ' .. response.statusText
    end
end

local function performLuckySearch()
    showLoading()
    
    local luckyTerms = {'test', 'demo', 'api', 'web', 'site', 'page', 'home', 'index'}
    local randomTerm = luckyTerms[math.random(#luckyTerms)]
    
    local url = '/api/search?q=' .. urlEncode(randomTerm) .. '&per_page=50'
    local response = fetch(url, {
        method = 'GET'
    })
    
    if response:ok() then
        local data = response:json()
        if data.results and #data.results > 0 then
            local randomResult = data.results[math.random(#data.results)]
            gurt.location.goto(randomResult.url)
        else
            loading.classList:add('hidden')
            results.text = ''
            stats.text = 'No sites available for lucky search'
        end
    else
        loading.classList:add('hidden')
        results.text = ''
        stats.text = 'Lucky search failed'
    end
end

searchBtn:on('click', function()
    local query = searchQuery.value
    if query and query ~= '' then
        performSearch(query:trim())
    end
end)

luckyBtn:on('click', function()
    performLuckySearch()
end)

searchQuery:on('keydown', function(e)
    if e.key == 'Enter' then
        local query = searchQuery.value
        if query and query ~= '' then
            performSearch(query:trim())
        end
    end
end)

searchQuery:focus()