#! /bin/bash

# First, get the number of monitors from xrandr and store it as a variable:
MONITOR_COUNT=$( xrandr | grep " connected" | wc -l )

# These are arrays that we'll be using below to distribute our bspwm workspaces depending on the number of monitors provided. We declare them here just because it's tidy but don't specify the number of elements because the size of the array will change depending on how many monitors we have.
declare -a MONITOR_ARRAY
declare -a WORKSPACE_ARRAY

# Second, check the names of all monitors that are not eDP1 (change to whatever your default screen is called inside of xrandr and throw all of those names into an array because I'm a piece of shit :3
for(( i=1; i <= $MONITOR_COUNT; i++ ))
do
	MONITOR_ARRAY[$i]=$( xrandr | grep " connected" | awk '{print $1}' | sed -n "$i"'p' )
	echo "Monitor $i counted - ${MONITOR_ARRAY[$i]}"

done	

# At this point let's go verify that all monitor options that are no longer connected/not connected are disabled in xrandr. We're doing this just to keep the cursor confined in visible monitors when unplugging a monitor.
DISABLED_MONITOR_COUNT=$( xrandr | grep "disconnected" | wc -l)
for(( i=1; i <= $DISABLED_MONITOR_COUNT; i++ ))
do
	TO_REMOVE=$( xrandr | grep "disconnected" | awk '{print $1}' | sed -n "$i"'p' )
	xrandr --output $TO_REMOVE --off
	echo "$TO_REMOVE disabled. ($i of $DISABLED_MONITOR_COUNT)"
done

# Thirdly, we go ahead and distribute the workspaces depending on the number of monitors.  I was going to make this more elegant and distribute them dynamically, but I just wanted something that works at first.
case $MONITOR_COUNT in
	1)echo "All workspaces being added to one monitor..."
	  WORKSPACE_ARRAY[1]="I II III IV V VI VII VIII IX X";;
	2)echo "Workspaces being distributed across two monitors..."
	  WORKSPACE_ARRAY[1]="I II III IV V"
	  WORKSPACE_ARRAY[2]="VI VII VIII IX X";;
	3)echo "Workspaces being distributed across three monitors..."
	  WORKSPACE_ARRAY[1]="I II III IV"
	  WORKSPACE_ARRAY[2]="V VI VII"
	  WORKSPACE_ARRAY[3]="VIII IX X";;
esac

# Use bspc monitor -d to pin workspaces to each desktop I guess idk I fucking hate it here.
for(( i=1; i <= $MONITOR_COUNT; i++))
do
	#Time to nest some 4 loops boooiiii-- get all the resolutions of the current monitor and apply the highest refresh rate
	XRANDR_LINE=$( xrandr | grep -A1 '\'"${MONITOR_ARRAY[$i]}"'' | sed -n 2p )
	RESOLUTION=$( echo $XRANDR_LINE | awk '{print $1}')
	declare -a RATE_ARRAY
	for(( ii=2; ii <= $( echo $XRANDR_LINE | awk '{ print NF }'); ii++))
	do
		RATE_ARRAY[$ii]=$( echo $XRANDR_LINE | awk '{print $'"$ii"'}' | tr -d '*+')
		echo "Current refresh rate being added to resolution array: ${RATE_ARRAY[$ii]}"
	done
	REFRESH_RATE=$( IFS=$'\n' && echo "${RATE_ARRAY[*]}" | sort -nr | head -n1)
	echo "$REFRESH_RATE is the highest refresh rate"
	
	if [ ${MONITOR_ARRAY[$i]} == "eDP1" ];
	then
		echo "pog it's eDP1"
		xrandr --output ${MONITOR_ARRAY[$i]} --mode $RESOLUTION --rate $REFRESH_RATE
	else
		echo "unpog it's not eDP1"
		xrandr --output ${MONITOR_ARRAY[$i]} --mode $RESOLUTION --rate $REFRESH_RATE --right-of eDP1
	fi
	bspc monitor ${MONITOR_ARRAY[$i]} -d ${WORKSPACE_ARRAY[$i]}
	bspc wm --adopt-orphans 
done
