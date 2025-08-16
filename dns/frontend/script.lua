local submitBtn = gurt.select('#submit')
local username_input = gurt.select('#username')
local password_input = gurt.select('#password')
local log_output = gurt.select('#log-output')

function addLog(message)
	gurt.log(message)
	log_output.text = log_output.text .. message .. '\\n'
end

print(gurt.location.href)
submitBtn:on('submit', function(event)
	local username = event.data.username
	local password = event.data.password

	local request_body = JSON.stringify({
    	username = username,
		password = password
	})
	print(request_body)
	local url = 'http://localhost:8080/auth/login'
	local headers = {
		['Content-Type'] = 'application/json'
	}

	addLog('Attempting to log in with username: ' .. username)
	log_output.text = ''

	local response = fetch(url, {
		method = 'POST',
		headers = headers,
		body = request_body
	})
	
	addLog('Response Status: ' .. response.status .. ' ' .. response.statusText)
	
	if response:ok() then
		addLog('Login successful!')
		local jsonData = response:json()
		if jsonData then
			addLog('Logged in as user: ' .. jsonData.user.username)
			addLog('Token: ' .. jsonData.token:sub(1, 20) .. '...')

			-- TODO: store as cookie
			gurt.location.goto("/dashboard.html")
		end
	else
		addLog('Request failed with status: ' .. response.status)
		local error_data = response:text()
		addLog('Error response: ' .. error_data)
	end
end)