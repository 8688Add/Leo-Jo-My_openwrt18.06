module("luci.controller.openclash", package.seeall)

function index()
	if not nixio.fs.access("/etc/config/openclash") then
		return
	end


	entry({"admin", "services", "openclash"},alias("admin", "services", "openclash", "client"), _("OpenClash"), 50).dependent = true
	entry({"admin", "services", "openclash", "client"},form("openclash/client"),_("Overview"), 20).leaf = true
	entry({"admin", "services", "openclash", "status"},call("action_status")).leaf=true
	entry({"admin", "services", "openclash", "state"},call("action_state")).leaf=true
	entry({"admin", "services", "openclash", "startlog"},call("action_start")).leaf=true
	entry({"admin", "services", "openclash", "currentversion"},call("action_currentversion"))
	entry({"admin", "services", "openclash", "lastversion"},call("action_lastversion"))
	entry({"admin", "services", "openclash", "settings"},cbi("openclash/settings"),_("Takeover Settings"), 30).leaf = true
	entry({"admin", "services", "openclash", "config"},form("openclash/config"),_("Server Config"), 40).leaf = true
	entry({"admin", "services", "openclash", "log"},form("openclash/log"),_("Logs"), 50).leaf = true

	
end


local function is_running()
	return luci.sys.call("pidof clash >/dev/null") == 0
end

local function is_web()
	return luci.sys.call("pidof clash >/dev/null") == 0
end

local function is_watchdog()
	return luci.sys.exec("ps |grep openclash_watchdog.sh |grep -v grep 2>/dev/null")
end

local function config_check()
  local yaml = luci.sys.call("ls -l /etc/openclash/config.yaml >/dev/null 2>&1")
  local nameserver,proxy,group,rule
  if (yaml == 0) then
     nameserver = luci.sys.call("egrep '^ {0,}nameserver:' /etc/openclash/config.yaml >/dev/null 2>&1")
     proxy = luci.sys.call("egrep '^ {0,}Proxy:' /etc/openclash/config.yaml >/dev/null 2>&1")
     group = luci.sys.call("egrep '^ {0,}Proxy Group:' /etc/openclash/config.yaml >/dev/null 2>&1")
     rule = luci.sys.call("egrep '^ {0,}Rule:' /etc/openclash/config.yaml >/dev/null 2>&1")
  else
     local yml = luci.sys.call("ls -l /etc/openclash/config.yml >/dev/null 2>&1")
     if (yml == 0) then
        nameserver = luci.sys.call("egrep '^ {0,}nameserver:' /etc/openclash/config.yml >/dev/null 2>&1")
        proxy = luci.sys.call("egrep '^ {0,}Proxy:' /etc/openclash/config.yml >/dev/null 2>&1")
        group = luci.sys.call("egrep '^ {0,}Proxy Group:' /etc/openclash/config.yml >/dev/null 2>&1")
        rule = luci.sys.call("egrep '^ {0,}Rule:' /etc/openclash/config.yml >/dev/null 2>&1")
     end
  end
  if (yaml == 0) or (yml == 0) then
     if (nameserver == 0) then
        nameserver = ""
     else
        nameserver = " - DNS服务器"
     end
     if (proxy == 0) then
        proxy = ""
     else
        proxy = " - 代理服务器"
     end
     if (group == 0) then
        group = ""
     else
        group = " - 策略组"
     end
     if (rule == 0) then
        rule = ""
     else
        rule = " - 规则"
     end
	   return nameserver..proxy..group..rule
	elseif (yaml ~= 0) and (yml ~= 0) then
	   return "1"
	end
end

local function cn_port()
	return luci.sys.exec("uci get openclash.config.cn_port 2>/dev/null")
end

local function mode()
	return luci.sys.exec("uci get openclash.config.en_mode 2>/dev/null")
end

local function config()
   local config_update = luci.sys.exec("ls -l --full-time /etc/openclash/config.bak 2>/dev/null |awk '{print $6,$7;}'")
   if (config_update ~= "") then
      return config_update
   else
      local yaml = luci.sys.call("ls -l /etc/openclash/config.yaml >/dev/null 2>&1")
      if (yaml == 0) then
         return "0"
      else
         local yml = luci.sys.call("ls -l /etc/openclash/config.yml >/dev/null 2>&1")
         if (yml == 0) then
            return "0"
         else
            return "1"
         end
      end
   end
end

local function ipdb()
	return luci.sys.exec("ls -l --full-time /etc/openclash/Country.mmdb 2>/dev/null |awk '{print $6,$7;}'")
end

local function lhie1()
	return luci.sys.exec("ls -l --full-time /etc/openclash/lhie1.yaml 2>/dev/null |awk '{print $6,$7;}'")
end

local function ConnersHua()
	return luci.sys.exec("ls -l --full-time /etc/openclash/ConnersHua.yaml 2>/dev/null |awk '{print $6,$7;}'")
end

local function ConnersHua_return()
	return luci.sys.exec("ls -l --full-time /etc/openclash/ConnersHua_return.yaml 2>/dev/null |awk '{print $6,$7;}'")
end

local function daip()
	return luci.sys.exec("uci get network.lan.ipaddr")
end

local function dase()
	return luci.sys.exec("uci get openclash.config.dashboard_password 2>/dev/null")
end

local function check_lastversion()
  luci.sys.exec("sh /usr/share/openclash/clash_version.sh 2>/dev/null")
	return luci.sys.exec("sh /usr/share/openclash/openclash_version.sh && sed -n '/^https:/,$p' /tmp/openclash_last_version 2>/dev/null")
end

local function check_currentversion()
	return luci.sys.exec("sed -n '/^data:image/,$p' /etc/openclash/openclash_version 2>/dev/null")
end

local function startlog()
	return luci.sys.exec("sed -n '$p' /tmp/openclash_start.log 2>/dev/null")
end

function action_status()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
	  clash = is_running(),
		watchdog = is_watchdog(),
		daip = daip(),
		dase = dase(),
		web = is_web(),
		cn_port = cn_port(),
		mode = mode();
	})
end
function action_state()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
		config_check = config_check(),
		config = config(),
		lhie1 = lhie1(),
		ConnersHua = ConnersHua(),
		ConnersHua_return = ConnersHua_return(),
		ipdb = ipdb();
	})
end

function action_lastversion()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
			lastversion = check_lastversion();
	})
end

function action_currentversion()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
			currentversion = check_currentversion();
	})
end

function action_start()
	luci.http.prepare_content("application/json")
	luci.http.write_json({
			startlog = startlog();
	})
end
