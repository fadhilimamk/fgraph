function prepare_fio_attr() {
	FIO_ATTR=""
	FIO_ATTR="$FIO_ATTR --name=graph"
	FIO_ATTR="$FIO_ATTR --ioengine=psync"
	FIO_ATTR="$FIO_ATTR --rw=randread"
	#FIO_ATTR="$FIO_ATTR --number_ios=1"
	FIO_ATTR="$FIO_ATTR --numjobs=$1"
	FIO_ATTR="$FIO_ATTR --bs=4k"
	FIO_ATTR="$FIO_ATTR --size=4k"
	FIO_ATTR="$FIO_ATTR --per_job_logs=0"
	FIO_ATTR="$FIO_ATTR --group_reporting"
	FIO_ATTR="$FIO_ATTR --direct=1"
	FIO_ATTR="$FIO_ATTR --time_based=1"
	FIO_ATTR="$FIO_ATTR --runtime=10"
	FIO_ATTR="$FIO_ATTR --randrepeat=0"
	FIO_ATTR="$FIO_ATTR --norandommap=1"
	FIO_ATTR="$FIO_ATTR --thread"
	FIO_ATTR="$FIO_ATTR --filename=/dev/nvme0n1"

	echo $FIO_ATTR
}

function run_fio() {
	number_jobs=$1

	attrs=$(prepare_fio_attr $number_jobs)
	echo "$(sudo fio $attrs)"
}

# return latency in us from fio standard output
function fio_get_lat() {
	fio_result=$1
	is_nsec=true
	
	result=$(echo "${fio_result}" | grep -e '[[:space:]]lat (nsec)')
	if [ -z "$result" ]; then
		result=$(echo "${fio_result}" | grep -e '[[:space:]]lat (usec)')
		is_nsec=false
	fi
	
	latency=$(echo $result | cut -d',' -f3 | cut -d'=' -f2)


	if [ "$is_nsec" = true ]; then
		latency=$(echo $latency*1000 | bc)
	fi

	echo "${latency}"
}

function cleanup() {
	if ls graph.*.0 1> /dev/null 2>&1; then
		rm graph.*.0
	fi
}

echo "Start benchmark, it will take a few minutes."
for NUM_THREAD in 2 4 8 16 32; do
	printf "\tRunning test with %d threads " $NUM_THREAD

	# for each NUM_THREAD run 3 time and get the average
        COUNTER=0; SUM=0
        while [ $COUNTER -lt 3 ]; do
		result=$(run_fio $NUM_THREAD)
		echo "$result" >> "log/log_thread_$NUM_THREAD"
        	latency=$(fio_get_lat "$result")
		SUM=$(echo $SUM+$latency | bc)
		printf "."
        	let COUNTER=COUNTER+1 
        done

	avg_latency=$(echo $SUM/3 | bc)
	printf "\t %.2f us\n" $avg_latency

done

cleanup

exit 0
