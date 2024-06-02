add_rules("mode.debug", "mode.release")

-- 设置C++17标准
set_languages("cxx17")

-- 添加编译选项
add_defines("NOMINMAX", "UNICODE", "WIN32_LEAN_AND_MEAN", "_CRT_SECURE_NO_WARNINGS", "_CRT_SECURE_NO_DEPRECATE", "_CRT_NONSTDC_NO_DEPRECATE")

-- libbreakpad 目标
add_requires("zlib","gtest","libdisasm","gflags","glog")
target("libbreakpad")
    set_kind("static")
    add_files("src/processor/*.cc")
    add_includedirs("src", {public = true})
    add_headerfiles("src/(**.h)")

    if is_plat("windows") then
        remove_files("src/processor/*_unittest.cc", "src/processor/*_selftest.cc", "src/processor/synth_minidump.cc", 
                        "src/processor/tests/**.cc", "src/processor/testdata/**.cc", "src/processor/linux/**.cc", 
                        "src/processor/mac/**.cc", "src/processor/android/**.cc", "src/processor/solaris/**.cc", 
                        "src/processor/microdump_stackwalk.cc", "src/processor/minidump_dump.cc", "src/processor/minidump_stackwalk.cc", 
                        "src/processor/disassembler_objdump.cc")
    elseif is_plat("macosx") then
        remove_files("src/processor/*_unittest.cc", "src/processor/*_selftest.cc", "src/processor/synth_minidump.cc", 
                        "src/processor/tests/**.cc", "src/processor/testdata/**.cc", "src/processor/linux/**.cc", 
                        "src/processor/windows/**.cc", "src/processor/android/**.cc", "src/processor/solaris/**.cc", 
                        "src/processor/microdump_stackwalk.cc", "src/processor/minidump_dump.cc", "src/processor/minidump_stackwalk.cc", 
                        "src/processor/disassembler_objdump.cc")
    else
        remove_files("src/processor/*_unittest.cc", "src/processor/*_selftest.cc", "src/processor/synth_minidump.cc", 
                        "src/processor/tests/**.cc", "src/processor/testdata/**.cc", "src/processor/mac/**.cc", 
                        "src/processor/windows/**.cc", "src/processor/android/**.cc", "src/processor/solaris/**.cc", 
                        "src/processor/microdump_stackwalk.cc", "src/processor/minidump_dump.cc", "src/processor/minidump_stackwalk.cc")
    end

    -- 手动添加 libdisasm 链接
    add_packages("libdisasm")


-- libbreakpad_client 目标
target("libbreakpad_client")
    set_kind("static")
    add_files("src/common/*.cc", "src/client/*.cc")
    add_includedirs("src", {public = true})
    add_headerfiles("src/(**.h)")

    if is_plat("windows") then
        add_files("src/client/windows/**.cc", "src/common/windows/**.cc")
        remove_files("src/common/language.cc", "src/common/path_helper.cc", "src/common/stabs_to_module.cc",
                     "src/common/stabs_reader.cc", "src/common/minidump_file_writer.cc")
        add_links("wininet")
    elseif is_plat("macosx") then
        add_defines("HAVE_MACH_O_NLIST_H")
        add_files("src/client/mac/**.cc", "src/common/mac/**.cc", "src/common/mac/MachIPC.mm")
        add_frameworks("CoreFoundation")
    else
        add_defines("HAVE_A_OUT_H", "HAVE_GETCONTEXT=1")
        add_files("src/client/linux/**.cc", "src/common/linux/**.cc")
        add_packages("zlib", "gtest", "gflags", "glog")
        add_links("pthread")
        -- 在这里添加检查 getcontext 函数的逻辑
    end


-- 安装选项

if is_plat("linux") then
    target("microdump_stackwalk")
        set_kind("binary")
        add_files("src/processor/microdump_stackwalk.cc")
        add_deps("libbreakpad", "libbreakpad_client")
        add_installfiles("microdump_stackwalk", {prefixdir = "bin"})

    target("minidump_dump")
        set_kind("binary")
        add_files("src/processor/minidump_dump.cc")
        add_deps("libbreakpad", "libbreakpad_client")
        add_installfiles("minidump_dump", {prefixdir = "bin"})

    target("minidump_stackwalk")
        set_kind("binary")
        add_files("src/processor/minidump_stackwalk.cc")
        add_deps("libbreakpad", "libbreakpad_client")
        add_installfiles("minidump_stackwalk", {prefixdir = "bin"})

    target("core2md")
        set_kind("binary")
        add_files("src/tools/linux/core2md/core2md.cc")
        add_deps("libbreakpad_client")
        add_installfiles("core2md", {prefixdir = "bin"})

    target("pid2md")
        set_kind("binary")
        add_files("src/tools/linux/pid2md/pid2md.cc")
        add_deps("libbreakpad_client")
        add_installfiles("pid2md", {prefixdir = "bin"})

    target("dump_syms")
        set_kind("binary")
        add_files("src/common/dwarf_cfi_to_module.cc", "src/common/dwarf_cu_to_module.cc", "src/common/dwarf_line_to_module.cc",
                    "src/common/dwarf_range_list_handler.cc", "src/common/language.cc", "src/common/module.cc",
                    "src/common/path_helper.cc", "src/common/stabs_reader.cc", "src/common/stabs_to_module.cc",
                    "src/common/dwarf/bytereader.cc", "src/common/dwarf/dwarf2diehandler.cc", "src/common/dwarf/dwarf2reader.cc",
                    "src/common/dwarf/elf_reader.cc", "src/tools/linux/dump_syms/dump_syms.cc")
        add_deps("libbreakpad_client")
        add_installfiles("dump_syms", {prefixdir = "bin"})

    target("minidump-2-core")
        set_kind("binary")
        add_files("src/common/linux/memory_mapped_file.cc", "src/tools/linux/md2core/minidump-2-core.cc")
        add_deps("libbreakpad_client")
        add_installfiles("minidump-2-core", {prefixdir = "bin"})

    target("minidump_upload")
        set_kind("binary")
        add_files("src/common/linux/http_upload.cc", "src/tools/linux/symupload/minidump_upload.cc")
        add_deps("libbreakpad_client")
        add_installfiles("minidump_upload", {prefixdir = "bin"})

    target("sym_upload")
        set_kind("binary")
        add_files("src/common/linux/http_upload.cc", "src/common/linux/libcurl_wrapper.cc", 
                    "src/common/linux/symbol_collector_client.cc", "src/common/linux/symbol_upload.cc",
                    "src/tools/linux/symupload/sym_upload.cc")
        add_deps("libbreakpad_client")
        add_installfiles("sym_upload", {prefixdir = "bin"})

    target("core_handler")
        set_kind("binary")
        add_files("src/tools/linux/core_handler/core_handler.cc")
        add_deps("libbreakpad_client")
        add_installfiles("core_handler", {prefixdir = "bin"})
end


        -- 其他工具目标，类似以上设置


-- 安装头文件
    -- on_install(function (target)
    --     if is_plat("windows") then
    --         os.cp("src/client", path.join(target:installdir(), "include"), {excludes = "/apple|/ios|/linux|/mac|/solaris|/android|/dwarf|/tests|/testdata|/unittests"})
    --     elseif is_plat("macosx") then
    --         os.cp("src/client", path.join(target:installdir(), "include"), {excludes = "/apple|/ios|/linux|/windows|/solaris|/android|/dwarf|/tests|/testdata|/unittests|/sender|/testapp|%.xcodeproj|/gcov"})
    --     else
    --         os.cp("src/client", path.join(target:installdir(), "include"))
    --         -- os.cp("src/third_party/lss", path.join(target:installdir(), "include/third_party"), {matches = "%.h"})
    --     end
    -- end)


