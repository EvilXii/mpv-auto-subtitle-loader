-- auto-load-subs.lua
-- Configuration
local settings = {
    sub_extensions = {'srt', 'ass', 'ssa', 'sub'},
    min_similarity = 0.7,
    log_level = {info = true, debug = true, verbose = true},
    colors = {
        reset = "\27[0m", bright = "\27[1m", dim = "\27[2m",
        red = "\27[31m", green = "\27[32m", yellow = "\27[33m",
        blue = "\27[34m", magenta = "\27[35m", cyan = "\27[36m"
    }
}

-- Logging functions
local function log(level, color, message)
    if settings.log_level[level] then
        local prefix = settings.colors[color] .. "[mpv-auto-subs] " .. settings.colors.reset
        mp.msg.info(prefix .. message)
        io.stderr:write(prefix .. message .. "\n")
    end
end

local function log_info(message) log("info", "green", message) end
local function log_debug(message) log("debug", "cyan", message) end
local function log_verbose(message) log("verbose", "dim", message) end

-- Check if file extension is a subtitle extension
function is_subtitle(ext)
    for _, sub_ext in ipairs(settings.sub_extensions) do
        if ext:lower() == sub_ext:lower() then return true end
    end
    return false
end

-- Clean filename by removing common patterns
function clean_filename(filename)
    log_verbose("Original filename: " .. filename)
    local clean = filename:lower()
    clean = clean:gsub("%.%w+$", ""):gsub("%[.-%]", ""):gsub("%(1080p%)", "")
                  :gsub("%(720p%)", ""):gsub("^%[crunchyroll%]%s*", "")
                  :gsub("^%[subsplease%]%s*", ""):gsub("^%[horriblesubs%]%s*", "")
                  :gsub("^%[erai%-raws%]%s*", ""):gsub("%[[%x]+%]", "")
                  :gsub("%s+", " "):gsub("^%s*(.-)%s*$", "%1")
    log_verbose("Cleaned filename: " .. clean)
    return clean
end

-- Calculate similarity between two strings
function string_similarity(str1, str2)
    local len1, len2, matrix = #str1, #str2, {}
    for i = 0, len1 do matrix[i] = {[0] = 0} for j = 1, len2 do matrix[i][j] = 0 end end
    for i = 1, len1 do for j = 1, len2 do
        if str1:sub(i,i) == str2:sub(j,j) then matrix[i][j] = matrix[i-1][j-1] + 1
        else matrix[i][j] = math.max(matrix[i-1][j], matrix[i][j-1]) end end end
    return (2.0 * matrix[len1][len2]) / (len1 + len2)
end

-- Get all subtitle files in directory
function get_all_subs(video_dir)
    local subs, p = {}, io.popen('ls "' .. video_dir .. '"')
    if p then
        for file in p:lines() do
            local ext = file:match("%.(%w+)$")
            if ext and is_subtitle(ext) then
                table.insert(subs, {path = video_dir .. "/" .. file, similarity = 0})
                log_debug("Found subtitle file: " .. file)
            end
        end
        p:close()
    else log_debug("Failed to open directory: " .. video_dir) end
    return subs
end

-- Find matching subtitle files
function find_subs(video_path)
    if not video_path then
        log_debug("No video path detected. Exiting function.")
        return {}
    end
    
    -- Check for absolute path
    local video_dir, video_name = video_path:match("(.+)[/\\]"), video_path:match("[^/\\]+$")
    if not video_dir then
        local working_dir = mp.get_property("working-directory", "")
        if working_dir and #working_dir > 0 then
            video_path = working_dir .. "/" .. video_path
            video_dir, video_name = working_dir, video_path:match("[^/\\]+$")
        end
    end
    
    if not video_dir or not video_name then
        log_debug("Could not extract video directory or filename from path: " .. (video_path or "nil"))
        return {}
    end
    
    log_info("Processing video: " .. video_name)
    local clean_video_name, matching_subs = clean_filename(video_name), {}
    local p = io.popen('ls "' .. video_dir .. '"')
    if p then
        log_info("Scanning for matching subtitle files...")
        for file in p:lines() do
            local ext = file:match("%.(%w+)$")
            if ext and is_subtitle(ext) then
                local clean_sub_name = clean_filename(file)
                local similarity = string_similarity(clean_video_name, clean_sub_name)
                log_verbose(string.format("Comparing:\n  Video: %s\n  Sub: %s\n  Similarity: %.3f", 
                    clean_video_name, clean_sub_name, similarity))
                if similarity >= settings.min_similarity then
                    log_debug(string.format("Match found: %s (%.3f)", file, similarity))
                    table.insert(matching_subs, {path = video_dir .. "/" .. file, similarity = similarity})
                end
            end
        end
        p:close()
    else log_debug("Failed to open directory for matching subtitles") end
    if #matching_subs == 0 then
        log_info("No close matches found. Loading all subtitle files...")
        matching_subs = get_all_subs(video_dir)
    end
    table.sort(matching_subs, function(a, b) return a.similarity > b.similarity end)
    log_info(string.format("Found %d subtitle(s)", #matching_subs))
    return matching_subs
end

-- Load subtitles
function load_subs(event)
    local video_path = mp.get_property("path")
    if not video_path then
        log_info("Video path is nil; cannot proceed with subtitle loading.")
        return
    end
    
    log_info("=" .. string.rep("=", 40))
    log_info("Processing new video file")
    local subs = find_subs(video_path)
    if subs and #subs > 0 then
        for i, sub in ipairs(subs) do
            mp.commandv("sub-add", sub.path)
            log_info(string.format("Loaded subtitle %d/%d: %s (similarity: %.3f)", 
                i, #subs, sub.path:match("[^/]+$"), sub.similarity))
        end
        log_info("Subtitle loading complete")
    else
        log_info("No subtitles found in directory")
    end
    log_info("=" .. string.rep("=", 40))
end

mp.register_event("file-loaded", load_subs)
log_info("Auto-subtitle loader initialized")
