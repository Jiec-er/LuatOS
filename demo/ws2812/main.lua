-- LuaTools需要PROJECT和VERSION这两个信息
PROJECT = "ws2812demo"
VERSION = "1.0.0"

log.info("main", PROJECT, VERSION)

-- 引入必要的库文件(lua编写), 内部库不需要require
sys = require("sys")

local rtos_bsp = rtos.bsp():lower()
if rtos_bsp=="air101" or rtos_bsp=="air103" then
    mcu.setClk(240)
end

if wdt then
    --添加硬狗防止程序卡死，在支持的设备上启用这个功能
    wdt.init(9000)--初始化watchdog设置为9s
    sys.timerLoopStart(wdt.feed, 3000)--3s喂一次狗
end

local show_520 = {
    {0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff},
    {0x0000ff,0x00ff00,0x00ff00,0x0000ff,0x0000ff,0x00ff00,0x00ff00,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff},
    {0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x0000ff,0x0000ff,0x0000ff},
    {0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x00ff00,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x00ff00,0x0000ff,0x00ff00,0x0000ff,0x00ff00,0x0000ff,0x0000ff,0x0000ff,0x0000ff},
    {0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x00ff00,0x0000ff,0x00ff00,0x0000ff,0x0000ff,0x0000ff,0x0000ff},
    {0x0000ff,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x00ff00,0x0000ff,0x00ff00,0x0000ff,0x0000ff,0x0000ff,0x00ff00,0x0000ff,0x00ff00,0x0000ff,0x0000ff,0x0000ff,0x0000ff},
    {0x0000ff,0x0000ff,0x00ff00,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x0000ff,0x0000ff,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x00ff00,0x00ff00,0x00ff00,0x0000ff,0x0000ff,0x0000ff,0x0000ff},
    {0x0000ff,0x0000ff,0x0000ff,0x00ff00,0x00ff00,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff,0x0000ff},
}
local show_520_w = 24
local show_520_h = 8

local ws2812_w = 8
local ws2812_h = 8
local buff = zbuff.create({ws2812_w,ws2812_h,24},0x000000)

local function ws2812_roll_show(show_data,data_w)
    local m = 0
    while 1 do
        for j=0,ws2812_w-1 do
            if j%2==0 then
                for i=ws2812_w-1,0,-1 do
                    if m+ws2812_w-i>data_w then
                        buff:pixel(i,j,show_data[j+1][m+ws2812_w-i-data_w])
                    else
                        buff:pixel(i,j,show_data[j+1][m+ws2812_w-i])
                    end
                end
            else
                for i=0,ws2812_w-1 do
                    if m+i+1>data_w then
                        buff:pixel(i,j,show_data[j+1][m+i+1-data_w])
                    else
                        buff:pixel(i,j,show_data[j+1][m+i+1])
                    end
                end
            end
        end
        m = m+1
        if m==data_w then m=0 end
        --可选pwm,gpio,spi方式驱动,API详情查看wiki https://wiki.luatos.com/api/sensor.html
        sensor.ws2812b(7,buff,0,20,20,0)--此处使用gpio方法驱动
        -- sensor.ws2812b_pwm(5,buff)--此处使用pwm方法驱动
        -- sensor.ws2812b_spi(0,buff)--此处使用spi方法驱动
        sys.wait(300)
    end
end
sys.taskInit(function()
    sys.wait(500)
    ws2812_roll_show(show_520,show_520_w)
end)
-- 用户代码已结束---------------------------------------------
-- 结尾总是这一句
sys.run()
-- sys.run()之后后面不要加任何语句!!!!!
