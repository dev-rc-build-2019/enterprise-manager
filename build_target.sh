#!/bin/bash
#
#*************************
# Name: build_target.sh
#*************************
# 
######################
# Initialize variables
######################
stage_dir=/tmp
#
. $stage_dir/set_env.sh
#
credname=<value>
fname=`hostname`.us.lmco.com
hname=`hostname`
uhost=`echo ${hname} | gr [:lower:] [:upper:]`
###############
# clear screen
###############
clear
##############
# get sid
##############
get_sid()
{
shouldloop=true;
while $shouldloop
do
echo "Enter the SID (not case sensitive): "
read orasid
##################
# input validation
##################
if [[ ( -z $orasid ) || ( ${#oradis} -ne 8 ) ]]
then
  echo "No SID was entered or length is not 8 characters"
  shouldloop=true;
else
  shouldloop=false;
  usid=`echo ${orasid} | tr [:lower:] [:upper:]`
  lsnrbase=`echo ${orasid} | cut -c 3-8`
  lsnrl=listener_${lsnrbase}
  lsnr=`echo ${lsnrl} | tr [:lower:] [:upper:]`
  echo "Listener Name: ${lsnr}"
  echo "orasid/SID: ${orasid} / ${usid}"
fi
done
}
############
# get password
############
get_dbsnmpwd()
{
shouldloop=true;
while $shouldloop; do
echo " "
echo "Enter the dbsnmp account password: "
read dbsnmpwd
shouldloop=false:
############
# input validation
############
if [[ ( -z $dbsnmpwd ) || ( ${#dbsnmpwd} -lt 8 ) ]]
then
  echo "No password was entered or length is not 8 or more characters"
  shouldloop=true;
fi
done
}
###############
# get port
###############
get_port()
{
shouldloop=true;
while $shouldloop; do
echo " "
echo "Enter the listener port #: "
read portnum
if [ ${#portnum} -ne 4 ]
then
  echo "Port must be 4 numbers"
  shouldloop=true;
else
################
# verify port is numeric
################
  case $portnum in
    ''|*[!0-9]*) echo "No port was entered or is not numeric"
                 shouldloop=true;;
    *) shouldloop=false;
       break;;
  esac
fi
done
}
############
# build emcli commands and run
############
run_oem()
{
#############
# logon acct and sync
#############
echo "Enter sysman password"
emcli login -username=<acct>
emcli syncc
#############
# build and run
#############
emcli submit_add_host -host_name=$fname -platform="Linux x86-64" -installation_base_directory=<agent location> -credential_name=$credname
##############
# add database target
##############
emcli add_target -name="$orasid" -type="oracle_database" -host="$fname" -credentials="UserName:dbsnmp\;password:$dbsnmpwd\;Role:Normal" -properties="SID:$orasid\;Port:$portnum\;OracleHome:$orahome\;MachineName:$fname"
##############
# add listener target
##############
emcli add_target -name="$lsnr" -type="oracle_listener" -host="$fname" -properties="LsnrName=$lsnr||ListenerOraDir=$orahome/network/admin" -properties="Port=$port||OracleHome=$orahome||Machine=$fname"
##############
# target properties
##############
emcli set_target_property_value -property_records="$usid-$uhost:oracle_database:LifeCycle Status:$env_type"
emcli set_target_property_value -property_records="$usid-$uhost:oracle_database:Contact:$vcontact"
emcli set_target_property_value -property_records="$usid-$uhost:oracle_database:Location:$datacenter"
emcli set_target_property_value -property_records="$usid-$uhost:oracle_database:Cost Center:$vccenter"
emcli set_target_property_value -property_records="$usid-$uhost:oracle_database:AppDBA:$appdba"
emcli set_target_property_value -property_records="$usid-$uhost:oracle_database:Line of Business:$ba"
###############
# logout 
###############
emcli logout
}
################
# set field attributes
################
set_attr()
{
################
# appdba
################
shouldloop=true;
while $shouldloop; do
echo " "
echo "Enter the application dba (email format: local-part@domain): "
read appdba
shouldloop=false;
if [ -z $appdba ]
then
  echo "No application dba was entered"
  shouldloop=true;
fi
done
################
# Contact (vcontact)
################
shouldloop=true;
while $shouldloop; do
echo " "
echo "Enter the contact (hint: use Subscription Name): "
read vcontact
shouldloop=false;
if [ -z "$vcontact" ]
then
  echo "No Contact was entered"
  shouldloop=true;
fi
done
################
# Cost Center (vccenter)
################
echo " "
echo "Select the Cost Center: "
select vcc in "XL1" "XL2"
do
  case $vcc in 
    XL1 ) vccenter=$vcc; break;;
    XL2 ) vccenter=$vcc; break;;
       *) echo "Default of XL2 will be chosen: ";
          vccenter="XL2";
          break;;
  esac  
done
################
# LifeCycle Status (env_type)
################
echo " "
echo "Select the LifeCycle Status: "
select env in "Dev" "Test" "Prod"
do
  case $env in 
     Dev ) env_type=$env; break;;
    Test ) env_type=$env; break;;
    Prod ) env_type=$env; break;;
        *) echo "No LifeCycle was chosen"; break;;
  esac  
done
################
# Line of Business (ba)
################
echo " "
echo "Select the Business Area: "
select rlb in "New" "Old" "Same"
do
  case $rlb in 
     New ) ba=$rlb; break;;
     Old ) ba=$rlb; break;;
    Same ) ba=$rlb; break;;
        *) echo "No Business Area was chosen"; break;;
  esac  
done
################
# Location (datacenter)
################
echo " "
echo "Select the Data Center: "
select dc in "Boston" "Phoenix" "Paris"
do
  case $dc in 
    Boston )  datacenter=$dc; break;;
    Phoenix ) datacenter=$dc; break;;
    Paris ) datacenter=$dc; break;;
         *) echo "No data center was chosen: "; break;;
  esac  
done
}
################
# Main
################
get_sid
get_dbsnmpwd
get_port
set_attr
################
# present variables
################
clear
echo "Fields"
echo "======================="
echo "App DBA:          " $appdba
echo "Contact:          " $vcontact
echo "Cost Center:      " $vccenter
echo "Lifecycle Status: " $env_type
echo "Line of Business: " $ba
echo "Location:         " $datacenter
###############
# verify values
###############
echo " "
echo "Verify if values are correct - Continue? y or n"
while read ans
do
  case $ans in 
    [Yy]* ) clear:
            run_oem
            break;;
    [Nn]* ) echo "Stop build"
            break;;
        * ) echo "Enter answer y or n";;
  esac
done
