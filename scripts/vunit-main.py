import os
from glob import glob
from os.path import dirname, isfile, join

from vunit import VUnit

ghdl_elab_flags = '-g -Wbinding -Wreserved -Wlibrary -Wvital-generic -Wdelayed-checks -Wbody -Wspecs -Wunused --mb-comments --std=08 --ieee=synopsys -fexplicit'.split()
ghdl_sim_flags = ''.split()

src_path = join(dirname(__file__), '..', "src")
test_path = join(dirname(__file__), '..', "test")


def isignored(p):
    if 'instr_mem.vhdl' in p and os.environ['RUN_MAIN'] == '1':
        p = p.replace('src', 'out')

    with open(p, 'r') as f:
        ignored = '--%IGNORE%--' in f.readline()
        if ignored:
            print(f'ignore file: {p.replace("scripts/../", "")}')
        return ignored


def get_files(p):
    return [f for f in glob(join(p, '**/*.vhd?'), recursive=True) if isfile(f) and not isignored(f)]


vu = VUnit.from_argv()

vu.add_library("project").add_source_files(
    [*get_files(src_path), *get_files(test_path)]
)

vu.set_compile_option("ghdl.flags", ghdl_elab_flags)
vu.set_sim_option('ghdl.elab_flags', ghdl_elab_flags)
vu.set_sim_option('ghdl.sim_flags', ghdl_sim_flags)
vu.set_sim_option('ghdl.elab_e', True)

vu.set_compile_option("rivierapro.vcom_flags", ["-coverage", "bs"])
vu.set_compile_option("rivierapro.vlog_flags", ["-coverage", "bs"])
vu.set_compile_option("modelsim.vcom_flags", ["+cover=bs"])
vu.set_compile_option("modelsim.vlog_flags", ["+cover=bs"])
vu.set_sim_option("enable_coverage", True)

vu.main()
