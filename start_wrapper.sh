#!/bin/bash

#going into the directory
cd /home/freephone-wrapper/

# Name of the jar file
JAR_NAME="freephone_wrapper.jar"

# Full path to the Java executable (adjust as per your JDK installation)
JAVA_HOME="/home/freephone-wrapper/jdk-21.0.5"
JAVA_EXEC="$JAVA_HOME/bin/java"

# Function to check if the jar is running
check_and_kill_jar() {
    # Get the process ID (PID) of the running jar
    PID=$(ps -ef | grep "$JAR_NAME" | grep -v grep | awk '{print $2}')
    
    if [ -n "$PID" ]; then
        echo "Jar is running with PID $PID. Stopping it..."
        kill -9 "$PID"
        echo "Process stopped."
    else
        echo "Jar is not running."
    fi
}

# Main script
check_and_kill_jar

echo "Starting the jar with new configuration..."

# Run the jar with specified config files
nohup "$JAVA_EXEC"  -Xmx4g -Dlog4j.configurationFile="log4j2.xml" -Dspring.config.location="application.properties" -jar "$JAR_NAME" &

echo "Jar started successfully."

