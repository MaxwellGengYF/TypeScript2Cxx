rule("basic_settings")
on_config(function(target)
    local _, cc = target:tool("cxx")
    if is_plat("linux") then
        -- Linux should use -stdlib=libc++
        -- https://github.com/LuisaGroup/LuisaCompute/issues/58
        if (cc == "clang" or cc == "clangxx") then
            target:add("cxflags", "-stdlib=libc++", {
                force = true
            })
            target:add("syslinks", "c++")
        end
    end
end)
on_load(function(target)
    local _get_or = function(name, default_value)
        local v = target:extraconf("rules", "basic_settings", name)
        if v == nil then
            return default_value
        end
        return v
    end
    local toolchain = _get_or("das_toolchain", get_config('das_toolchain'))
    if toolchain then
        target:set("toolchains", toolchain)
    end
    local project_kind = _get_or("project_kind", nil)
    if project_kind then
        target:set("kind", project_kind)
    end
    if not is_plat("windows") then
        if project_kind == "static" then
            target:add("cxflags", "-fPIC", {
                tools = {"clang", "gcc"}
            })
        end
    end
    -- fma support
    if is_arch("x64", "x86_64") then
        target:add("cxflags", "-mfma", {
            tools = {"clang", "gcc"}
        })
    end
    local c_standard = target:values("c_standard")
    local cxx_standard = target:values("cxx_standard")
    if type(c_standard) == "string" and type(cxx_standard) == "string" then
        target:set("languages", c_standard, cxx_standard, {
            public = true
        })
    else
        target:set("languages", "clatest", "cxx20", {
            public = true
        })
    end

    local enable_exception = _get_or("enable_exception", nil)
    if enable_exception then
        target:set("exceptions", "cxx")
    else
        target:set("exceptions", "no-cxx")
    end

    if is_mode("debug") then
        target:set("runtimes", _get_or("runtime", "MDd"), {
            public = true
        })
        target:set("optimize", "none")
        target:set("warnings", "none")
        target:add("cxflags", "/GS", "/Gd", {
            tools = {"clang_cl", "cl"}
        })
    elseif is_mode("releasedbg") then
        target:set("runtimes", _get_or("runtime", "MD"), {
            public = true
        })
        target:set("optimize", "none")
        target:set("warnings", "none")
        target:add("cxflags", "/GS-", "/Gd", {
            tools = {"clang_cl", "cl"}
        })
    else
        target:set("runtimes", _get_or("runtime", "MD"), {
            public = true
        })
        target:set("optimize", "aggressive")
        target:set("warnings", "none")
        target:add("cxflags", "/GS-", "/Gd", {
            tools = {"clang_cl", "cl"}
        })
    end
    target:set("fpmodels", "fast")
    target:add("cxflags", "/Zc:preprocessor", {
        tools = "cl",
        public = true
    });
    if _get_or("use_simd", true) then
        if is_arch("arm64") then
            target:add("vectorexts", "neon")
        else
            target:add("vectorexts", "avx", "avx2")
        end
    end
    if _get_or("no_rtti", true) then
        target:add("cxflags", "/GR-", {
            tools = {"clang_cl", "cl"},
            public = true
        })
        target:add("cxflags", "-fno-rtti", "-fno-rtti-data", {
            tools = {"clang"},
            public = true
        })
        target:add("cxflags", "-fno-rtti", {
            tools = {"gcc"},
            public = true
        })
    end
end)
rule_end()
if _config_rules == nil then
    _config_rules = {"basic_settings"}
end
if not _config_project then
    function _config_project(config)
        local batch_size = config["batch_size"]
        if type(batch_size) == "number" and batch_size > 1 then
            add_rules("c.unity_build", {
                batchsize = batch_size
            })
            add_rules("c++.unity_build", {
                batchsize = batch_size
            })
        end
        if type(_config_rules) == "table" then
            add_rules(_config_rules, config)
        end
    end
end

rule('codegen_ts')
set_extensions(".ts")
on_buildcmd_file(function(target, batchcmds, sourcefile, opt)
    local lib = import('lib')
    local ts_utils = import('ts_utils')
    local script_dir = lib.string_replace(path.translate(target:extraconf("rules", "codegen_ts", "script_dir")), '\\', '/')
    local sb = lib.StringBuilder('node ')
    local file_path = lib.string_replace(sourcefile, '\\', '/')
    sb:add(script_dir):add(' '):add(file_path)
    local out_file = ts_utils.out_dir(sourcefile)
    batchcmds:add_depfiles(sourcefile)
    batchcmds:add_depfiles(out_file)
    batchcmds:vrunv(sb:to_string())
    batchcmds:show('generating ' .. file_path)
    sb:dispose()
end)
rule_end()

rule('compile_ts')
set_extensions(".ts")
on_buildcmd_file(function(target, batchcmds, sourcefile, opt)
    local lib = import('lib')
    local ts_utils = import('ts_utils')
    local out_file = ts_utils.out_dir(sourcefile)
    local objectfile = target:objectfile(out_file)
    table.insert(target:objectfiles(), objectfile)
    batchcmds:show("compiling " .. out_file)
    batchcmds:add_depfiles(out_file)
    batchcmds:set_depmtime(os.mtime(objectfile))
    batchcmds:set_depcache(target:dependfile(objectfile))
    batchcmds:compile(out_file, objectfile)
end)
rule_end()