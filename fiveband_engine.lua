-- init.lua
engine.name = "fiveband_engine"

local BUS_START = 16 -- choose a free bus index (must be even)
local BAND_COUNT = 5
local band_buses = {} -- will hold {leftBus, rightBus} pairs
local band_fx = {} -- placeholders for per-band fx chains

function init()
  -- params for crossover freqs
  params:add{type="control", id="f1", name="f1 (low/mid1)", min=20, max=2000, default=200, action=function(v) engine.set(\f1, v) end}
  params:add{type="control", id="f2", name="f2 (mid1/mid2)", min=100, max=5000, default=800, action=function(v) engine.set(\f2, v) end}
  params:add{type="control", id="f3", name="f3 (mid2/mid3)", min=500, max=10000, default=3000, action=function(v) engine.set(\f3, v) end}
  params:add{type="control", id="f4", name="f4 (mid3/high)", min=1000, max=16000, default=8000, action=function(v) engine.set(\f4, v) end}

  -- per-band send levels (unity default)
  for i=1,BAND_COUNT do
    params:add{type="control", id="band"..i.."_gain", name="band "..i.." gain", min=0, max=2, default=1, action=function(v) end}
  end

  -- allocate bus pairs for bands
  for i=0,BAND_COUNT-1 do
    local base = BUS_START + i*2
    band_buses[i+1] = {base, base+1}
  end

  -- start engine synth: input bus 0, output buses start at BUS_START
  -- ensure engine synth is running and writing bands to buses
  engine.load("fiveband_engine")
  -- spawn the synth; pass outBus = BUS_START
  -- use engine API to create synth; if engine.start is not available, use engine.run pattern
  -- Norns engine synth creation
  engine.start() -- placeholder if engine requires explicit start
  -- create the synth with parameters
  -- The following uses norns engine command pattern
  engine.create("fiveband_engine", {inBus=0, outBus=BUS_START, f1=params:get("f1"), f2=params:get("f2"), f3=params:get("f3"), f4=params:get("f4")})

  -- create per-band FX chains as DSP nodes reading from buses and writing to main output
  -- simple example: read band bus, apply gain, sum to output
  for i=1,BAND_COUNT do
    local leftBus = band_buses[i][1]
    local rightBus = band_buses[i][2]
    -- create soft placeholder synths in SuperCollider or handle in Lua via audio routing
    -- For Norns, use engine to read buses and mix; here we assume engine exposes a helper synth
    -- We'll call a generic mixer synth per band (must be implemented in engine if needed)
    engine.create("band_mixer", {inBus=leftBus, inBusR=rightBus, gain=params:get("band"..i.."_gain"), outBus=0})
  end

  -- UI
  screen.clear()
  screen.move(10,20)
  screen.text("5-band stereo crossover loaded")
  screen.update()
end

function key(n,z)
  if n==2 and z==1 then
    params:show()
  end
end
