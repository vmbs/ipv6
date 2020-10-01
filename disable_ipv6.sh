#!/bin/bash
#============================================================================#
# DisableIPv6 on RH-6/7 CentOS-6/7
# Author:  vasile@vmonline.net

touch /root/disable_ipv6.log
prep_log=/root/disable_ipv6.log

check_root_privileges () {
    #must run as root
    if [[ $(whoami) == 'root' ]] || [[ $(whoami) == 'sysops' ]] ; then
        # Running as root or sysops. All good
        echo -n ' '
    else
        echo -e "You don't have privileges... \nRun the script as root or sysops."
        exit 0
    fi
    echo
}

determine_os () {
    echo "---------------------------------------" | tee -a $prep_log
    echo "         CHECKING SERVER DETAILS       " | tee -a $prep_log
    echo "---------------------------------------" | tee -a $prep_log
    # Variable initialization
    SYSTEM_IS_OLD="false"
    SYSTEM_IS_NEW="false"
    # Un-built systems don't have the approvelist file in place # CORRECTION # Using lsb-release instead #
    # if [ -f /etc/redhat-release ]
    # Show the release on stdout
    cat /etc/redhat-release
    # Figure out if it's a RHEL5 or RHEL6/CENTOS6
    grep -q ' 4 \| 4\.' /etc/redhat-release
    if   [[ $? == 0 ]] ; then
        echo 'OS maj ver: 4' | tee -a $prep_log
        SYSTEM_IS_OLD="true"
        OS_VERSION="4"
    else
        grep -q ' 5\.' /etc/redhat-release
        if   [[ $? == 0 ]] ; then
            echo "OS maj ver: 5" | tee -a $prep_log
            SYSTEM_IS_OLD="true"
            OS_VERSION="5"
        else
            grep -q ' 6\.' /etc/redhat-release
            if   [[ $? == 0 ]] ; then
                 echo "OS maj ver: 6" | tee -a $prep_log
                 OS_VERSION="6"


                 # The script has to know if the server is old or new in order to know what to do.
                 # There are old AND new servers built on RHEL6, so to solve this problem without user input:
                 # If the -n attribute was not used when running the script, then consider this as the old server.
                 # Why? Because the -n attribute has to be used on old servers and at the same time, it is never used on a new server.
                 if [ -z ${NEW_SYSTEM_IP+x} ] ; then
                     SYSTEM_IS_NEW="true"
                 else
                     SYSTEM_IS_OLD="true"
                 fi
            else
                 grep -q ' 7\.' /etc/redhat-release
                 if   [[ $? == 0 ]] ; then
                      echo "OS maj ver: 7" | tee -a $prep_log
                      SYSTEM_IS_NEW="true"
                      OS_VERSION="7"
                 else
                      echo "Could not determine OS version" | tee -a $prep_log
                      return 1
                fi
            fi
        fi
    fi
}

remove_ipv6_hosts () {
  echo "---------------------------------------" | tee -a $prep_log
  echo "     REMOVE IPV6 from HOSTS            " | tee -a $prep_log
  echo "---------------------------------------" | tee -a $prep_log
  cp -p /etc/hosts /etc/hosts.disableipv6
  sed -i 's/^[[:space:]]*::/#::/' /etc/hosts
  }

disable_ipv6 () {
if [[ "$OS_VERSION" == '7' ]] ; then
    echo -n 'Disable IPV6... '
    if grep -xq "^net.ipv6.conf.all.disable_ipv6 = 1$" /etc/sysctl.conf ; then
      echo "IPV6 already disbaled" >> $prep_log
       else
       echo " Disabling IPV6 this may take while.."
         touch /etc/sysctl.d/ipv6.conf
         echo "# To disable for all interfaces" >> /etc/sysctl.d/ipv6.conf
         echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.d/ipv6.conf
         sysctl -p /etc/sysctl.d/ipv6.conf
         dracut -f
       fi
    if  [[ $? == 0 ]] ; then
        echo 'ok'
    else
        echo 'disabling Ipv6 failed'
    fi
fi
echo | tee -a $prep_log

if [[ "$OS_VERSION" == '6' ]] ; then
    echo -n 'Disable IPV6... '
    if grep -xq "^net.ipv6.conf.all.disable_ipv6 = 1$" /etc/sysctl.conf ; then
      echo "IPV6 already disbaled" >> $prep_log
       else
       echo " Disabling IPV6 on RH6/CentOS this will require a reboot please scheduale with customer if server is not in maintenance already"
       touch /etc/modprobe.d/ipv6.conf
       #add following lines
       echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
       echo "net.ipv6.conf.default.disable_ipv6 = 1" >> /etc/sysctl.conf
       fi
    if  [[ $? == 0 ]] ; then
        echo 'ok'
    else
        echo 'disabling Ipv6 failed'
    fi
 fi
}
check_root_privileges;
determine_os ;
disable_ipv6;
remove_ipv6_hosts;
