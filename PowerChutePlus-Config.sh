#!/bin/sh
# 
# Copyright 1999 American Power Conversion, All Rights Reserved
#
# Description: This file is used to configure PowerChute Plus
#              for Linux.
#
# Usage:  ./Config - will configure PowerChute PLUS after
#                    installing it from an RPM archive
#
#

###################
# Global Constants
###################
# --------------------------------------------------------------------------
# Do not change definitons for TRUE and FALSE from below, or '&&' shell logic
# will fail.  TRUE=0 and FALSE!=0 is shell convention
# --------------------------------------------------------------------------
FALSE=1
TRUE=0

YES=0
NO=1
QUIT=2
INVALID=99

SMART="smart"
SIMPLE="simple"
PNP="PNP"
NORMAL="Normal"

NOT_SYM1="Bad battery"
SYM=""
NOT_SYM2="UPS on bypass"
SYM2="UPS"
NOT_SYM3=""
SYM10="TimeOutFactor = 20"
SYM11="UPS system is in maintenance bypass set by switch"
NOT_SYM4="UPS on bypass: user set via rear switch"
SYM5="Actions = LUS"
NOT_SYM5="Actions = LU"

FULL_PROD_NAME="PowerChute Plus for Unix"
PROD_HEADER="4.5.2"
INST_SCRIPT_NAME=$0
LINUX_INTEL_STRING="Linux"
OS_NAME="$LINUX_INTEL_STRING"
MONO_WARN_COLOR_STRING="WarningColor = LightGray"
MONO_ERR_COLOR_STRING="ErrorColor = LightGray"
TTY1="/dev/ttyS0"
TTY2="/dev/ttyS1"
SHUTDOWN_SEARCH_STRING="swapoff -a"
STARTUP_FILE_PATH="/etc/rc.d/init.d"
STARTUP_FILE="$STARTUP_FILE_PATH/upsd"
STARTUP_RC_PATH="/etc/rc.d"
MODEM_ALLOWED_PORT_NAMES="/dev/modem,/dev/ttyS0,/dev/ttyS1"
MODEM_PORT_NAME="/dev/modem"
SHUTDOWN_FILE="/etc/rc.d/init.d/halt"
SHUTDOWN_FILE_BACKUP="/usr/lib/powerchute/halt"
SHUTDOWN_COMMAND_STRING="if [ -r /upsoff.cmd ]     #POWERCHUTE\\
 then                      #POWERCHUTE\\
 . ./upsoff.cmd >/dev/null       #POWERCHUTE\\
 rm -f /upsoff.cmd       #POWERCHUTE\\
 fi                        #POWERCHUTE\\
 "                      


COMM_VERIFIED=$FALSE
IS_MODEM_PORT=$FALSE
IS_LOCAL_PORT=$FALSE
SKIP_PORT_VERIFICATION=$FALSE

# Variables that start uninitialized
ALLOWED_PORT_NAMES=
APC_HARDWARE_PROD=
CABLE_TYPE=
INST_HARDWARE=
INST_TTY=
MEASURE_UPS=
ROOT_USER=
RUN_COMMAND_FILES_AS_ROOT=
SEND_EMAIL_AS_ROOT=
SIGNAL_TYPE=
UI_MONO_COLOR_SCHEME=
USE_TCP=
VALID_TTY_SELECTED=
WEB_BROWSER=

#######################
# Functions used below
#######################

###########################################################################
# IsYN handles Yes No responses
###########################################################################
Echo() {
        
	tmp_name=`uname -s`
	string="$1"

	if [ "$tmp_name" = "Linux" ]
	then
		echo -e "$string"
	elif [ -r /usr/5bin/echo ]
        then
		/usr/5bin/echo "$string"
	else
		echo "$string"
	fi
}


echo_line() {
	Echo "----------------------------------------------------------------------------"
}



HitAnyKey() {
	default="Press Enter to continue"
	string=${1:-$default}
	Echo "$string \\c"
	read tmp_strike
}


beep() {
	Echo "\\c"
}

IsYN(){
    VALID_YN=$FALSE
    YN=
    rval=
    Echo "[y/n] \\c"
    read YN
    if [ -z "$YN" ]
    then
        VALID_YN=$FALSE
        rval=$INVALID
    else
        case "$YN" in
        [Yy]*)
            VALID_YN=$TRUE
            rval=$YES
            ;;
        [Nn]*)
            VALID_YN=$TRUE
            rval=$NO
            ;;
        *)
            VALID_YN=$FALSE
            rval=$INVALID
            ;;
        esac
    fi
    if [ $rval -eq $INVALID ]
    then
        beep
        Echo "Invalid Response..."
    fi
    return $rval
}


IsYNLoop() {
    rval=$INVALID
    query_string="$1"
    valid_response=$FALSE
    while [ $valid_response -eq $FALSE ]
    do
        Echo "$query_string \\c"
        IsYN
        rval=$?
        case "$rval" in
            $YES|$NO)
                valid_response=$TRUE
                ;;
        esac
    done
    return $rval
}

CheckEepromUps() {

	eeprom=$1
	dev_name=$2
	set `./ups_adjust -in -d$dev_name -c$eeprom -t$CABLE_TYPE 2>/dev/null`
	while [ ! -z "$2" ]
	do
		if [ "$1" = "FV" ]
		then
			firmware="$2"
		elif [ "$1" = "2G+" ]
		then
			if [ "$2" = "TRUE" ]
			then
				Is2g=$TRUE
			else
				Is2g=$FALSE
			fi
		elif [ "$1" = "VAL" ]
		then
			current=$2
		fi
		shift;
		shift;
	done
	if [ $Is2g -eq $TRUE ]
	then
		if [ `expr $current \> 20` -eq 1 ]
		then
			rval=$FALSE
		else
			rval=$TRUE
		fi
	else
		rval=$FALSE
	fi
	return $rval
}

CheckDipSwitches() {

	dev_name=$1
	okay_flag=$FALSE
	rval=$FALSE

	while [ $okay_flag -eq $FALSE ]
	do
		set `./ups_adjust -sn -d$dev_name -c7 -t$CABLE_TYPE 2>/dev/null`
		if [ "$2" != "NA" ]
		then
		    if [ -z "$2" ] || [ $2 -ne 0 ]
		    then
			echo_line
			beep
			Echo "Your UPS will not accept an attempt to change its eeproms."
			Echo "If your UPS has dip switches on the back panel, check that they are all in"
			Echo "'On' position.  After installation, you can set them back to their"
			Echo "original state if you wish."
			echo_line
			continue_loop_flag=$TRUE
			while [ $continue_loop_flag -eq $TRUE ]
			do
				Echo "Do you wish to Retry setting this value, or Continue on with"
				Echo "the installation? [R/C] \\c"
				read response
				if [ -z "$response" ]
				then
					beep
					Echo "Invalid response..."
				else
					case "$response" in
						[Cc]*)
							continue_loop_flag=$FALSE
							okay_flag=$TRUE
						;;
						[Rr]*)
							continue_loop_flag=$FALSE
							okay_flag=$FALSE
							Echo
						;;
						*)
							beep
							Echo "Invalid Response..."
						;;
					esac
				fi
			done	
					
		    else 
			okay_flag=$TRUE
			rval=$TRUE
		    fi
		else
		    okay_flag=$TRUE
		    rval=$TRUE
		fi
	done
	return $rval
}

# This function takes an eeprom and a device name and
# it determines the current setting of the eeprom and
# returns this value. It returns -1 on error.
GetCurrentEepromSetting() {
    eeprom=$1
    dev_name=$2
   
    ret_val="-1"
    set `./ups_adjust -in -d$dev_name -c$eeprom -t$CABLE_TYPE 2>/dev/null`
    
    while [ "$1" ]
    do
	if [ "$1" = "VAL" ]
	then
	    if [ -n "$2" ]
	    then
		ret_val="$2"
	    fi
	fi
	shift
    done 
    return $ret_val
}


# This functions takes an eeprom, a check value, and a device
# name and it determines the next valid eeprom setting value
# greater than the check value. 
GetNextEepromValueGreaterThan() {   
    eeprom=$1
    check_value=$2
    dev_name=$3
    
    ret_val=-1
    starting_val=-1
    GetCurrentEepromSetting $eeprom $dev_name
    starting_val="$?"

    if [ "$starting_val" -ne "-1" ]
    then
	done=$FALSE
        previous_val=$starting_val
	while [ $done -eq $FALSE ]
	do
	    set `./ups_adjust -sn -d$dev_name -c$eeprom -t$CABLE_TYPE 2>/dev/null`
	    if [ "$2" -eq "$starting_val" ]
	    then
		done=$TRUE
	    else
		if [ "$2" -gt "$check_value" ]
		then
		    if [ "$2" -lt "$previous_val" ]
		    then
			ret_val="$2"
		    fi
		fi
	    fi
	    previous_val="$2"
	    Echo ".\\c"
	done
    fi
    
    return $ret_val
}


CycleUntilAcceptableValue() {

	eeprom=$1
	current_value=$2
	desired_value=$3
	dev_name=$4
	okay_flag=$FALSE
	rval=$FALSE
	
	while [ $okay_flag -eq $FALSE ]
	do
		Echo ".\\c"
		set `./ups_adjust -sn -d$dev_name -c$eeprom -t$CABLE_TYPE 2>/dev/null`
		if [ "$2" -eq "$desired_value" ]
		then
			okay_flag=$TRUE
			rval=$TRUE
		elif [ "$2" -eq "$current_value" ]
		then
			#We either can't change the value, or we are back
			#where we started and our desired value never turned up
			okay_flag=$TRUE
			echo_line
			beep
			Echo "Unable to modify the value of this eeprom.  If you are unable to"
			Echo "change this value through the powerchute user interface, refer to the UPS"
			Echo "manual, or contact APC Technical Support."
			echo_line
			HitAnyKey
		fi
	done
	Echo
}

CopyOutToIn() {
   cp /tmp/temp_ini.out /tmp/temp_ini.in
}


#######################################################################
# Trap signals so we can clean up temp files
#######################################################################

trap 'Echo \\nsignal caught, Quitting.;exit' 1 2 15

# ---------------------------------------------------------------------
# ----------------------------- Start ---------------------------------
# ---------------------------------------------------------------------
cd /usr/lib/powerchute


#######################################################################
# Print Banner
#######################################################################
Echo "-----------------------------------------------------------------------"
Echo "     PowerChute Plus for Linux v$PROD_HEADER Configuration Script"
Echo "             Copyright American Power Conversion 1999"
Echo "-----------------------------------------------------------------------"
Echo

#######################################################################
# Verify root authority 
#######################################################################

    root_string=`id | grep root`

    if [ -z "$root_string" ]
    then
        ROOT_USER=$FALSE
        echo_line
        beep
        Echo "$INST_SCRIPT_NAME must be run with root privileges!"
        echo_line
        echo_line
        IsYNLoop "Do you wish to continue anyway?"
        case "$?" in
            $NO)
                exit
                ;;
        esac
    else
        ROOT_USER=$TRUE
    fi


#######################################################################
# Select an APC Hardware Product
#######################################################################

    VALID_HARDWARE_SELECTED=$FALSE 
    INST_HARDWARE=
    while [ $VALID_HARDWARE_SELECTED -eq $FALSE ]
    do
        Echo 
        Echo "                1) Matrix-UPS"
        Echo "                2) Smart-UPS"
        Echo "                3) Back-UPS"
        Echo "                4) Back-UPS Pro"
        Echo "                5) Symmetra Power Array"
        Echo "                6) Smart-UPS DP"
        Echo " "
        Echo "Which APC Hardware will $FULL_PROD_NAME be running with [?] \\c"
        read INST_HARDWARE
        case "$INST_HARDWARE" in
            1)
                VALID_HARDWARE_SELECTED=$TRUE
                APC_HARDWARE_PROD="Matrix"
                SIGNAL_TYPE=$SMART
                CABLE_TYPE=$NORMAL
                SYMSTR1=$NOT_SYM1
                SYMSTR2=$NOT_SYM2
                SYMSTR13=$NOT_SYM3
                SYMSTR14=$NOT_SYM4
                SYMSTR3=$SYM5
                
                ;;
            2)
                VALID_HARDWARE_SELECTED=$TRUE
                APC_HARDWARE_PROD="SmartUps"
                SIGNAL_TYPE=$SMART
                CABLE_TYPE=$NORMAL
                SYMSTR1=$NOT_SYM1
                SYMSTR2=$NOT_SYM2
                SYMSTR13=$NOT_SYM3
                SYMSTR14=$NOT_SYM4
                SYMSTR3=$SYM5
                ;;
            3)
                VALID_HARDWARE_SELECTED=$TRUE
                APC_HARDWARE_PROD="BackUps"
                SIGNAL_TYPE=$SIMPLE
                CABLE_TYPE=$SIMPLE
                SYMSTR1=$NOT_SYM1
                SYMSTR2=$NOT_SYM2
                SYMSTR13=$NOT_SYM3
                SYMSTR14=$NOT_SYM4
                SYMSTR3=$SYM5
                # No way to verify comm for simple sig, assume
                # OK to skip warning banner
                COMM_VERIFIED=$TRUE
                IS_MODEM_PORT=$TRUE
                ;;
            4)
                VALID_HARDWARE_SELECTED=$TRUE
                APC_HARDWARE_PROD="SmartUps"
                SIGNAL_TYPE=$SMART
                CABLE_TYPE=$PNP
                SYMSTR1=$NOT_SYM1
                SYMSTR2=$NOT_SYM2
                SYMSTR13=$NOT_SYM3
                SYMSTR14=$NOT_SYM4
                SYMSTR3=$SYM5
                ;;
            5)      
                VALID_HARDWARE_SELECTED=$TRUE
                APC_HARDWARE_PROD="Symmetra"
                SIGNAL_TYPE=$SMART
                CABLE_TYPE=$NORMAL
                SYMSTR1=$SYM1
                SYMSTR2=$SYM2
                SYMSTR13=$SYM10
                SYMSTR14=$SYM11
                SYMSTR3=$NOT_SYM5
                                ;;
            6)
                VALID_HARDWARE_SELECTED=$TRUE
                APC_HARDWARE_PROD="SmartUps"
                SIGNAL_TYPE=$SMART
                CABLE_TYPE=$NORMAL
                SYMSTR1=$NOT_SYM1
                SYMSTR2=$NOT_SYM2
                SYMSTR13=$NOT_SYM3
                SYMSTR14=$NOT_SYM4
                SYMSTR3=$SYM5
                ;;
            *)
                VALID_HARDWARE_SELECTED=$FALSE                
                beep
                Echo "Invalid Selection...."
        esac
    done


#######################################################################
# Ask about MeasureUps
#######################################################################

	if [ $SIGNAL_TYPE = $SMART ]
	then
		Echo
		echo_line
		Echo "The Measure-UPS is a device which is designed to perform environmental "
		Echo "monitoring in conjunction with $FULL_PROD_NAME"
		echo_line
	
		Echo 
		IsYNLoop "Do you currently have a Measure-UPS attached to the UPS?"
		case "$?" in
		$YES)
			MEASURE_UPS=$TRUE
			;;
		$NO)
			MEASURE_UPS=$FALSE
			;;
		esac

	else
		MEASURE_UPS=$FALSE
	fi

		
#######################################################################
# Ask about TCP/IP
#######################################################################

        Echo
        echo_line
        Echo "$FULL_PROD_NAME is able to monitor other hosts.  However, in order"
        Echo "to monitor other hosts TCP/IP must be installed. If you do not have"
        Echo "TCP/IP installed, answer 'n' to the following question."
        echo_line
        Echo
        IsYNLoop "Do you currently have TCP/IP Installed?"
        case "$?" in
        $YES)
                USE_TCP=$TRUE
                ;;
        $NO)
                USE_TCP=$FALSE
                ;;
        esac

############################################################################
# Ask about coloring schemes...
############################################################################
	Echo
	echo_line
	Echo "If you will be using the Motif version of the User Interface on a "
	Echo "monochrome monitor, using the Monochrome Coloring scheme is recommended."
    Echo
	echo_line
	Echo "		1) Use Default Color scheme"
	Echo "		2) Use Monochrome Color scheme"
	echo
	valid_color_scheme=$FALSE
	while [ $valid_color_scheme -eq $FALSE ]
	do
		Echo "Which color scheme do you wish to use [1]? \\c"
		read color_scheme
		if [ -z "$color_scheme" ] || [ "$color_scheme" = "1" ]
		then
			valid_color_scheme=$TRUE
			UI_MONO_COLOR_SCHEME=$FALSE
		else
			if [ "$color_scheme" = "2" ]
			then
				UI_MONO_COLOR_SCHEME=$TRUE
				valid_color_scheme=$TRUE
			else
				valid_color_scheme=$FALSE
			fi
		fi
	done


#######################################################################
# Select communications port
#######################################################################

        Echo
        echo_line
        Echo "$FULL_PROD_NAME requires complete control of the serial port. No"
        Echo "processes, including gettys, are allowed to be accessing the port."
        Echo "Therefore, the serial port you select must NOT be enabled for logins. To"
        Echo "ensure that $FULL_PROD_NAME has control of the serial port, make"
        Echo "sure that it is not enabled for logins.  To disable the port for logins"
        Echo "consult the $FULL_PROD_NAME manual."
        echo_line
        Echo
		VALID_TTY_SELECTED=$FALSE
		TTY_NUM=
		while [ $VALID_TTY_SELECTED -eq $FALSE ]
		do
			Echo 
			Echo "		1) $TTY1"
			Echo "		2) $TTY2"
			Echo "		3) Other"
			Echo 
			Echo "Which serial device will be dedicated to $FULL_PROD_NAME [?] \\c"
			read TTY_NUM
				case "$TTY_NUM" in
				1)
				    ALLOWED_PORT_NAMES="$TTY1,$TTY2"
					INST_TTY=$TTY1
					VALID_TTY_SELECTED=$TRUE
					;;
				2)
				    ALLOWED_PORT_NAMES="$TTY1,$TTY2"
					INST_TTY=$TTY2
					VALID_TTY_SELECTED=$TRUE
					;;
				3)
					VALID_TEMP_TTY=$FALSE
					while [ $VALID_TEMP_TTY -eq $FALSE ]
					do
						Echo "Enter full path name of a serial device \\c"
						read TEMP_TTY
						if [ -z "$TEMP_TTY" ]
						then
							Echo "Invalid Selection"
						else
							VALID_TEMP_TTY=$TRUE
							INST_TTY=$TEMP_TTY
							ALLOWED_PORT_NAMES="$TTY1,$TTY2,$INST_TTY"
						fi
					done
					VALID_TTY_SELECTED=$TRUE
					;;
                *)
				    beep
				    Echo "Invalid Selection..."
                    ;;    
    		    esac
		done

#######################################################################
# Print cable type
#######################################################################
	
		Echo
		echo_line
		case "$SIGNAL_TYPE" in
		$SMART)
		    case "$CABLE_TYPE" in
			$NORMAL)
			    if [ "$APC_HARDWARE_PROD" = "Symmetra" ]
			    then
				Echo "You should have the cable, #940-1524C attached to $INST_TTY"
			    else
				Echo "You should have the black cable, #940-0024C attached to $INST_TTY"
			    fi
			    ;;
			$PNP)
			    Echo "You should have the grey cable, #940-0095A attached to $INST_TTY"
			    ;;
		        esac
			;;
		$SIMPLE)
			Echo "You should have the grey cable, #940-0023A attached to $INST_TTY"
			;;
		esac
		Echo "Please verify."
		echo_line

######################################################################
# Determine if user wants to run command files as root
######################################################################

    Echo
    echo_line
    Echo "Command files may be executed with root privileges or with the"
    Echo "privileges you assign to the pwrchute account (allowing you to"
    Echo "customize command file execution according to your system"
    Echo "requirements)."
    echo_line
	
	Echo 
	IsYNLoop "Do you want to execute command files as root?"
	case "$?" in
	$YES)
		RUN_COMMAND_FILES_AS_ROOT=$TRUE
		;;
	$NO)
		RUN_COMMAND_FILES_AS_ROOT=$FALSE
		;;
	esac

######################################################################
# Determine if user wants to send email as root 
######################################################################

    Echo
    echo_line
    Echo "E-mail may be sent with root privileges or with the privileges you"
    Echo "assign to the pwrchute account."
    echo_line
	
	Echo 
	IsYNLoop "Do you want to send e-mail as root?"
	case "$?" in
	$YES)
		SEND_EMAIL_AS_ROOT=$TRUE
		;;
	$NO)
		SEND_EMAIL_AS_ROOT=$FALSE
		;;
	esac


#######################################################################
# Print install info for customer verification
#######################################################################

    Echo 
    echo_line
    Echo "PRODUCT                   : $FULL_PROD_NAME"
	Echo "DEDICATED TTY             : $INST_TTY"
    case "$INST_HARDWARE" in
        1) UPS_TYPE="Matrix-UPS"
        ;;
        2) UPS_TYPE="Smart-UPS"
        ;;
        3) UPS_TYPE="Back-UPS"
        ;;
	    4) UPS_TYPE="Back-UPS Pro"
	    ;;
        5) UPS_TYPE="Symmetra Power Array"
        ;;
        6) UPS_TYPE="Smart-UPS DP"
        ;;
    esac
    Echo "UPS TYPE                  : $UPS_TYPE"
	if [ $SIGNAL_TYPE = $SMART ] && [ $MEASURE_UPS -eq $TRUE ]
	then
		Echo "Measure-UPS INSTALLED     : TRUE"
	fi
	if [ $SIGNAL_TYPE = $SMART ] && [ $MEASURE_UPS -eq $FALSE ]
	then
		Echo "Measure-UPS INSTALLED     : FALSE"
	fi

    if [ $ROOT_USER -eq $TRUE ]
    then
	    Echo "INSTALLING AS ROOT        : TRUE"
    else
	    Echo "INSTALLING AS ROOT        : FALSE"
    fi  

    if [ $USE_TCP -eq $TRUE ]
    then
        Echo "TCP/IP Installed          : TRUE"
    else
        Echo "TCP/IP Installed          : FALSE"
    fi

	if [ $RUN_COMMAND_FILES_AS_ROOT -eq $TRUE ] 
	then
      	Echo "RUN COMMAND FILES AS ROOT : TRUE"
    else
       	Echo "RUN COMMAND FILES AS ROOT : FALSE"
	fi

	if [ $SEND_EMAIL_AS_ROOT -eq $TRUE ] 
	then
       	Echo "SEND EMAIL AS ROOT        : TRUE"
	else
       	Echo "SEND EMAIL AS ROOT        : FALSE"
	fi

    echo_line
    Echo

#######################################################################
# Allow customer to verify or quit
#######################################################################

IsYNLoop "Are the above selections correct?"
case "$?" in
	$NO)
		Echo 
		Echo "Please rerun the $INST_SCRIPT_NAME script"
		Echo "No actions taken."
		Echo 
		exit
		;;
esac

#############################################################################
# Check for binary compatibility
#############################################################################
    Echo
    Echo "Checking for binary compatibility..."
    rm -f machine_def
    ./machine_id 2>&1
    if [ ! -r machine_def ]
    then
    	echo_line
	    Echo "INSTALL FAILURE: There does not appear to be binary compatibilty between"
	    Echo "installed product and this machine"
	    echo_line
	    Echo
	    exit
    else
	    Echo "binary compatibility VERIFIED"
	    Echo
    fi


#############################################################################
# Verify that chosen serial device is a valid tty 
#############################################################################
	VALID_TTY=$FALSE
	./ttycheck "$INST_TTY"
	case "$?" in
		1)
			VALID_TTY=$TRUE
			Echo "$INST_TTY verified as a valid tty"
			Echo
			;;
		0)
			echo_line
			Echo "WARNING: $INST_TTY does not appear to be a valid tty"
			echo_line
			beep
			sleep 3
			;;
		*)
			echo_line
			Echo "WARNING: General tty verification failure."
			echo_line
			beep
			sleep 3
			;;
	esac

#############################################################################
# See what we can determine about the port.
#############################################################################
    if [ $SKIP_PORT_VERIFICATION -eq $FALSE ]
    then
	    Echo "The following Port validations for $INST_TTY may take a few moments...."
	    sleep 2
	    if [ $VALID_TTY -eq $TRUE ]
	    then
    		./portcheck "$INST_TTY"
	    	case "$?" in
    		1)
	    		IS_MODEM_PORT=$TRUE
		    	IS_LOCAL_PORT=$FALSE
			    Echo "$INST_TTY appears to be a modem control port"
    			sleep 1
	    		;;
		    2)
    			IS_MODEM_PORT=$FALSE
	    		IS_LOCAL_PORT=$TRUE
		    	Echo "$INST_TTY appears to be a local control port"
			    sleep 1
    			;;
	    	*)
		    	beep
			    echo_line
    			Echo "Could not determine port type!"
	    		echo_line
		    	sleep 1
			    ;;
    		esac
	    fi

	    if [ $IS_MODEM_PORT -eq $TRUE ] && [ $SIGNAL_TYPE = $SMART ]
	    then
		    echo_line
    		beep
	    	Echo "WARNING: Port must be configured for local control in order to work with a"
		    Echo "\"Smart\" Signaling UPS"
    		echo_line
	    	Echo
		    HitAnyKey
    	fi
		
	    if [ $IS_LOCAL_PORT -eq $TRUE ] && [ $SIGNAL_TYPE = $SIMPLE ]
    	then
	    	echo_line
		    beep
    		Echo "WARNING: Port must be configured for modem control in order to work with a"
	    	Echo "\"Simple\" Signaling UPS"
		    echo_line
		    Echo
    		HitAnyKey
	    fi
	    Echo
    fi
   



#############################################################################
# Modify OS system files for shutdown
#############################################################################
	modify_files=`grep -q -s -c POWERCHUTE /etc/rc.d/init.d/halt`
	if [ "$modify_files" -eq 0 ]
	then
		Echo "making backup copy of shutdown files..."
		cp $SHUTDOWN_FILE $SHUTDOWN_FILE.tmp
		cp $SHUTDOWN_FILE $SHUTDOWN_FILE_BACKUP

		Echo "modifying shutdown files...."

		if [ -r $SHUTDOWN_FILE.tmp ]
		then
			rm -f $SHUTDOWN_FILE
		else
    		echo_line
			beep
			Echo "Unable to find temp file $SHUTDOWN_FILE.tmp. Quitting."
			echo_line
			Quit
		fi
		sed "/$SHUTDOWN_SEARCH_STRING/ a\\
		$SHUTDOWN_COMMAND_STRING" $SHUTDOWN_FILE.tmp > $SHUTDOWN_FILE
		if [ ! -r $SHUTDOWN_FILE ]
		then
			echo_line
			beep
			Echo "Error writing $SHUTDOWN_FILE! Original can be found in\n$INSTALL_PATH/$SYSFILES_BACKUP_REPOSITORY. Quitting."
			echo_line
			exit
		else
			rm -f $SHUTDOWN_FILE.tmp
		fi
		chmod 754 $SHUTDOWN_FILE
	fi


#############################################################################
# Verify we can communicate with UPS
#############################################################################
	cd /usr/lib/powerchute
	RETRY=$TRUE
	RE=
	if [ $VALID_TTY -eq $TRUE ] && [ $IS_MODEM_PORT -eq $FALSE ]
	then
		while [ $RETRY -eq $TRUE ]
		do
			./upswrite $INST_TTY $CABLE_TYPE verify
			if [ $? -eq 5 ]
			then
				COMM_VERIFIED=$TRUE
				RETRY=$FALSE
				Echo 
				Echo "UPS communications on $INST_TTY verified"
				Echo "Done."
				Echo
			else
				Echo
				echo_line
				Echo "WARNING: Could not communicate with device on $INST_TTY."
				Echo "Check that the communications cable is attached properly to both the device"
				Echo "and the serial port."
				beep
				echo_line
				Echo "NOTE: Though the $FULL_PROD_NAME installation is complete, if you "
				Echo "quit before verifying communications, the application may not work properly"
				echo_line
				VALID_RE=$FALSE
				while [ $VALID_RE -eq $FALSE ]
				do
					Echo "Do you wish to Exit or Retry communications? [R/E] \\c"
					read RE
					case "$RE" in
					[Rr]*)
						RETRY=$TRUE
						VALID_RE=$TRUE
						;;
					[Ee]*)
						COMM_VERIFIED=$FALSE
						RETRY=$FALSE
						VALID_RE=$TRUE
						;;
					esac
				done
			fi						
		done
		
	elif [ $IS_LOCAL_PORT -eq $TRUE ]
	then
		echo_line
		Echo "WARNING: Due to tty verification failure, the install"
		Echo "will be unable to test UPS communications."
		echo_line
		beep
		sleep 3
	fi

#############################################################################
# Modify the powerchute.ini file
#############################################################################
        cd /usr/lib/powerchute
	rm -f /tmp/temp_ini.in
	rm -f /tmp/temp_ini.out
        cp powerchute.ini_templ /tmp/temp_ini.in 	
	cp /etc/powerchute.ini /etc/powerchute_ini.bak

	sed s!GSUB_TTY_HERE!$INST_TTY!g /tmp/temp_ini.in > /tmp/temp_ini.out
	CopyOutToIn
	sed s/GSUB_SIGTYPE_HERE/$SIGNAL_TYPE/g /tmp/temp_ini.in > /tmp/temp_ini.out
	CopyOutToIn 
	if [ $MEASURE_UPS -eq $TRUE ]
	then
		sed s/GSUB_MUPS_HERE/YES/g /tmp/temp_ini.in > /tmp/temp_ini.out
	else
		sed s/GSUB_MUPS_HERE/NO/g /tmp/temp_ini.in > /tmp/temp_ini.out
	fi
	CopyOutToIn
	if [ $UI_MONO_COLOR_SCHEME -eq $TRUE ]
	then
		sed "s/GSUB_UI_WARNCOLOR_HERE/$MONO_WARN_COLOR_STRING/g" /tmp/temp_ini.in > /tmp/temp_ini.out
	else
		sed "/GSUB_UI_WARNCOLOR_HERE/d" /tmp/temp_ini.in > /tmp/temp_ini.out
	fi
        CopyOutToIn
	if [ $UI_MONO_COLOR_SCHEME -eq $TRUE ]
	then
		sed "s/GSUB_UI_ERRCOLOR_HERE/$MONO_ERR_COLOR_STRING/g" /tmp/temp_ini.in > /tmp/temp_ini.out
	else
		sed "/GSUB_UI_ERRCOLOR_HERE/d" /tmp/temp_ini.in > /tmp/temp_ini.out 
	fi
	CopyOutToIn
        sed s!GSUB_ALLOWED_PORTS_HERE!$ALLOWED_PORT_NAMES!g /tmp/temp_ini.in > /tmp/temp_ini.out
	CopyOutToIn
	if [ $USE_TCP -eq $TRUE ]
        then
            sed s/GSUB_USETCP_HERE/YES/g /tmp/temp_ini.in > /tmp/temp_ini.out
        else
            sed s/GSUB_USETCP_HERE/NO/g /tmp/temp_ini.in > /tmp/temp_ini.out
        fi
	CopyOutToIn
        sed s/GSUB_CHANGE1_HERE/"$SYMSTR1"/g /tmp/temp_ini.in > /tmp/temp_ini.out
	CopyOutToIn
        sed s/GSUB_CHANGE2_HERE/"$SYMSTR2"/g /tmp/temp_ini.in > /tmp/temp_ini.out
	CopyOutToIn
        sed s/GSUB_TIMEOUT_HERE/"$SYMSTR13"/g /tmp/temp_ini.in > /tmp/temp_ini.out
	CopyOutToIn
	sed s/GSUB_ACTIONS_HERE/"$SYMSTR3"/g /tmp/temp_ini.in > /tmp/temp_ini.out
	CopyOutToIn
	if [ $RUN_COMMAND_FILES_AS_ROOT -eq $TRUE ]
        then
            sed s/GSUB_COMMAND_FILES_AS_ROOT_HERE/YES/g /tmp/temp_ini.in > /tmp/temp_ini.out
        else
            sed s/GSUB_COMMAND_FILES_AS_ROOT_HERE/NO/g /tmp/temp_ini.in > /tmp/temp_ini.out
        fi
	CopyOutToIn
        if [ $SEND_EMAIL_AS_ROOT -eq $TRUE ]
        then
            sed s/GSUB_SEND_EMAIL_AS_ROOT_HERE/YES/g /tmp/temp_ini.in > /tmp/temp_ini.out
        else
            sed s/GSUB_SEND_EMAIL_AS_ROOT_HERE/NO/g /tmp/temp_ini.in > /tmp/temp_ini.out
        fi
	CopyOutToIn
        if [ -n "$MODEM_PORT_NAME" ]
        then
	    sed s!GSUB_MODEM_PORT_NAME!$MODEM_PORT_NAME!g /tmp/temp_ini.in > /tmp/temp_ini.out
        else
	    sed s/GSUB_MODEM_PORT_NAME/""/g /tmp/temp_ini.in > /tmp/temp_ini.out
        fi
	CopyOutToIn
        sed s!GSUB_CABLE_TYPE_HERE!$CABLE_TYPE!g /tmp/temp_ini.in > /tmp/temp_ini.out
	CopyOutToIn
        if [ -n "$MODEM_ALLOWED_PORT_NAMES" ]
        then
	    sed s!GSUB_MODEM_ALLOWED_PORT_NAMES!$MODEM_ALLOWED_PORT_NAMES!g /tmp/temp_ini.in > /tmp/temp_ini.out
        else
	    sed s/GSUB_MODEM_ALLOWED_PORT_NAMES/""/g /tmp/temp_ini.in > /tmp/temp_ini.out
        fi

        cp -f /tmp/temp_ini.out /etc/powerchute.ini
	rm -f /tmp/temp_ini.in
	rm -f /tmp/temp_ini.out


############################################################################
# Make EEPROM adjustments
############################################################################
	if [ $COMM_VERIFIED -eq $TRUE ] && [ $SIGNAL_TYPE = $SMART ]
	then 
		
		CheckEepromUps "p" $INST_TTY
		if [ "$?" -eq $TRUE ]
		then
			beep
			echo_line
			Echo "Due to the amount of time it can take Unix platforms to shutdown,"
			Echo "it is sometimes necessary to increase the eeprom parameter UpsTurnOffDelay"
			Echo "within the UPS.  This is in order to allow sufficient time for the"
			Echo "Operating System to shutdown completely."
			echo_line
			Echo "* Doing this is recommended for the Linux Operating System *"
			echo_line

			IsYNLoop "Do you wish to increment the UpsTurnOffDelay to its next highest\nvalue now?"
			if [ "$?" -eq $YES ]
			then
				CheckDipSwitches $INST_TTY
				if [ "$?" -eq $TRUE ]
				then
					Echo "Please wait.\\c"
					desired_val="180"
					GetNextEepromValueGreaterThan "p" "20" $INST_TTY
					next_value="$?"
					if [ "$next_value" -ne "-1" ]
					then
					    desired_val=$next_value
					fi
										
					current_val="20"
					GetCurrentEepromSetting "p" $INST_TTY
					current_eeprom="$?"
					if [ "$current_eeprom" -ne "-1" ]
					then
					    current_val="$current_eeprom"
					fi
										
					CycleUntilAcceptableValue "p" "$current_val" "$desired_val" "$INST_TTY"
					if [ "$?" -eq $TRUE ]
					then
						Echo
						beep
						Echo "UpsTurnOffDelay successfully set at $desired_val."
					fi
				fi
			fi
		else
			Echo "Eeproms okay."
		fi		
	fi

############################################################################
# Add pwrchute user account
############################################################################
	if [ $USE_TCP -eq $TRUE ]
	then
		pwrchute_exists=`grep -c pwrchute /etc/passwd`
		if [ $pwrchute_exists -eq 0 ]
		then
			Echo	
			Echo "The PowerChute plus User Interface will prompt you for a password when you attempt"
			Echo "to connect to the upsd daemon running on this machine.  This password is the"
			Echo "password of the pwrchute user account."
			Echo
			Echo "Adding a pwrchute user account"
			/usr/sbin/useradd pwrchute
			Echo "Please set the password for the pwrchute user account."
			/usr/bin/passwd pwrchute
		fi
	fi

############################################################################
# Done!
############################################################################

	echo_line
	Echo "$FULL_PROD_NAME Installation complete.  You will need to reboot" 
	Echo "in order to start the application"
	echo_line

    if [ $COMM_VERIFIED -eq $FALSE ]
    then
	    echo_line
	    Echo "WARNING: Serial communications never verified, the installed product may"
	    Echo "not work properly.  You may want to try the following:"
	    Echo
	    Echo "	1) Check that specified serial device exists."
	    Echo "	2) Check the device configuration is appropriate for your UPS type"
	    Echo "	3) Rebuild or create the serial device using the utility appropriate "
	    Echo "	   for your system."
	    Echo
	    echo_line
    fi
