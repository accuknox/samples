#!/bin/bash

podname=$(kubectl get pod -n explorer -l container=knoxautopolicy -o=jsonpath='{.items[0].metadata.name}' --field-selector=status.phase==Running)
[[ $? -ne 0 ]] && echo "could not find knoxautopolicy pod" && exit 2

function trigger_policy_dump()
{
	kubectl exec -n explorer $podname -- bash -c "rm *_policies*.yaml 2>/dev/null; /convert_$1_policy.sh > /dev/null"
	[[ $? -ne 0 ]] && echo "getting $1 policies failed" && exit 1
}

function network_policy()
{
#	kubectl exec -n explorer $podname -- bash -c "rm cilium_policies*.yaml 2>/dev/null" 2>/dev/null
	trigger_policy_dump net
	filelist=`kubectl exec -n explorer $podname -- ls -1 | grep "cilium_policies.*\.yaml"`
	[[ "$filelist" == "" ]] && echo "No network policies discovered" && return
	for f in `echo $filelist`; do
		f=$(echo $f | tr -d '\r')
		typ=${f/_*/}
		ns=${f/*_policies_/}
		ns=${ns/.yaml/}
		kubectl cp explorer/$podname:$f $f
		cnt=`grep "kind:" $f | wc -l`
		echo "Got $cnt $typ policies in file $f"
	done
}

function system_policy()
{
#	kubectl exec -n explorer $podname -- bash -c "rm kubearmor_policies*.yaml 2>/dev/null" 2>/dev/null
	trigger_policy_dump sys
	[[ "$FILTER" == "" ]] && FILTER="kubearmor_policies.*\.yaml"
	filelist=`kubectl exec -n explorer $podname -- ls -1 | grep "$FILTER"`
	[[ "$filelist" == "" ]] && echo "No system policies discovered" && return 1
	for f in `echo $filelist`; do
		f=$(echo $f | tr -d '\r')
		typ=${f/_*/}
		kubectl cp explorer/$podname:$f $f
		cnt=`grep "kind:" $f | wc -l`
		echo "Got $cnt $typ policies in file $f"
	done
}

usage()
{
	echo "$0 [options]"
	echo -en "\t-f|--fetch [cilium|kubearmor] ... default [cilium|kubearmor]\n"
	echo -en "\t--filter [kubearmor_policies_default_*.yaml] ... default []\n"
	exit
}

parse_cmdargs()
{
	FETCH="cilium|kubearmor"
    OPTS=`getopt -o hf: --long filter:,fetch:,help -n 'parse-options' -- "$@"`
    eval set -- "$OPTS"
    while true; do
        case "$1" in
            -f | --fetch ) FETCH="$2"; shift 2;;
            --filter ) FILTER="$2"; echo "USING $FILTER"; shift 2;;
            -h | --help ) usage; shift 2;;
            -- ) shift; break ;;
            * ) break ;;
        esac
    done
}

parse_cmdargs $*
[[ "$FETCH" =~ .*cilium.* ]] && network_policy
[[ "$FETCH" =~ .*kubearmor.* ]] && system_policy
