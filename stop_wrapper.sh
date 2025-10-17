JAR_NAME=freephone_wrapper.jar

# Get the process ID (PID) of the running jar
    PID=$(ps -ef | grep "$JAR_NAME" | grep -v grep | awk '{print $2}')

    if [ -n "$PID" ]; then
        echo "Jar is running with PID $PID. Stopping it..."
        kill -9 "$PID"
        echo "Process stopped."
    else
        echo "Jar is not running."
    fi
