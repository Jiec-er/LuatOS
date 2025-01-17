-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "nvm_test"
VERSION = "1.0.0"

--[[
这个demo不推荐使用, 建议使用fdb库
]]

-- 引入必要的库文件(lua编写), 内部库不需要require
sys = require("sys")

require "config"--默认数据文件
--引用nvm库
local nvm = require "nvm"

--先加载初始化数据
nvm.init("config.lua")

--检查一下现在的数据
log.info("nvm","get a",nvm.get("a"))
log.info("nvm","get b",nvm.get("b"))

--改一下看看，下次开机就会是这个值
nvm.set('a',nvm.get("a") + 1)
nvm.set('b',nvm.get("b") + 1)

--看看改之后的数据
log.info("nvm","get a",nvm.get("a"))
log.info("nvm","get b",nvm.get("b"))

-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!
