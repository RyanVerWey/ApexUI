from pathlib import Path
import runpy
ctx=runpy.run_path(str(Path(__file__).with_name('test_standalone.py')))
lua=ctx['lua'];root=ctx['ROOT']
lua.execute((root/'BarOptions.lua').read_text(),'ApexUI',lua.globals().A)
lua.execute("""
local bars=A.Active().addons.ApexBars.bars
local other=bars.Bar9.numIcons
A.ConfigureBar('MainBar','count',-2);assert(bars.MainBar.numIcons==10 and bars.Bar9.numIcons==other)
A.ConfigureBar('MainBar','rows',1);assert(bars.MainBar.numRows==2)
A.ConfigureBar('MainBar','size',2);assert(bars.MainBar.buttonWidth==52)
assert(A.ActionBars.frames.Bar9.buttons[1]:GetAttribute('action')==13)
local imported=A.Backend.FillDefaults({addons={ApexBars={bars={Bar6={buttonWidth=0,buttonHeight=0},StanceBar={numIcons=12}}}}})
assert(imported.addons.ApexBars.bars.Bar6.buttonWidth==50 and imported.addons.ApexBars.bars.StanceBar.numIcons==10)
local first=A.ActionBars.frames.MainBar.buttons[1]
local originalTexture=GetActionTexture
GetActionTexture=function() return nil end
bars.MainBar.alwaysShowButtons=false;A.ActionBars.Apply();assert(first.hideEmpty)
GetActionTexture=originalTexture;A.ActionBars.Apply()
A.ConfigureBar('Bar3','visible');assert(not bars.Bar3.alwaysHidden)
combat=true;A.ConfigureBar('MainBar','count',-1);assert(bars.MainBar.numIcons==10);combat=false
A.OpenBarOptions();assert(ApexBarOptions:IsShown())
ApexBarOptions.scripts.OnEvent();assert(not ApexBarOptions:IsShown())
""")
print('PASS: independent bar counts, row/size controls, visibility and combat lock.')
