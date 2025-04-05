add_rules("mode.debug", "mode.release")

set_languages("c++latest")

set_warnings("allextra", "error")
set_symbols("hidden")
add_rules("plugin.compile_commands.autoupdate", {outputdir = ".vscode"})

target("avr-demo")
    set_kind("binary")

    set_optimize("smallest")

    set_toolchains("cross")
    add_cxflags("gcc::-ffunction-sections", "gcc::-fdata-sections", "-mmcu=atmega2560")
    add_ldflags("-Wl,--gc-sections", "-mmcu=atmega2560")

    add_defines("F_CPU=8000000")

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
        os.vrunv(avrdude.program, {"-c", "stk500v2", "-P", "/dev/cu.usbmodem142101", "-p", "atmega2560", "-U", "flash:w:"..target:targetfile()..".ihex:i"})
    end)
