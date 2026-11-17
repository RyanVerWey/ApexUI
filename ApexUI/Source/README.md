# Corresponding source

The runnable Lua is included as editable source. Original pre-wrapper module
sources are in the four directories beside this file. Original profession data
builders, tests, licenses and credits are retained under ApexProfessions.

To rebuild wrappers, put the four module directories beside an ApexUI directory.
Copy the distributed ApexUI root Lua, TOC and license into that directory; put
build_suite.py in ApexUI/tools, then run python ApexUI/tools/build_suite.py.
Python 3.9+ is required. No compilation or generated binary is needed to run Lua.
Data-refresh tools additionally require their documented upstream data inputs.
They are not needed for installation. Local checks use Python and lupa.lua51.

Modified by ApexInterfectum, November 17, 2026. GPL-3.0. Third-party notices
remain in their respective source directories. ApexProfessions is a modified
Craft Ladder fork; see its UPSTREAM.md, LICENSE and CREDITS.txt.
