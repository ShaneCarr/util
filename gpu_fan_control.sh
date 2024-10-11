#!/bin/bash

# Path to the mode control file
MODE_FILE="$HOME/.nvidia_fan_mode"

# Custom fan curve logic
custom_fan_curve() {
    echo "Setting custom fan curve..."
    sudo nvidia-settings -a "[gpu:0]/GPUFanControlState=1" > /dev/null 2>&1
    
    while true; do
        if [[ $(cat $MODE_FILE) != "manual" ]]; then
            # Stop loop if not in custom curve mode
            exit 0
        fi

        TEMP=$(nvidia-smi --query-gpu=temperature.gpu --format=csv,noheader,nounits)

        if [ "$TEMP" -ge 70 ]; then
            sudo nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=100" > /dev/null 2>&1
        elif [ "$TEMP" -ge 60 ]; then
            sudo nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=80" > /dev/null 2>&1
        elif [ "$TEMP" -ge 50 ]; then
            sudo nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=60" > /dev/null 2>&1
        elif [ "$TEMP" -ge 45 ]; then
            sudo nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=40" > /dev/null 2>&1
        else
            sudo nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=30" > /dev/null 2>&1
        fi

        sleep 10
    done
}

# Switch to automatic fan control
automatic_fan_control() {
    echo "Switching to automatic fan control..."
    sudo nvidia-settings -a "[gpu:0]/GPUFanControlState=0" > /dev/null 2>&1
    echo "automatic" > "$MODE_FILE"
}

# Set manual fan speed
manual_fan_speed() {
    SPEED=$1
    echo "Setting manual fan speed to $SPEED%"
    sudo nvidia-settings -a "[gpu:0]/GPUFanControlState=1" > /dev/null 2>&1
    sudo nvidia-settings -a "[fan:0]/GPUTargetFanSpeed=$SPEED" > /dev/null 2>&1
    echo "manual" > "$MODE_FILE"
}

# Show current GPU stats
show_status() {
    nvidia-smi --query-gpu=temperature.gpu,fan.speed,power.draw --format=csv
}

# Main script logic
case $1 in
    m*)
        # Set specific manual fan speed (e.g., m60 for 60%)
        SPEED=$(echo "$1" | sed 's/m//')
        manual_fan_speed $SPEED
        ;;
    a)
        automatic_fan_control
        ;;
    c)
        echo "manual" > "$MODE_FILE"
        #custom_fan_curve & # for manual run
        custom_fan_curve 
        ;;
    s)
        show_status
        ;;
    *)
        echo "Usage: nvidiafan [a|c|m|s]"
        echo "  a: Switch to automatic mode"
        echo "  c: Switch to custom fan curve mode"
        echo "  m<number>: Set manual fan speed (e.g., m60 for 60%)"
        echo "  s: Show current GPU stats"
        ;;
esac

