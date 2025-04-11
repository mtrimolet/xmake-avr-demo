add_rules("mode.debug", "mode.release")

set_languages("c++latest")

option("avr", {default = "/usr"})
option("mcu", {default = "atmega2560"})

set_warnings("allextra", "error")
set_symbols("hidden")
add_rules("plugin.compile_commands.autoupdate", {outputdir = ".vscode"})

toolchain("llvm-avr")
    set_kind("standalone")
    set_homepage("https://llvm.org/")
    set_description("A collection of modular and reusable compiler and toolchain technologies")

    set_toolset("cc",     "clang")
    set_toolset("cxx",    "clang", "clang++")
    set_toolset("mxx",    "clang", "clang++")
    set_toolset("mm",     "clang")
    set_toolset("cpp",    "clang -E")
    set_toolset("as",     "clang")
    set_toolset("ld",     "avr-g++", "avr-gcc")
    set_toolset("sh",     "avr-g++", "avr-gcc")
    set_toolset("ar",     "llvm-ar")
    set_toolset("strip",  "llvm-strip")
    set_toolset("ranlib", "llvm-ranlib")
    set_toolset("objcopy","llvm-objcopy", "avr-objcopy")
    set_toolset("mrc",    "llvm-rc")

    on_load(function (toolchain)
        local march = {"--target=avr", "--gcc-toolchain=" .. get_config("avr"), "-isystem", path.join(get_config("avr"), "avr", "include"), "--sysroot=" .. path.join(get_config("avr"), "avr"), "-mmcu="..get_config("mcu")}
        toolchain:add("cxflags", table.unwrap(march))
        toolchain:add("mxflags", table.unwrap(march))
        toolchain:add("asflags", table.unwrap(march))
        toolchain:add("ldflags", "-Wl,--gc-sections", "-mmcu="..get_config("mcu"))
        toolchain:add("shflags", "-Wl,--gc-sections", "-mmcu="..get_config("mcu"))

        toolchain:add("defines", "__DELAY_BACKWARD_COMPATIBLE__", "F_CPU=8000000")
    end)
toolchain_end()

target("avr-demo")
    set_kind("binary")

    set_optimize("smallest")

    set_plat("cross")
    set_toolchains("llvm-avr")
    add_cxflags("-ffunction-sections", "-fdata-sections", {force = true})
    add_ldflags("-Wl,--gc-sections", {force = true})

    add_files("src/**.mpp")
    add_files("src/*.cpp")

    after_link(function(target)
        import("lib.detect.find_tool")
        import("utils.progress")
        import("core.project.depend")

        local targetfile = target:targetfile()

        local dependfile = target:dependfile(targetfile..".ihex")
        local dependinfo = target:is_rebuilt() and {} or (depend.load(dependfile) or {})

        depend.on_changed(function()
            local objcopy = find_tool("avr-objcopy") or find_tool("objcopy")
            assert(objcopy, "unable to find tool objcopy")
            progress.show(100, "${color.build.object}Generating rom file")
            os.vrunv(objcopy.program, {"-S", "-O", "ihex", targetfile, targetfile..".ihex"})
        end, {dependfile = dependfile, files = {targetfile}, changed = target:is_rebuilt()})
    end)

    on_run(function(target)
        import("lib.detect.find_tool")
        import("utils.progress")
        local avrdude = find_tool("avrdude")
        assert(avrdude, "unable to find tool avrdude")
        progress.show(100, "${color.build.target}Uploading rom file")
        os.vrunv(avrdude.program, {"-p", get_config("mcu"), "-C", "+.avrduderc", "-U", "flash:w:"..target:targetfile()..".ihex:i"})
    end)
