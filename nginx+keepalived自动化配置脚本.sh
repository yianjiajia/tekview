#!/bin/sh
DIR1=/usr/src
DIR2=/usr/local
     
cat << EOF
++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
++++Welcome to use Linux installed a key LVS+KEEPALIVED shells scripts
+++++++++++++++++++++*************************++++++++++++++++++++++++
EOF
     
if
[ $UID -ne 0 ];then
     
echo “This script must use root user ,please exit……”
sleep 2
exit 0
     
fi
     
download ()
{
cd $DIR1 && wget -c http://www.linuxvirtualserver.org/software/kernel-2.6/ipvsadm-1.24.tar.gz http://www.keepalived.org/software/keepalived-1.1.15.tar.gz
     
if
[ $? = 0 ];then
     
echo "Download LVS Code is OK!"
else
echo "Download LVS Code is failed,Please check!"
exit 1
fi
}
     
ipvsadm_install ()
{
     
ln -s $DIR1/kernels/2.6.* $DIR1/linux
     
cd $DIR1 && tar xzvf ipvsadm-1.24.tar.gz &&cd ipvsadm-1.24 && make && make install
if
[ $? -eq 0 ];then
echo "Install ipvsadm success,please waiting install keepalived ..............."
else
echo "Install ipvsadm failed ,please check !"
exit 1
fi
}
     
keepalived_install ()
{
cd $DIR1 && tar -xzvf keepalived-1.1.15.tar.gz &&cd keepalived-1.1.15 && ./configure && make && make install
if
[ $? -eq 0 ];then
echo "Install keepalived success,please waiting configure keepalived ..............."
else
echo "Install keepalived failed ,please check install version !"
exit 1
fi
}
     
######如果以上软件包编译报错的话，请检查相关的版本跟系统版本之间的关系，然后手动下载安装.
     
keepalived_config ()
{
cp $DIR2/etc/rc.d/init.d/keepalived /etc/rc.d/init.d/ && cp $DIR2/etc/sysconfig/keepalived /etc/sysconfig/ && mkdir -p /etc/keepalived &&cp $DIR2/etc/keepalived/keepalived.conf /etc/keepalived/ && cp $DIR2/sbin/keepalived /usr/sbin/
if
[ $? -eq 0 ];then
     
echo "Keepalived system server config success!"
else
echo "Keepalived system server config failed ,please check keepalived!"
exit 1
fi
     
}
     
PS3="Please select Install Linux Packages:"
     
select option in download ipvsadm_install keepalived_install keepalived_config
     
do
     
$option
     
done
以上脚本分别在lvs-master和lvs-backup上执行安装。
     
三、配置keepalived.conf：内容如下是lvs-master配置
也可以参考配置：http://chinaapp.sinaapp.com/download/keepalived.conf 可以直接打开
     
! Configuration File for keepalived
     
global_defs {
   notification_email {
      wgkgood@163.com
   }
   notification_email_from wgkgood@163.com
   smtp_server 127.0.0.1
   smtp_connect_timeout 30
   router_id LVS_DEVEL
}
     
# VIP1
vrrp_instance VI_1 {
    state MASTER
    interface eth0
    lvs_sync_daemon_inteface eth0
    virtual_router_id 51
    priority 100
    advert_int 5
    authentication {
        auth_type PASS
        auth_pass 1111
    }
    virtual_ipaddress {
        192.168.2.100
    }
}
#REAL_SERVER_1
virtual_server 192.168.2.100 80 {
    delay_loop 6 
    lb_algo wlc 
    lb_kind DR
    persistence_timeout 60 
    protocol TCP      
     
    real_server 192.168.2.79 80 {
        weight 100     
        TCP_CHECK {
        connect_timeout 10
        nb_get_retry 3
        delay_before_retry 3
        connect_port 80
        }
}
#REAL_SERVER_2
    real_server 192.168.2.80 80 {
        weight 100
        TCP_CHECK {
        connect_timeout 10
        nb_get_retry 3
        delay_before_retry 3
        connect_port 80
           
        }
    }
}
注意***Lvs-backup端同样配置，只需要更改state MASTER为state BACKUP，修改priority 100为priority 90即可。
     
四、分别在web1、web2上配置好apache，然后分别执行如下脚本：
     
如下的VIP1指的是lvs-dr-vip地址，及对外提供访问的虚拟ip：
#!/bin/sh
     
PS3="Please Choose whether or not to start a realserver VIP1 configuration:"
     
select i in "start" "stop"
     
do
case "$i" in
     
start)
     
read -p "Please enter the virtual server IP address:" VIP1
ifconfig lo:0 $VIP1 netmask 255.255.255.255 broadcast $VIP1
/sbin/route add -host $VIP1 dev lo:0
echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce
sysctl -p >/dev/null 2>&1
echo "RealServer Start OK"
exit 0
;;
     
stop)
ifconfig lo:0 down
route del $VIP1 >/dev/null 2>&1
echo "0" >/proc/sys/net/ipv4/conf/lo/arp_ignore
echo "0" >/proc/sys/net/ipv4/conf/lo/arp_announce
echo "0" >/proc/sys/net/ipv4/conf/all/arp_ignore
echo "0" >/proc/sys/net/ipv4/conf/all/arp_announce
echo "RealServer Stoped"
exit 1
;;
*)
echo "Usage: $0 {start|stop}"
exit 2
esac
done
脚本会提示是否启动，按1即启动，然后输入vip地址 192.168.2.100 ，用ifconfig你会看到：lo:0的ip即表示配置ip成功。
lo:0      Link encap:Local Loopback
          inet addr:192.168.2.100 Mask:255.255.255.255
          UP LOOPBACK RUNNING MTU:16436 Metric:1
     
最后启动lvs-master、lvs-backup上面的keepalived服务即可