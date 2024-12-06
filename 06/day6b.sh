#!/usr/bin/env bash
set -o pipefail
declare -A map
declare -a lines
declare -i positions
declare -i guard_i
declare -i guard_j
declare -a guard=("^" "v" "<" ">")
declare -i bound_i
declare -i bound_j
declare -a seen
declare -a route
terminate() { # Because I'm a professional 8-)
	local msg="${1}"
	local code="${2}"
	echo "Error: ${msg}" >&2
	exit "${code:-1}"
}
usage() {
	cat <<EOF
Usage: day6.sh [FILE]
    Returns the number of distinct positions visited by the guard.
    Arguments:
        FILE: A text file containing current position as described in Day 6: Guard Gallivant
EOF
}

[[ $# -lt 1 ]] && ( usage; terminate "No input file specified" 2 )
[[ ! -s $1 ]] && ( usage; terminate "The input file is empty" 3 )

echo "If you have fond feelings for your CPU pls don't execute" && exit 1

input_file=$1
mapfile -t lines < <(sed '/^$/d' "$input_file")

# Create associative array (i.e. matrix)
for (( i=0; i < "${#lines[@]}"; i++ )); do
    for (( j=0; j < "${#lines[0]}"; j++ )); do
        char="${lines[i]:$j:1}"
        if [[ "${guard[*]}" == *"$char"* ]]; then
            guard_i=$i
            guard_j=$j
            start_i=$guard_i
            start_j=$guard_j
            start_obj="$char"
        fi
        map["$i","$j"]="${lines[i]:$j:1}"
    done
done
bound_i="${#lines[@]}"
bound_j="${#lines[0]}"

print_map() {
    for (( i=0; i < "${#lines[@]}"; i++ )); do
        line=""
        for (( j=0; j < "${#lines[0]}"; j++ )); do
            char="${map["$i","$j"]}"
            line="${line}${char}"
        done
        echo "$line"
    done
}

next_move() {
    print_route="$1"
    if [ "$print_route" = "route" ]; then route+=("$guard_i","$guard_j"); fi

    new_i=$guard_i
    new_j=$guard_j
    case "${map["$guard_i","$guard_j"]}" in
        "^")
            (( new_i-=1 )); [[ new_i -lt 0 || new_i -eq $bound_i ]] && done=true
            if [ "${map["$new_i","$guard_j"]}" = "#" ]; then 
                map["$guard_i","$guard_j"]=">"
            else
                map["$guard_i","$guard_j"]="."
                (( guard_i-=1 ))
                if [ $done = "false" ]; then map["$guard_i","$guard_j"]="^"; fi
            fi
        ;;
        "v")
            (( new_i+=1 )); [[ new_i -lt 0 || new_i -eq $bound_i ]] && done=true
            if [ "${map["$new_i","$guard_j"]}" = "#" ]; then 
                map["$guard_i","$guard_j"]="<"
            else
                map["$guard_i","$guard_j"]="."
                (( guard_i+=1 ))
                if [ $done = "false" ]; then map["$guard_i","$guard_j"]="v"; fi
            fi
        ;;
        ">")
            (( new_j+=1 )); [[ new_j -lt 0 || new_j -eq $bound_j ]] && done=true
            if [ "${map["$guard_i","$new_j"]}" = "#" ]; then 
                map["$guard_i","$guard_j"]="v"
            else
                map["$guard_i","$guard_j"]="."
                (( guard_j+=1 ))
                if [ $done = "false" ]; then map["$guard_i","$guard_j"]=">"; fi
            fi
        ;;
        "<")
            (( new_j-=1 )); [[ new_j -lt 0 || new_j -eq $bound_j ]] && done=true
            if [ "${map["$guard_i","$new_j"]}" = "#" ]; then 
                map["$guard_i","$guard_j"]="^"
            else
                map["$guard_i","$guard_j"]="."
                (( guard_j-=1 ))
                if [ $done = "false" ]; then map["$guard_i","$guard_j"]="<"; fi
            fi
        ;;
    esac
}

check_loop() {
    while [[ $done = "false" && ! "${seen[*]}" == *"$guard_i,$guard_j,${map["$guard_i","$guard_j"]}"* ]]; do
        seen+=("$guard_i" "$guard_j" "${map["$guard_i","$guard_j"]}")
        next_move
    done
    if [[ "${seen[*]}" == *"$guard_i $guard_j ${map["$guard_i","$guard_j"]}"* ]]; then
        ((positions++))
    fi
}

# Get the positions for placing an obstacle
done=false
while [ $done = "false" ]; do
    next_move route
done
mapfile -t route < <(printf "%s\n" "${route[@]}" | sort -u)


print_map

for location in "${route[@]}"; do
    done=false
    guard_i=$start_i
    guard_j=$start_j
    map["$start_i","$start_j"]="$start_obj"
    seen=()

    map["$location"]="#"
    check_loop
    map["$location"]="."
    break
done

echo $positions
# echo "${route[@]}"