local vehicles = require 'shared.vehicles'

---@type table<number, Vehicle>
local vehicleHashes = {}
for _, v in pairs(vehicles) do
    vehicleHashes[v.hash] = v
end

return {
    Vehicles = vehicles,
    VehicleHashes = vehicleHashes,
}