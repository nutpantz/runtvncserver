#!/bin/bash
# title             :startvnc
# description       :This script was written for the debian package tigervnc-scraping-server, in order to log in to the actual X session on display :0
# date              :2025
# version           :0.5
# usage             :bash startvnc
# notes             :install tigervnc-scraping-server (debian 12-13)

# What's the script name
SCRIPTNAME="startvnc"

# Where the x0vncserver executable is located, default:
VNCSERVER="/usr/bin/x0vncserver"

# Set home directory
HOMEDIR=${HOME}

# Set home ip
INTERFACE=${192.168.0.120}

# Default VNC User directory
VNCDIR="${HOMEDIR}/.vnc"

# Set log file for debugging
LOGFILE="${VNCDIR}/logfile"

# The vnc passwd file. If it doesn't exist, you need to create it
PASSWDFILE="${VNCDIR}/passwd"

# What's the Geometry  -Geometry 1280x720
GEOMETRY="1280x720"

# Leave this on ":0", since we want to log in to the actual session
DISPLAY=":0"

# Set the port (default 5900)
VNCPORT="5900"

# PID of the actual VNC server running
# The PID is actually created this way, so it is compatible with the vncserver command
# if you want to kill the VNC server manually, just type 
# vncserver -kill :0
PIDFILE="${VNCDIR}/${HOSTNAME}${DISPLAY}.pid"

# Add some color to the script
OK="[\033[1;32mok\033[0m]"
FAILED="[\033[1;31mfailed\033[0m]"
RUNNING="[\033[1;32mrunning\033[0m]"
NOTRUNNING="[\033[1;31mnot running\033[0m]"

# Function to get the process id of the VNC Server
fn_pid() {
    CHECKPID=$(ps -fu ${USER} | grep "[x]0vncserver" | awk '{print $2}')
    if [[ ${CHECKPID} =~ ^[0-9]+$ ]] 
    then
        VAR=${CHECKPID}
        return 0
    else
        return 1
    fi
}


if [ ! -d ${VNCDIR} ]
then
    echo -e "Directory ${VNCDIR} doesn't exist. Create it first." ${FAILED}
    echo
    exit 1
fi

if [ ! -f ${PASSWDFILE} ]
then
    echo -e "${PASSWDFILE} doesn't exist. Create VNC password first. ${FAILED}"
    echo "Type \"vncpasswd\" to create passwd file."
    echo
    exit 1
fi

case "$1" in
    start)
        echo -n "Starting VNC Server on display ${DISPLAY} "
        fn_pid
        if [ $? -eq 0 ]
        then
            echo -e ${FAILED}
            echo -e "VNC Server is running (pid: ${VAR})"
	    echo
        else
            ${VNCSERVER} -Geometry ${GEOMETRY} -localhost=0 -interface ${INTERFACE} -display ${DISPLAY} -passwordfile ${PASSWDFILE} -rfbport ${VNCPORT} >> ${LOGFILE} 2>&1 &
	    if [ $? -eq 0 ]
	    then
            	fn_pid
            	echo ${VAR} > ${PIDFILE}
            	echo -e ${OK}
	    	echo
	else
		echo -e $FAILED
		echo
		fi

        fi

        ;;
    
    restart)

        echo -n "Restarting VNC Server on display ${DISPLAY} "
        fn_pid
        if [ $? -eq 0 ]
        then
            kill -9 ${VAR}

            if [ $? -eq 0 ]
            then 
                ${VNCSERVER} -Geometry ${GEOMETRY} -localhost=0 -interface 192.168.0.130 -display ${DISPLAY} -passwordfile ${PASSWDFILE} -rfbport ${VNCPORT} >> ${LOGFILE} 2>&1 &
                echo -e ${OK}
		echo
                fn_pid 
                echo ${VAR} > ${PIDFILE}
                exit 0
            else
                echo -e ${FAILED}
                echo "Couldn't stop VNC Server. Exiting."
		echo
                exit 1
            fi

        else

            ${VNCSERVER} -Geometry ${GEOMETRY} -localhost=0 -interface 192.168.0.130 -display ${DISPLAY} -passwordfile ${PASSWDFILE} -rfbport ${VNCPORT} >> ${LOGFILE} 2>&1 &
            if [ $? -eq 0 ]
            then
                echo -e ${OK}
		echo
                fn_pid
                echo ${VAR} > ${PIDFILE}
            else
                echo -e ${FAILED}
                echo "Couldn't start VNC Server. Exiting."
		echo
                exit 1
            fi
        fi
    ;;

    stop)
    
        echo -n "Stopping VNC Server: "
        fn_pid
        if [ $? -eq 0 ]
        then
            kill -9 ${VAR}
	    x0vncserver -kill :0
            echo -ne ${OK}
            echo -e " (pid: ${VAR})"
	    echo
        else
            echo -e ${FAILED}
            echo -e "VNC Server is not running."
	    echo
            exit 1
        fi
    ;;

    status)
        echo -n "Status of the VNC server: "
        fn_pid
        if [ $? -eq 0 ]
        then
            echo -e "$RUNNING (pid: $VAR)"
	    echo
            exit 0
        else
            echo -e $NOTRUNNING
	    echo
        fi
        ;;

    *)
        echo
        echo "Usage: $0 start|stop|restart|status"
        echo
        exit 1
    ;;
esac
