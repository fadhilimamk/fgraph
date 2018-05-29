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
	FIO_ATTR="$FIO_ATTR --runtime=30"
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

function fio_get_lat() {
	fio_result=$1
	is_nsec=true

	result=$(echo "${fio_result}" | grep -e '[[:space:]]lat (nsec)')
	if [ -z "$result"] ; then
		result=$(echo "${fio_result}" | grep -e '[[:space:]]lat (usec)')
		is_nsec=false
	fi
	result=$(echo $result | cut -d',' -f3 | cut -d'=' -f2)

	if $is_nsec ; then
		let result=$result*1000
	fi

	echo "${result}"
}

function cleanup() {
	if ls graph.*.0 1> /dev/null 2>&1; then
		rm graph.*.0
	fi
}

echo "Running benchmark with 256 threads"
result=$(run_fio 256)
echo "${result}"
echo $(fio_get_lat "$result")

cleanup
