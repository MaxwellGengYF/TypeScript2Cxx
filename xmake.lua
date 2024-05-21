set_xmakever('2.9.1')
add_rules('mode.release', 'mode.debug', 'mode.releasedbg')
set_policy('build.ccache', not is_plat('windows'))
set_toolchains('llvm')

includes('test/xmake/xmake_func.lua', 'test/EASTL/xmake.lua')


target('test_codegen')
set_kind('object')
add_files('test/*.ts')
add_rules('codegen_ts', {script_dir = "__out/main.js"})
set_policy("build.across_targets_in_parallel", false)
target_end()

target('test')
_config_project({
    project_kind = 'binary',
    enable_exception = true
})
set_pcxxheader('test/core.h')
add_files('test/*.ts')
add_rules('compile_ts')
add_deps('eastl', 'test_codegen')
add_includedirs('.')
target_end()