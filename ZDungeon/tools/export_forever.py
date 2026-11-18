"""Run QuestieDB's own tools/export-forever.lua (merged Forever data incl. corrections)
with the LuaJIT bundled in the lupa Python package. Usage: export_forever.py QUESTIEDB_PATH"""
import os, sys
from lupa import lua51 as lupa
os.chdir(sys.argv[1])
rt = lupa.LuaRuntime(unpack_returned_tuples=True)
rt.execute('arg = {[0]="tools/export-forever.lua", "--include-authored"}')
rt.execute('dofile("tools/export-forever.lua")')
