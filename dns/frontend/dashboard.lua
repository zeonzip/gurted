local user = nil
local domains = {}
local tlds = {}
local authToken = nil

local userInfo = gurt.select('#user-info')
local domainsList = gurt.select('#domains-list')
local logArea = gurt.select('#log-area')
local inviteModal = gurt.select('#invite-modal')
local tldSelector = gurt.select('#tld-selector')

local logMessages = {}

local function addLog(message)
    table.insert(logMessages, Time.format(Time.now(), '%H:%M:%S') .. ' - ' .. message)
    if #logMessages > 50 then
        table.remove(logMessages, 1)
    end
    logArea.text = table.concat(logMessages, '\n')
end

local function showError(elementId, message)
    local element = gurt.select('#' .. elementId)
    
    element.text = message
    element.classList:remove('hidden')
end

local function hideError(elementId)
    local element = gurt.select('#' .. elementId)

    element.classList:add('hidden')
end

local function showModal(modalId)
    local modal = gurt.select('#' .. modalId)

    modal.classList:remove('hidden')
end

local function hideModal(modalId)
    local modal = gurt.select('#' .. modalId)
    
    modal.classList:add('hidden')
end

local function makeRequest(url, options)
    options = options or {}
    if authToken then
        options.headers = options.headers or {}
        options.headers.Authorization = 'Bearer ' .. authToken
    end
    return fetch(url, options)
end

local function checkAuth()
    authToken = gurt.crumbs.get("auth_token")
    
    if authToken then
        addLog('Found auth token, checking validity...')
        local response = makeRequest('gurt://localhost:4878/auth/me')
        print(table.tostring(response))
        if response:ok() then
            user = response:json()
            addLog('Authentication successful for user: ' .. user.username)
            updateUserInfo()
            loadDomains()
            loadTLDs()
        else
            addLog('Token invalid, redirecting to login...')
            --gurt.crumbs.delete('auth_token')
            --gurt.location.goto('../')
        end
    else
        addLog('No auth token found, redirecting to login...')
        gurt.location.goto('../')
    end
end

local function logout()
    gurt.crumbs.delete('auth_token')
    addLog('Logged out successfully')
    gurt.location.goto("../")
end

local function loadDomains()
    addLog('Loading domains...')
    local response = makeRequest('gurt://localhost:4878/domains?page=1&size=100')
    
    if response:ok() then
        local data = response:json()
        domains = data.domains or {}
        addLog('Loaded ' .. #domains .. ' domains')
        renderDomains()
    else
        addLog('Failed to load domains: ' .. response:text())
    end
end

local function loadTLDs()
    addLog('Loading available TLDs...')
    local response = fetch('gurt://localhost:4878/tlds')
    
    if response:ok() then
        tlds = response:json()
        addLog('Loaded ' .. #tlds .. ' TLDs')
        renderTLDSelector()
    else
        addLog('Failed to load TLDs: ' .. response:text())
    end
end

local function submitDomain(name, tld, ip)
    hideError('domain-error')
    addLog('Submitting domain: ' .. name .. '.' .. tld)
    
    local response = makeRequest('gurt://localhost:4878/domain', {
        method = 'POST',
        headers = { ['Content-Type'] = 'application/json' },
        body = JSON.stringify({ name = name, tld = tld, ip = ip })
    })
    
    if response:ok() then
        local data = response:json()
        addLog('Domain submitted successfully: ' .. data.domain)
        
        -- Update user registrations remaining
        user.registrations_remaining = user.registrations_remaining - 1
        updateUserInfo()
        
        -- Clear form
        gurt.select('#domain-name').text = ''
        gurt.select('#domain-ip').text = ''
        
        -- Refresh domains list
        loadDomains()
    else
        local error = response:text()
        showError('domain-error', 'Domain submission failed: ' .. error)
        addLog('Domain submission failed: ' .. error)
    end
end

local function createInvite()
    addLog('Creating invite code...')
    local response = makeRequest('gurt://localhost:4878/auth/invite', { method = 'POST' })
    
    if response:ok() then
        local data = response:json()
        local inviteCode = data.invite_code
        gurt.select('#invite-code-display').text = inviteCode
        addLog('Invite code created: ' .. inviteCode)
        showModal('invite-modal')
    else
        addLog('Failed to create invite: ' .. response:text())
    end
end

local function redeemInvite(code)
    hideError('redeem-error')
    addLog('Redeeming invite code: ' .. code)
    
    local response = makeRequest('gurt://localhost:4878/auth/redeem-invite', {
        method = 'POST',
        headers = { ['Content-Type'] = 'application/json' },
        body = JSON.stringify({ invite_code = code })
    })
    
    if response:ok() then
        local data = response:json()
        addLog('Invite redeemed: +' .. data.registrations_added .. ' registrations')
        
        -- Update user info
        user.registrations_remaining = user.registrations_remaining + data.registrations_added
        updateUserInfo()
        
        -- Clear form
        gurt.select('#invite-code-input').text = ''
    else
        local error = response:text()
        showError('redeem-error', 'Failed to redeem invite: ' .. error)
        addLog('Failed to redeem invite: ' .. error)
    end
end

-- UI rendering functions
local function updateUserInfo()
    if user then
        userInfo.text = 'Welcome, ' .. user.username .. ' | Registrations remaining: ' .. user.registrations_remaining
    end
end

local function renderTLDSelector()
    tldSelector.text = ''
    for i, tld in ipairs(tlds) do
        local option = gurt.create('div', {
            text = '.' .. tld,
            style = 'tld-option',
            ['data-tld'] = tld
        })
        
        option:on('click', function()
            -- Clear previous selection
            local options = gurt.selectAll('.tld-option')
            for j = 1, #options do
                options[j].classList:remove('tld-selected')
            end
            
            -- Select this option
            option.classList:add('tld-selected')
        end)
        
        tldSelector:append(option)
    end
end

local function renderDomains()
    domainsList.text = ''
    
    if #domains == 0 then
        local emptyMessage = gurt.create('div', {
            text = 'No domains registered yet. Submit your first domain below!',
            style = 'text-center text-[#6b7280] py-8'
        })
        domainsList:append(emptyMessage)
        return
    end
    
    for i, domain in ipairs(domains) do
        local domainItem = gurt.create('div', {
            style = 'domain-item'
        })
        
        local domainInfo = gurt.create('div', {})
        
        local domainName = gurt.create('div', {
            text = domain.name .. '.' .. domain.tld,
            style = 'font-bold text-lg'
        })
        
        local domainIP = gurt.create('div', {
            text = 'IP: ' .. domain.ip,
            style = 'text-[#6b7280]'
        })
        
        domainInfo:append(domainName)
        domainInfo:append(domainIP)
        
        local actions = gurt.create('div', {
            style = 'flex gap-2'
        })
        
        -- Update IP button
        local updateBtn = gurt.create('button', {
            text = 'Update IP',
            style = 'secondary-btn'
        })
        
        updateBtn:on('click', function()
            local newIP = prompt('Enter new IP address for ' .. domain.name .. '.' .. domain.tld .. ':')
            if newIP and newIP ~= '' then
                updateDomainIP(domain.name, domain.tld, newIP)
            end
        end)
        
        -- Delete button
        local deleteBtn = gurt.create('button', { text = 'Delete', style = 'danger-btn' })

        deleteBtn:on('click', function()
            if confirm('Are you sure you want to delete ' .. domain.name .. '.' .. domain.tld .. '?') then
                deleteDomain(domain.name, domain.tld)
            end
        end)
        
        actions:append(updateBtn)
        actions:append(deleteBtn)
        
        domainItem:append(domainInfo)
        domainItem:append(actions)
        domainsList:append(domainItem)
    end
end

local function updateDomainIP(name, tld, ip)
    addLog('Updating IP for ' .. name .. '.' .. tld .. ' to ' .. ip)
    
    local response = makeRequest('gurt://localhost:4878/domain/' .. name .. '/' .. tld, {
        method = 'PUT',
        headers = { ['Content-Type'] = 'application/json' },
        body = JSON.stringify({ ip = ip })
    })
    
    if response:ok() then
        addLog('Domain IP updated successfully')
        loadDomains()
    else
        addLog('Failed to update domain IP: ' .. response:text())
    end
end

local function deleteDomain(name, tld)
    addLog('Deleting domain: ' .. name .. '.' .. tld)
    
    local response = makeRequest('gurt://localhost:4878/domain/' .. name .. '/' .. tld, {
        method = 'DELETE'
    })
    
    if response:ok() then
        addLog('Domain deleted successfully')
        loadDomains()
    else
        addLog('Failed to delete domain: ' .. response:text())
    end
end

-- Event handlers
gurt.select('#logout-btn'):on('click', logout)

gurt.select('#submit-domain-btn'):on('click', function()
    local name = gurt.select('#domain-name').text
    local ip = gurt.select('#domain-ip').text
    local selectedTLD = gurt.select('.tld-selected')
    
    if not name or name == '' then
        showError('domain-error', 'Domain name is required')
        return
    end
    
    if not ip or ip == '' then
        showError('domain-error', 'IP address is required')
        return
    end
    
    if not selectedTLD then
        showError('domain-error', 'Please select a TLD')
        return
    end
    
    local tld = selectedTLD:getAttribute('data-tld')
    submitDomain(name, tld, ip)
end)

gurt.select('#create-invite-btn'):on('click', createInvite)

gurt.select('#redeem-invite-btn'):on('click', function()
    local code = gurt.select('#invite-code-input').text
    if code and code ~= '' then
        redeemInvite(code)
    end
end)

gurt.select('#close-invite-modal'):on('click', function()
    hideModal('invite-modal')
end)

gurt.select('#copy-invite-code'):on('click', function()
    local inviteCode = gurt.select('#invite-code-display').text
    Clipboard.write(inviteCode)
    addLog('Invite code copied to clipboard')
end)

-- Initialize
addLog('Dashboard initialized')
checkAuth()