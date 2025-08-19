local user = nil
local domains = {}
local tlds = {}
local authToken = nil

local userInfo = gurt.select('#user-info')
local domainsList = gurt.select('#domains-list')
local tldSelector = gurt.select('#tld-selector')
local loadingElement = gurt.select('#tld-loading')
local displayElement = gurt.select('#invite-code-display')
local options

displayElement:hide()

local function showError(elementId, message)
    local element = gurt.select('#' .. elementId)
    
    element.text = message
    element.classList:remove('hidden')
end

local function hideError(elementId)
    local element = gurt.select('#' .. elementId)

    element.classList:add('hidden')
end

local function updateUserInfo()
    userInfo.text = 'Welcome, ' .. user.username .. '!'
end

local function renderTLDSelector()
    loadingElement:remove()

    tldSelector.text = ''
    local i = 1
    local total = #tlds
    local intervalId

    intervalId = gurt.setInterval(function()
        if i > total then
            gurt.clearInterval(intervalId)
            return
        end

        local tld = tlds[i]
        local option = gurt.create('button', {
            text = '.' .. tld,
            style = 'tld-option',
            ['data-tld'] = tld
        })

        tldSelector:append(option)
        
        option:on('click', function()
            -- Clear previous selection
            if not options then
                options = gurt.selectAll('.tld-option')
            end

            for j = 1, #options do
                if options[j].classList:contains('tld-selected') then
                    options[j].classList:remove('tld-selected')
                end
            end

            -- Select this option
            option.classList:add('tld-selected')
        end)
        i = i + 1
    end, 16)
end

local function renderDomains()
    local loadingElement = gurt.select('#domains-loading')
    loadingElement:remove()
    
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

local function loadDomains()
    print('Loading domains...')
    local response = fetch('gurt://localhost:8877/domains?page=1&size=100', {
        headers = {
            Authorization = 'Bearer ' .. authToken
        }
    })
    
    if response:ok() then
        local data = response:json()
        domains = data.domains or {}
        print('Loaded ' .. #domains .. ' domains')
        renderDomains()
    else
        print('Failed to load domains: ' .. response:text())
    end
end

local function loadTLDs()
    print('Loading available TLDs...')
    local response = fetch('gurt://localhost:8877/tlds')
    
    if response:ok() then
        tlds = response:json()
        print('Loaded ' .. #tlds .. ' TLDs')
        renderTLDSelector()
    else
        print('Failed to load TLDs: ' .. response:text())
    end
end

local function checkAuth()
    authToken = gurt.crumbs.get("auth_token")
    
    if authToken then
        print('Found auth token, checking validity...')
        local response = fetch('gurt://localhost:8877/auth/me', {
            headers = {
                Authorization = 'Bearer ' .. authToken
            }
        })
        print(table.tostring(response))
        if response:ok() then
            user = response:json()
            print('Authentication successful for user: ' .. user.username)
            updateUserInfo()
            loadDomains()
            loadTLDs()
        else
            print('Token invalid, redirecting to login...')
            gurt.crumbs.delete('auth_token')
            gurt.location.goto('../')
        end
    else
        print('No auth token found, redirecting to login...')
        gurt.location.goto('../')
    end
end

local function logout()
    gurt.crumbs.delete('auth_token')
    print('Logged out successfully')
    gurt.location.goto("../")
end

local function submitDomain(name, tld, ip)
    hideError('domain-error')
    print('Submitting domain: ' .. name .. '.' .. tld)
    
    local response = fetch('gurt://localhost:8877/domain', {
        method = 'POST',
        headers = { 
            ['Content-Type'] = 'application/json',
            Authorization = 'Bearer ' .. authToken
        },
        body = JSON.stringify({ name = name, tld = tld, ip = ip })
    })
    
    if response:ok() then
        local data = response:json()
        print('Domain submitted successfully: ' .. data.domain)
        
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
        print('Domain submission failed: ' .. error)
    end
end

local function createInvite()
    print('Creating invite code...')
    local response = fetch('gurt://localhost:8877/auth/invite', { 
        method = 'POST',
        headers = {
            Authorization = 'Bearer ' .. authToken
        }
    })
    
    if response:ok() then
        local data = response:json()
        local inviteCode = data.invite_code
        displayElement.text = 'Invite code: ' .. inviteCode .. ' (copied to clipboard)'
        displayElement:show()
        Clipboard.write(inviteCode)
        print('Invite code created and copied to clipboard: ' .. inviteCode)
    else
        print('Failed to create invite: ' .. response:text())
    end
end

local function redeemInvite(code)
    hideError('redeem-error')
    print('Redeeming invite code: ' .. code)
    
    local response = fetch('gurt://localhost:8877/auth/redeem-invite', {
        method = 'POST',
        headers = { 
            ['Content-Type'] = 'application/json',
            Authorization = 'Bearer ' .. authToken
        },
        body = JSON.stringify({ invite_code = code })
    })
    
    if response:ok() then
        local data = response:json()
        print('Invite redeemed: +' .. data.registrations_added .. ' registrations')
        
        -- Update user info
        user.registrations_remaining = user.registrations_remaining + data.registrations_added
        updateUserInfo()
        
        -- Clear form
        gurt.select('#invite-code-input').text = ''
    else
        local error = response:text()
        showError('redeem-error', 'Failed to redeem invite: ' .. error)
        print('Failed to redeem invite: ' .. error)
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

-- Initialize
print('Dashboard initialized')
checkAuth()