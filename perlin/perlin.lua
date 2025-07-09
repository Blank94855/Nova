local perlin = {}

local conf = require("config")

-- Default configuration
local defaultConfig = {
	scale = 1.0, -- overall frequency scale
	octaves = 1, -- number of noise layers
	persistence = 0.5, -- amplitude scaling per octave
	lacunarity = 2.0, -- frequency scaling per octave
	seed = 0, -- if nonzero, used to seed the permutation
}

--------------------------------------------------------------------------------
-- Perlin Noise Internals
--------------------------------------------------------------------------------

-- A basic 2D gradient array
local grad2 = {
	{ 1, 1 },
	{ -1, 1 },
	{ 1, -1 },
	{ -1, -1 },
	{ 1, 0 },
	{ -1, 0 },
	{ 0, 1 },
	{ 0, -1 },
}

-- Classic base permutation table (for fallback if seed == 0)
local basePermutation = {
	151,
	160,
	137,
	91,
	90,
	15,
	131,
	13,
	201,
	95,
	96,
	53,
	194,
	233,
	7,
	225,
	140,
	36,
	103,
	30,
	69,
	142,
	8,
	99,
	37,
	240,
	21,
	10,
	23,
	190,
	6,
	148,
	247,
	120,
	234,
	75,
	0,
	26,
	197,
	62,
	94,
	252,
	219,
	203,
	117,
	35,
	11,
	32,
	57,
	177,
	33,
	88,
	237,
	149,
	56,
	87,
	174,
	20,
	125,
	136,
	171,
	168,
	68,
	175,
	74,
	165,
	71,
	134,
	139,
	48,
	27,
	166,
	77,
	146,
	158,
	231,
	83,
	111,
	229,
	122,
	60,
	211,
	133,
	230,
	220,
	105,
	92,
	41,
	55,
	46,
	245,
	40,
	244,
	102,
	143,
	54,
	65,
	25,
	63,
	161,
	1,
	216,
	80,
	73,
	209,
	76,
	132,
	187,
	208,
	89,
	18,
	169,
	200,
	196,
	135,
	130,
	116,
	188,
	159,
	86,
	164,
	100,
	109,
	198,
	173,
	186,
	3,
	64,
	52,
	217,
	226,
	250,
	124,
	123,
	5,
	202,
	38,
	147,
	118,
	126,
	255,
	82,
	85,
	212,
	207,
	206,
	59,
	227,
	47,
	16,
	58,
	17,
	182,
	189,
	28,
	42,
	223,
	183,
	170,
	213,
	119,
	248,
	152,
	2,
	44,
	154,
	163,
	70,
	221,
	153,
	101,
	155,
	167,
	43,
	172,
	9,
	129,
	22,
	39,
	253,
	19,
	98,
	108,
	110,
	79,
	113,
	224,
	232,
	178,
	185,
	112,
	104,
	218,
	246,
	97,
	228,
	251,
	34,
	242,
	193,
	238,
	210,
	144,
	12,
	191,
	179,
	162,
	241,
	81,
	51,
	145,
	235,
	249,
	14,
	239,
	107,
	49,
	192,
	214,
	31,
	181,
	199,
	106,
	157,
	184,
	84,
	204,
	176,
	115,
	121,
	50,
	45,
	127,
	4,
	150,
	254,
	138,
	236,
	205,
	93,
	222,
	114,
	67,
	29,
	24,
	72,
	243,
	141,
	128,
	195,
	78,
	66,
	215,
	61,
	156,
	180,
}

-- Fisher-Yates shuffle for permutation
local function shuffle(tbl)
	for i = #tbl, 2, -1 do
		local j = math.random(i)
		tbl[i], tbl[j] = tbl[j], tbl[i]
	end
end

--------------------------------------------------------------------------------
-- Permutation Caching
--------------------------------------------------------------------------------

-- Cache table (seed -> permutation array)
-- The key is the seed; the value is the expanded 512-entry permutation array.
local permutationsCache = {}

local function getPermutationForSeed(seed)
	-- Check if we already have a permutation table for this seed
	if permutationsCache[seed] then
		return permutationsCache[seed]
	end

	-- Otherwise, generate a new permutation for this seed
	local permutation = {}
	for i = 1, 256 do
		permutation[i] = basePermutation[i]
	end

	if seed ~= 0 then
		math.randomseed(seed)
		shuffle(permutation)
	end

	-- Duplicate for simpler indexing (p[i+256] = p[i])
	local p = {}
	for i = 1, 512 do
		p[i] = permutation[(i - 1) % 256 + 1]
	end

	-- Store in cache before returning
	permutationsCache[seed] = p
	return p
end

--------------------------------------------------------------------------------
-- Perlin Noise Functions
--------------------------------------------------------------------------------

-- The fade function for smoothing
local function fade(t)
	return t * t * t * (t * (t * 6 - 15) + 10)
end

-- Linear interpolation
local function lerp(a, b, t)
	return a + t * (b - a)
end

-- Dot product with the selected gradient
local function gradDot2(hash, x, y)
	local g = grad2[(hash % #grad2) + 1]
	return g[1] * x + g[2] * y
end

-- The core 2D Perlin function: returns value in [-1, 1]
-- We'll pass in the permutation table 'p' to keep it flexible.
local function perlin2D(p, x, y)
	-- Find cell coords
	local X = math.floor(x) % 256
	local Y = math.floor(y) % 256

	-- Relative coords in cell
	local xf = x - math.floor(x)
	local yf = y - math.floor(y)

	-- Corner hashes
	local aa = p[X + 1 + p[Y + 1]]
	local ab = p[X + 1 + p[Y + 1 + 1]]
	local ba = p[X + 1 + 1 + p[Y + 1]]
	local bb = p[X + 1 + 1 + p[Y + 1 + 1]]

	-- Fade curves
	local u = fade(xf)
	local v = fade(yf)

	-- Gradients for each corner
	local x1 = gradDot2(aa, xf, yf)
	local x2 = gradDot2(ba, xf - 1, yf)
	local y1 = lerp(x1, x2, u)

	x1 = gradDot2(ab, xf, yf - 1)
	x2 = gradDot2(bb, xf - 1, yf - 1)
	local y2 = lerp(x1, x2, u)

	-- Final interpolation
	return lerp(y1, y2, v)
end

--------------------------------------------------------------------------------
-- Public API
--------------------------------------------------------------------------------

function perlin.noise(x, y, config)
	local ok, err = pcall(function()
		config = conf:merge(defaultConfig, config)
	end)
	if not ok then
		error(err, 2)
	end

	local scale = config.scale
	local octaves = config.octaves
	local persistence = config.persistence
	local lacunarity = config.lacunarity
	local seed = config.seed

	-- Retrieve or create the cached permutation table for this seed
	local p = getPermutationForSeed(seed)

	local total = 0
	local frequency = 1
	local amplitude = 1
	local maxValue = 0 -- used to normalize

	for _ = 1, octaves do
		-- Evaluate Perlin noise at scaled coordinates
		local noiseVal = perlin2D(p, x * scale * frequency, y * scale * frequency)
		total = total + noiseVal * amplitude

		maxValue = maxValue + amplitude
		amplitude = amplitude * persistence
		frequency = frequency * lacunarity
	end

	-- Normalize to [-1, 1]
	local normalized = total / maxValue
	return normalized
end

return perlin
