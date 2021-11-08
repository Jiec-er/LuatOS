
-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "nimbledemo"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

-- 一定要添加sys.lua !!!!
local sys = require "sys"

--添加硬狗防止程序卡死
if wdt then
    wdt.init(15000)--初始化watchdog设置为15s
    sys.timerLoopStart(wdt.feed, 10000)--10s喂一次狗
else
    log.warn("wdt", "not wdt found!!!")
end


leds = {}
if rtos.bsp() == "air101" then -- 与w800/805等价
    leds["a"] = gpio.setup(24, 0, gpio.PULLUP) -- PB_08,输出模式
    leds["b"] = gpio.setup(25, 0, gpio.PULLUP) -- PB_09,输出模式
    leds["c"] = gpio.setup(26, 0, gpio.PULLUP) -- PB_10,输出模式
elseif rtos.bsp() == "air103" then -- 与w806等价
    leds["a"] = gpio.setup(16, 0, gpio.PULLUP) -- PB0,输出模式
    leds["b"] = gpio.setup(17, 0, gpio.PULLUP) -- PB1,输出模式
    leds["c"] = gpio.setup(18, 0, gpio.PULLUP) -- PB2,输出模式
else
    log.info("gpio", "pls add gpio.setup for you board")
end

if lcd then
    spi_lcd = spi.deviceSetup(0,20,0,0,8,20*1000*1000,spi.MSB,1,1)
    lcd.setColor(0x0000,0xFFFF)
    log.info("lcd.init",
    lcd.init("st7735s",{port = "device",pin_dc = 17, pin_pwr = 7,pin_rst = 19,direction = 2,w = 160,h = 80,xoffset = 1,yoffset = 26},spi_lcd))
    lcd.clear()
    lcd.setFont(lcd.font_opposansm12_chinese)
    lcd.drawStr(30,15,"nimbledemo",0X07FF)
    lcd.drawStr(50,35,"监听中",0x001F)
else
    log.info("lcd", "lcd not found, display is off")
end

gpio.setup(0, function(val) print("PA0 L",val) lcd.fill(0,40,160,80) if lcd and val == 0 then lcd.drawStr(50,60,"L按下",0x07E0) end end, gpio.PULLUP)--PA0 L
gpio.setup(7, function(val) print("PA7 U",val) lcd.fill(0,40,160,80) if lcd and val == 0 then lcd.drawStr(50,60,"U按下",0x07E0) end end, gpio.PULLUP)--PA7 U
gpio.setup(4, function(val) print("PA4 C",val) lcd.fill(0,40,160,80) if lcd and val == 0 then lcd.drawStr(50,60,"C按下",0x07E0) end end, gpio.PULLUP)--PA4 C
gpio.setup(1, function(val) print("PA1 D",val) lcd.fill(0,40,160,80) if lcd and val == 0 then lcd.drawStr(50,60,"D按下",0x07E0) end end, gpio.PULLUP)--PA1 D
gpio.setup(27, function(val) print("PB11 R",val) lcd.fill(0,40,160,80) if lcd and val == 0 then lcd.drawStr(50,60,"R按下",0x07E0) end end, gpio.PULLUP)--PB11 R


-- 注册一个命令列表
cmds = {
    -- 控制led的命令
    led = function(id, val)
        local led = leds[id]
        if led then
            led(val == "on" and 1 or 0)
        end
    end,
    -- 重启板子的命令
    reboot = function()
        sys.taskInit(function()
            log.info("ble", "cmd reboot, after 5s")
            sys.wait(5000)
            rtos.reboot()
        end)
    end,
    -- 显示屏输出内容的命令
    display = function(text)
        lcd.fill(0, 20, 160, 36)
        lcd.drawStr(50 , 35, text ,0x001F)
    end,
}

-- 监听BLE主适配的状态变化,需要nimble库
if nimble then
    -- BLE初始化成功或失败会产生该事件
    sys.subscribe("BLE_STATE_INC", function(state)
        log.info("ble", "ble state changed", state)
        if state == 1 then
            nimble.server_init()
        else
            nimble.server_deinit()
        end
    end)
    
    -- 监听GATT服务器的WRITE_CHR事件
    sys.subscribe("BLE_GATT_WRITE_CHR", function(info, data)
        -- info 是个table, 但当前没有数据
        log.info("ble", "data got!!", data:toHex())
        if data:len() == 0 then
            return
        end
        -- led,a,on 对应hex值 6c65642c612c6f6e
        -- led,b,on 对应hex值 6c65642c622c6f6e
        -- led,c,on 对应hex值 6c65642c632c6f6e
        -- led,a,off 对应 6c65642c612c6f6666
        -- led,b,off 对应 6c65642c622c6f6666
        -- led,c,off 对应 6c65642c632c6f6666
        -- display,xxx 对应 646973706C6179xxx, 支持中文
        local cmd = data:split(",")
        if cmd[1] and cmds[cmd[1]] then
            cmds[cmd[1]](table.unpack(cmd, 2))
        else
            log.info("ble", "unkown cmd", json.encode(cmd))
        end
    end)

    
    -- TODO 支持传数据(read)和推送数据(notify)

    -- 配合微信小程序 "BLE蓝牙开发助手"
    -- 1. 若开发板无天线, 将手机尽量靠近芯片也能搜到
    -- 2. 该小程序是开源的, 每次write会自动分包为16字节

    sys.taskInit(function()
        sys.wait(2000) -- 为了能看到日志,休眠2秒
        nimble.debug(6) -- 开启日志
        nimble.init() -- 初始化nimble, 会产生事件BLE_STATE_INC
    end)
else
    -- 没有nimble, 那就闪灯吧
    sys.taskInit(function()
        if not leds["a"] then
            return
        end
        local count = 0
        local uid = ""
        if mcu then
            uid = mcu.unique_id():toHex()
        elseif nbiot then
            uid = nbiot.imei()
        end
        log.warn("ble", "no nimble found, just led")
        while true do
            leds["a"](count & 0x01 == 0x01 and 1 or 0)
            leds["b"](count & 0x02 == 0x02 and 1 or 0)
            leds["c"](count & 0x03 == 0x03 and 1 or 0)
            log.info("gpio", "Go Go Go", uid, count)
            sys.wait(1000)
            count = count + 1
        end
    end)
end




-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!