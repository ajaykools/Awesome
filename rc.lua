-- Standard awesome library
require("awful")
require("awful.autofocus")
require("awful.rules")
-- Theme handling library
require("beautiful")
-- Notification library
require("naughty")
require('vicious')

-- Load Debian menu entries
require("debian.menu")

-- {{{ Variable definitions
-- Themes define colours, icons, and wallpapers
beautiful.init("/usr/share/awesome/themes/zenburn/theme.lua")

-- This is used later as the default terminal and editor to run.
terminal = "guake"
editor = os.getenv("EDITOR") or "emacsclient -t"
editor_cmd = terminal .. " -e " .. editor

-- Default modkey.
-- Usually, Mod4 is the key with a logo between Control and Alt.
-- If you do not like this or do not have such a key,
-- I suggest you to remap Mod4 to another key using xmodmap or other tools.
-- However, you can use another modifier like Mod1, but it may interact with others.
modkey = "Mod4"

-- Table of layouts to cover with awful.layout.inc, order matters.
layouts =
   {
   awful.layout.suit.floating,
   awful.layout.suit.tile,
   awful.layout.suit.tile.left,
   awful.layout.suit.tile.bottom,
   awful.layout.suit.tile.top,
   awful.layout.suit.fair,
   awful.layout.suit.fair.horizontal,
   awful.layout.suit.spiral,
   awful.layout.suit.spiral.dwindle,
   awful.layout.suit.max,
   awful.layout.suit.max.fullscreen,
   awful.layout.suit.magnifier
}
-- }}}

-- {{{ Tags
-- Define a tag table which hold all screen tags.
tags = {}
for s = 1, screen.count() do
   -- Each screen has its own tag table.
   tags[s] = awful.tag({ 1, 2, 3, 4 }, s, layouts[1])
end
-- }}}

-- {{{ Menu
-- Create a laucher widget and a main menu
myawesomemenu = {
   { "manual", terminal .. " -e man awesome" },
   { "edit config", editor_cmd .. " " .. awful.util.getdir("config") .. "/rc.lua" },
   { "restart", awesome.restart },
   { "quit", awesome.quit }
}

mymainmenu = awful.menu({ items = { { "awesome", myawesomemenu, beautiful.awesome_icon },
                                    { "Debian", debian.menu.Debian_menu.Debian },
				    --  { "open terminal", terminal }
				    {"Log out", '/home/ajay/projects/awesome/shutdown_dialog.sh'}
				 }
		       })

mylauncher = awful.widget.launcher({ image = image(beautiful.awesome_icon),
                                     menu = mymainmenu })
-- }}}

-- {{{ Wibox
-- Create a textclock widget
mytextclock = awful.widget.textclock({ align = "right" })

-- Create a systray
mysystray = widget({ type = "systray" })

-- Volume
volumewidget = widget({ type = "textbox" })
vicious.register(volumewidget, vicious.widgets.volume, " $1%", 2, "Master")
volumewidget:buttons(awful.util.table.join(
			awful.button({ }, 1, function ()  
						awful.util.spawn_with_shell("pavucontrol") 
					     end)
		  ))
volume_widget = widget({ type = "textbox", name = "tb_volume", align = "right" })

function update_volume(widget)
   local fd = io.popen("amixer sget Master")
   local status = fd:read("*all")
   fd:close()
   
   local volume = tonumber(string.match(status, "(%d?%d?%d)%%")) / 100
   -- volume = string.format("% 3d", volume)
   
   status = string.match(status, "%[(o[^%]]*)%]")
   
   -- starting colour
   local sr, sg, sb = 0x3F, 0x3F, 0x3F
   -- ending colour
   local er, eg, eb = 0xDC, 0xDC, 0xCC
   
   local ir = volume * (er - sr) + sr
   local ig = volume * (eg - sg) + sg
   local ib = volume * (eb - sb) + sb
   interpol_colour = string.format("%.2x%.2x%.2x", ir, ig, ib)
   if string.find(status, "on", 1, true) then
      volume = " <span background='#" .. interpol_colour .. "'>   </span>"
   else
      volume = " <span color='red' background='#" .. interpol_colour .. "'> M </span>"
   end
   widget.text = volume
end

update_volume(volume_widget)
awful.hooks.timer.register(1, function () update_volume(volume_widget) end)

-- Battery 
-- batwidget = widget({type="textbox", name="Battery", align="right"})
-- vicious.register(batwidget, vicious.widgets.bat, "$2%", 180, "BAT0")

bboxwidget = widget({ type = "textbox", align="right" })
vicious.register(bboxwidget, vicious.widgets.bat, 
		 function (widget, args)
		    if args[1] == "-" then return string.format("%s hours rem. %s%s",args[3],args[2],"%")
		    elseif args[2] == "100" then return  "Charged"
		    else return string.format("%s charged, %s to cmpltly chrg",args[2], args[3])
		    end
		 end
		 ,180,"BAT0")

-- bboxwid = widget({ type = "textbox" })
-- vicious.register(bboxwid, vicious.widgets.bat, "$1", 180, "BAT0")


-- Create a wibox for each screen and add it
mywibox = {}
mypromptbox = {}
mylayoutbox = {}
mytaglist = {}
mytaglist.buttons = awful.util.table.join(
   awful.button({ }, 1, awful.tag.viewonly),
   awful.button({ modkey }, 1, awful.client.movetotag),
   awful.button({ }, 3, awful.tag.viewtoggle),
   awful.button({ modkey }, 3, awful.client.toggletag),
   awful.button({ }, 4, awful.tag.viewnext),
   awful.button({ }, 5, awful.tag.viewprev)
)
mytasklist = {}
mytasklist.buttons = awful.util.table.join(
   awful.button({ }, 1, function (c)
			   if not c:isvisible() then
			      awful.tag.viewonly(c:tags()[1])
			   end
			   client.focus = c
			   c:raise()
			end),
   awful.button({ }, 3, function ()
			   if instance then
			      instance:hide()
			      instance = nil
			   else
			      instance = awful.menu.clients({ width=250 })
			   end
			end),
   awful.button({ }, 4, function ()
			   awful.client.focus.byidx(1)
			   if client.focus then client.focus:raise() end
			end),
   awful.button({ }, 5, function ()
			   awful.client.focus.byidx(-1)
			   if client.focus then client.focus:raise() end
			end))

for s = 1, screen.count() do
   -- Create a promptbox for each screen
   mypromptbox[s] = awful.widget.prompt({ layout = awful.widget.layout.horizontal.leftright })
   -- Create an imagebox widget which will contains an icon indicating which layout we're using.
   -- We need one layoutbox per screen.
   mylayoutbox[s] = awful.widget.layoutbox(s)
   mylayoutbox[s]:buttons(awful.util.table.join(
			     awful.button({ }, 1, function () awful.layout.inc(layouts, 1) end),
			     awful.button({ }, 3, function () awful.layout.inc(layouts, -1) end),
			     awful.button({ }, 4, function () awful.layout.inc(layouts, 1) end),
			     awful.button({ }, 5, function () awful.layout.inc(layouts, -1) end)))
   -- Create a taglist widget
   mytaglist[s] = awful.widget.taglist(s, awful.widget.taglist.label.all, mytaglist.buttons)

   -- Create a tasklist widget
   mytasklist[s] = awful.widget.tasklist(function(c)
					    return awful.widget.tasklist.label.currenttags(c, s)
					 end, mytasklist.buttons)

   -- Create the wibox
   mywibox[s] = awful.wibox({ position = "top", screen = s })
   -- Add widgets to the wibox - order matters
   mywibox[s].widgets = {
      {
	 mylauncher,
	 mytaglist[s],
	 mypromptbox[s],
	 layout = awful.widget.layout.horizontal.leftright
      },
      mylayoutbox[s],
      mytextclock,
      s == 1 and mysystray or nil,
      volumewidget,
      volume_widget,
--      batwidget,
      bboxwidget,
      mytasklist[s],
      layout = awful.widget.layout.horizontal.rightleft
   }
end
-- }}}

-- {{{ Mouse bindings
root.buttons(awful.util.table.join(
		awful.button({ }, 3, function () mymainmenu:toggle() end),
		awful.button({ }, 4, awful.tag.viewnext),
		awful.button({ }, 5, awful.tag.viewprev)
	  ))
-- }}}

-- {{{ Key bindings
globalkeys = awful.util.table.join(
   awful.key({ modkey,           }, "Left",   awful.tag.viewprev       ),
   awful.key({ modkey,           }, "Right",  awful.tag.viewnext       ),
   awful.key({ modkey,           }, "Escape", awful.tag.history.restore),

   awful.key({ modkey,           }, "j",
	     function ()
		awful.client.focus.byidx( 1)
		if client.focus then client.focus:raise() end
	     end),
   awful.key({ modkey,           }, "k",
	     function ()
		awful.client.focus.byidx(-1)
		if client.focus then client.focus:raise() end
	     end),
   awful.key({ modkey,           }, "w", function () mymainmenu:show({keygrabber=true}) end),

   -- Layout manipulation
   awful.key({ modkey, "Shift"   }, "j", function () awful.client.swap.byidx(  1)    end),
   awful.key({ modkey, "Shift"   }, "k", function () awful.client.swap.byidx( -1)    end),
   awful.key({ modkey, "Control" }, "j", function () awful.screen.focus_relative( 1) end),
   awful.key({ modkey, "Control" }, "k", function () awful.screen.focus_relative(-1) end),
   awful.key({ modkey,           }, "u", awful.client.urgent.jumpto),
   awful.key({ modkey,           }, "Tab",
	     function ()
		awful.client.focus.history.previous()
		if client.focus then
		   client.focus:raise()
		end
	     end),

   -- Standard program
   awful.key({ modkey,           }, "Return", function () awful.util.spawn(terminal) end),
   awful.key({ modkey, "Control" }, "r", awesome.restart),
   awful.key({ modkey, "Shift"   }, "q", awesome.quit),

   awful.key({ modkey,           }, "l",     function () awful.tag.incmwfact( 0.05)    end),
   awful.key({ modkey,           }, "h",     function () awful.tag.incmwfact(-0.05)    end),
   awful.key({ modkey, "Shift"   }, "h",     function () awful.tag.incnmaster( 1)      end),
   awful.key({ modkey, "Shift"   }, "l",     function () awful.tag.incnmaster(-1)      end),
   awful.key({ modkey, "Control" }, "h",     function () awful.tag.incncol( 1)         end),
   awful.key({ modkey, "Control" }, "l",     function () awful.tag.incncol(-1)         end),
   awful.key({ modkey,           }, "space", function () awful.layout.inc(layouts,  1) end),
   awful.key({ modkey, "Shift"   }, "space", function () awful.layout.inc(layouts, -1) end),

   -- Application switcher
   awful.key({ modkey,           }, "Escape", function ()
						 --If you want to always position the menu on the same place set coordinates
						 awful.menu.menu_keys.down = { "Down", "Alt_L" }
						 local cmenu = awful.menu.clients({width=245}, { keygrabber=true, coords={x=525, y=330} })
					      end),
   
   -- Lock screen
   awful.key({ }, "#150", function () awful.util.spawn("xscreensaver-command -lock") end),

   -- Volume Controls
   awful.key({ }, "XF86AudioRaiseVolume", function ()
					     awful.util.spawn("amixer set Master 9%+") end),
   awful.key({ }, "XF86AudioLowerVolume", function ()
					     awful.util.spawn("amixer set Master 9%-") end),
   awful.key({ }, "XF86AudioMute", function ()
				      awful.util.spawn("amixer sset Master toggle") end),
   
   -- Prompt
   awful.key({ modkey },            "r",     function () mypromptbox[mouse.screen]:run() end),

   awful.key({ modkey }, "x",
	     function ()
		awful.prompt.run({ prompt = "Run Lua code: " },
				 mypromptbox[mouse.screen].widget,
				 awful.util.eval, nil,
				 awful.util.getdir("cache") .. "/history_eval")
	     end)
)

clientkeys = awful.util.table.join(
   awful.key({ modkey,           }, "f",      function (c) c.fullscreen = not c.fullscreen  end),
   awful.key({ modkey, "Shift"   }, "c",      function (c) c:kill()                         end),
   awful.key({ modkey, "Control" }, "space",  awful.client.floating.toggle                     ),
   awful.key({ modkey, "Control" }, "Return", function (c) c:swap(awful.client.getmaster()) end),
   awful.key({ modkey,           }, "o",      awful.client.movetoscreen                        ),
   awful.key({ modkey, "Shift"   }, "r",      function (c) c:redraw()                       end),
   awful.key({ modkey,           }, "t",      function (c) c.ontop = not c.ontop            end),
   awful.key({ modkey,           }, "n",      function (c) c.minimized = not c.minimized    end),
   awful.key({ modkey,           }, "m",
	     function (c)
		c.maximized_horizontal = not c.maximized_horizontal
		c.maximized_vertical   = not c.maximized_vertical
	     end)
)

-- Compute the maximum number of digit we need, limited to 9
keynumber = 0
for s = 1, screen.count() do
   keynumber = math.min(9, math.max(#tags[s], keynumber));
end

-- Bind all key numbers to tags.
-- Be careful: we use keycodes to make it works on any keyboard layout.
-- This should map on the top row of your keyboard, usually 1 to 9.
for i = 1, keynumber do
   globalkeys = awful.util.table.join(globalkeys,
				      awful.key({ modkey }, "#" .. i + 9,
						function ()
						   local screen = mouse.screen
						   if tags[screen][i] then
						      awful.tag.viewonly(tags[screen][i])
						   end
						end),
				      awful.key({ modkey, "Control" }, "#" .. i + 9,
						function ()
						   local screen = mouse.screen
						   if tags[screen][i] then
						      awful.tag.viewtoggle(tags[screen][i])
						   end
						end),
				      awful.key({ modkey, "Shift" }, "#" .. i + 9,
						function ()
						   if client.focus and tags[client.focus.screen][i] then
						      awful.client.movetotag(tags[client.focus.screen][i])
						   end
						end),
				      awful.key({ modkey, "Control", "Shift" }, "#" .. i + 9,
						function ()
						   if client.focus and tags[client.focus.screen][i] then
						      awful.client.toggletag(tags[client.focus.screen][i])
						   end
						end))
end

clientbuttons = awful.util.table.join(
   awful.button({ }, 1, function (c) client.focus = c; c:raise() end),
   awful.button({ modkey }, 1, awful.mouse.client.move),
   awful.button({ modkey }, 3, awful.mouse.client.resize))

-- Set keys
root.keys(globalkeys)
-- }}}

-- {{{ Rules
awful.rules.rules = {
   -- All clients will match this rule.
   { rule = { },
     properties = { border_width = beautiful.border_width,
		    border_color = beautiful.border_normal,
		    focus = true,
		    keys = clientkeys,
		    buttons = clientbuttons } },
   { rule = { class = "MPlayer" },
     properties = { floating = true } },
   { rule = { class = "pinentry" },
     properties = { floating = true } },
   { rule = { class = "gimp" },
     properties = { floating = true } },
   -- Set Firefox to always map on tags number 2 of screen 1.
   -- { rule = { class = "Firefox" },
   --   properties = { tag = tags[1][2] } },
}
-- }}}

-- {{{ Signals
-- Signal function to execute when a new client appears.
client.add_signal("manage", function (c, startup)
			       -- Add a titlebar
			       -- awful.titlebar.add(c, { modkey = modkey })
			       
			       -- Enable sloppy focus
			       c:add_signal("mouse::enter", function(c)
							       if awful.layout.get(c.screen) ~= awful.layout.suit.magnifier
							       and awful.client.focus.filter(c) then
							       client.focus = c
							    end
							 end)
			       
			       if not startup then
				  -- Set the windows at the slave,
				  -- i.e. put it at the end of others instead of setting it master.
				  -- awful.client.setslave(c)

				  -- Put windows in a smart way, only if they does not set an initial position.
				  if not c.size_hints.user_position and not c.size_hints.program_position then
				     awful.placement.no_overlap(c)
				     awful.placement.no_offscreen(c)
				  end
			       end
			    end)

client.add_signal("focus", function(c) c.border_color = beautiful.border_focus end)
client.add_signal("unfocus", function(c) c.border_color = beautiful.border_normal end)
-- }}}

--run once script
function run_once(prg,arg_string,pname,screen)
   if not prg then
      do return nil end
   end

   if not pname then
      pname = prg
   end

   if not arg_string then 
      awful.util.spawn_with_shell("pgrep -f -u $USER -x '" .. pname .. "' || (" .. prg .. ")",screen)
   else
      awful.util.spawn_with_shell("pgrep -f -u $USER -x '" .. pname .. "' || (" .. prg .. " " .. arg_string .. ")",screen)
   end
end

run_once("chromium-browser",nil,nil)
run_once("xchat",nil,nil)
run_once("wicd-client",nil,"/usr/bin/python -O /usr/share/wicd/gtk/wicd-client.py")
run_once("/home/ajay/projects/awesome/xmodmap.sh")
run_once("emacs --daemon")
run_once("guake")
run_once("xscreensaver -no-splash &")