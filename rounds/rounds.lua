mod = {}

if IsServer then
	print("MOD LOADED ON SERVER")
end

if IsClient then
	print("MOD LOADED ON CLIENT")
end

print("IsClient:", IsClient)
print("IsServer:", IsServer)

return mod
