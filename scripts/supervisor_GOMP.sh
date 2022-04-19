#!/bin/bash
[[ $(id -u) != 0 ]] && echo -e "請在Root用戶下運行安裝該腳本" && exit 1

cmd="apt-get"
if [[ $(command -v apt-get) || $(command -v yum) ]] && [[ $(command -v systemctl) ]]; then
    if [[ $(command -v yum) ]]; then
        cmd="yum"
    fi
else
    echo "這個安裝腳本不支持你的系統" && exit 1
fi


install(){

	  $cmd update -y
    if [[ $cmd == "apt-get" ]]; then
        $cmd install -y lrzsz git zip unzip curl wget supervisor
        service supervisor restart
    else
        $cmd install -y epel-release
        $cmd update -y
        $cmd install -y lrzsz git zip unzip curl wget supervisor
        systemctl enable supervisord
        service supervisord restart
    fi
    
    
    if [ -d "/root/go_miner" ]; then
        rm -rf /root/go_miner
    fi

    $cmd update -y
    mkdir /root/go_miner
    wget https://raw.githubusercontent.com/minerproxys/AntiGoMinerProxyV1_3_9/main/others/cert.tar.gz -O /root/go_miner/cert.tar.gz --no-check-certificate
    tar -zxvf /root/go_miner/cert.tar.gz -C /root/go_miner
    wget https://github.com/minerproxys/AntiGoMinerProxyV1_3_9/releases/download/1.3.9/GoMinerProxy_v1.3.9_linux_amd64.tar.gz -O /root/GoMinerProxy_v1.3.9_linux_amd64.tar.gz --no-check-certificate
    tar -zxvf /root/GoMinerProxy_v1.3.9_linux_amd64.tar.gz -C /root/go_miner
    chmod 777 /root/go_miner/PatchGompV139
    cd /root/go_miner
    ./PatchGompV139
    chmod 777 /root/go_miner/GoMinerProxy

    
    sleep 0.2s
    
    
    echo "GoMinerProxy V1.3.9已经破解 安裝到/root/go_miner"
    
    
    start_write_config
    supervisorctl reload
    sleep 3s
    
    echo "----------------------------------------------------------------"    
    echo "GoMinerProxy 已经加入守护，崩溃、开机，都能自动重启"
    echo "查看守护状态： supervisorctl status  GoMinerProxy"
    echo "重启GOMP程序： supervisorctl restart GoMinerProxy"
    echo "启动GOMP程序： supervisorctl start    GoMinerProxy"
    echo "关闭GOMP程序： supervisorctl stop    GoMinerProxy"
    echo "---------------------记住上述命令便于操作-----------------------"
    echo "----------------------------------------------------------------"
    

    echo ""

    echo "1.请记录以下端口、密码等数据。然后浏览器打开 ip:端口 ，登录网页配置"
    echo "----------------------------------------------------------------"
    cd /root/go_miner
    cat "/root/go_miner/pwd.txt"
    echo "----------------------------------------------------------------"
    echo "忘记端口、密码，可运行此命令查看：  cat /root/go_miner/pwd.txt  "
    supervisorctl status GoMinerProxy
}

start_write_config() {
	  installPath="/root/go_miner"
    echo
    echo "开启守护"
    echo
    chmod a+x $installPath/GoMinerProxy
    if [ -d "/etc/supervisor/conf/" ]; then
        rm /etc/supervisor/conf/GoMinerProxy.conf -f
        echo "[program:GoMinerProxy]" >>/etc/supervisor/conf/GoMinerProxy.conf
        echo "command=${installPath}/GoMinerProxy" >>/etc/supervisor/conf/GoMinerProxy.conf
        echo "directory=${installPath}/" >>/etc/supervisor/conf/GoMinerProxy.conf
        echo "autostart=true" >>/etc/supervisor/conf/GoMinerProxy.conf
        echo "autorestart=true" >>/etc/supervisor/conf/GoMinerProxy.conf
    elif [ -d "/etc/supervisor/conf.d/" ]; then
        rm /etc/supervisor/conf.d/MinerProxy.conf -f
        echo "[program:GoMinerProxy]" >>/etc/supervisor/conf.d/GoMinerProxy.conf
        echo "command=${installPath}/GoMinerProxy" >>/etc/supervisor/conf.d/GoMinerProxy.conf
        echo "directory=${installPath}/" >>/etc/supervisor/conf.d/GoMinerProxy.conf
        echo "autostart=true" >>/etc/supervisor/conf.d/GoMinerProxy.conf
        echo "autorestart=true" >>/etc/supervisor/conf.d/GoMinerProxy.conf
    elif [ -d "/etc/supervisord.d/" ]; then
        rm /etc/supervisord.d/MinerProxy.ini -f
        echo "[program:GoMinerProxy]" >>/etc/supervisord.d/GoMinerProxy.ini
        echo "command=${installPath}/GoMinerProxy" >>/etc/supervisord.d/GoMinerProxy.ini
        echo "directory=${installPath}/" >>/etc/supervisord.d/GoMinerProxy.ini
        echo "autostart=true" >>/etc/supervisord.d/GoMinerProxy.ini
        echo "autorestart=true" >>/etc/supervisord.d/GoMinerProxy.ini
    else
        echo
        echo "----------------------------------------------------------------"
        echo
        echo " Supervisor安装目录没了，安装失败"
        echo
        exit 1
    fi

	}


uninstall(){
    read -p "您確認您是否刪除GoMinerProxy)[yes/no]：" flag
    if [ -z $flag ];then
         echo "您未正確輸入" && exit 1
    else
	    clear
	    if [ -d "/etc/supervisor/conf/" ]; then
	        rm /etc/supervisor/conf/MinerProxy.conf -f
	    elif [ -d "/etc/supervisor/conf.d/" ]; then
	        rm /etc/supervisor/conf.d/MinerProxy.conf -f
	    elif [ -d "/etc/supervisord.d/" ]; then
	        rm /etc/supervisord.d/MinerProxy.ini -f
	    fi
	    supervisorctl reload
	    echo -e "$yellow 已关闭自启动${none}"
    fi
}



start_my(){ 
		supervisorctl  start    GoMinerProxy	
}


restart_my(){
     supervisorctl restart    GoMinerProxy	
}

check(){
	supervisorctl status  GoMinerProxy
}

stop_my(){
    supervisorctl  stop    GoMinerProxy
}


change_limit(){
    if grep -q "1000000" "/etc/profile"; then
        echo -n "您的系統連接數限制可能已修改，當前連接限制："
        ulimit -n
        exit
    fi

    cat >> /etc/sysctl.conf <<-EOF
fs.file-max = 1000000
fs.inotify.max_user_instances = 8192

net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_fin_timeout = 30
net.ipv4.tcp_tw_reuse = 1
net.ipv4.ip_local_port_range = 1024 65000
net.ipv4.tcp_max_syn_backlog = 16384
net.ipv4.tcp_max_tw_buckets = 6000
net.ipv4.route.gc_timeout = 100

net.ipv4.tcp_syn_retries = 1
net.ipv4.tcp_synack_retries = 1
net.core.somaxconn = 32768
net.core.netdev_max_backlog = 32768
net.ipv4.tcp_timestamps = 0
net.ipv4.tcp_max_orphans = 32768

# forward ipv4
# net.ipv4.ip_forward = 1
EOF

    cat >> /etc/security/limits.conf <<-EOF
*               soft    nofile          1000000
*               hard    nofile          1000000
EOF

    echo "ulimit -SHn 1000000" >> /etc/profile
    source /etc/profile

    echo "系統連接數限制已修改，手動reboot重啟下系統即可生效"
}


check_limit(){
    echo -n "您的系統當前連接限制："
    ulimit -n
}


echo "======================================================="
echo "GoMinerTool-ETHASH 一鍵腳本，脚本默认安装到/root/go_miner"
echo "                               腳本版本(Script Version)：V1.3.9"
echo "有偿破解其他版本、抽水： ＴＧ-->  https://t.me/MinerProxyHackGO"
echo "****必须自定义E池、鱼池，务必详细阅读 《使用说明.doc》 文档****"
echo ""
echo "  1、安 裝 并 破 解* (Install)"
echo "  2、卸          載  (Uninstall)"
echo "  3、查看 守护 状态* (Check)"
echo "  4、啟          動  (Start)"
echo "  5、重          啟  (Restart)"
echo "  6、停          止  (Stop)"
echo "  7、一鍵解除Linux連接數限制,需手動重啟系統生效"
echo "  8、查看當前系統連接數限制 (View the current system connection limit)"
echo "======================================================="
read -p "$(echo -e "請選擇(Choose)[1-8]：")" choose
case $choose in
    1)
        install
        ;;
    2)
        uninstall
        ;;
    3)
        check
        ;;
    4)
        start_my
        ;;
    5)
        restart_my
        ;;
    6)
        stop_my
        ;;
    7)
        change_limit
        ;;
    8)
        check_limit
        ;;
    *)
        echo "請輸入正確的數字！(Please enter the correct number!)"
        ;;
esac