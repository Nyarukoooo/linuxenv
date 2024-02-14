#!/bin/bash

#ccp config 配置变量能不能放另外一个脚本？
API_KEY="9bfccd68-739b-43d9-81e7-6c18fa85cce8"
DEFAULT_INTERVALS="1h,24h,7d,30d"
SCRIPT_NAME=$(basename "$0")

#database config
HOST="118.31.51.60"
PORT="5432"
DB_NAME="ccp_watchlist"
DB_USER="postgres"
DB_PASSWORD="0703"
uid=$(whoami)

#query
add_user="
INSERT INTO config(username, watchlist) 
VALUES('${uid}', 'BTC,ETH,BNB');"

check_user="
SELECT username 
FROM config 
WHERE username = '${uid}';"

check_watchlist="
SELECT watchlist
FROM config
WHERE username = '${uid}';"

update_watchlist="
UPDATE config 
SET watchlist = '${tokens}' 
WHERE username = '${uid}';"

see_all="SELECT * FROM config;"

#query function
postsql(){
	local query=$1
	PGPASSWORD=${DB_PASSWORD} psql -X -A -t -U ${DB_USER} -h ${HOST} -p ${PORT} -d ${DB_NAME}<<EOF
${query}
EOF
}

add_token(){
	local token=$1
	PGPASSWORD=${DB_PASSWORD} psql -U ${DB_USER} -h ${HOST} -p ${PORT} -d ${DB_NAME}<<EOF
UPDATE config 
SET watchlist = '${token}'
WHERE username = '${uid}'
EOF
}
helper(){
    printf "Usage: \e[1;34m%s [-s -a -d <tokens>] [-h]\e[0m\n" "$SCRIPT_NAME"
    echo "  -s <tokens>: Specify tokens to watch (comma-separated)"
	printf "               Example: \e[1;34mcryptoPrice -s BTC ETH BNB\e[0m: create a new watchlist including BTC,ETH,BNB and show the current price info.\n" 
	printf "                        \e[1;34mcryptoPrice BTC ETH BNB\e[0m: show the current price info.\n"
	printf "                        \e[1;34mcryptoPrice\e[0m: show current price info of tokens in the watchlist.\n"
	echo "  -a <tokens>: add tokens into watch list"
	echo "  -d <tokens>: delete tokens from watch list"
    echo "  -h, --help: Display this help message"
}
#set color and format of percent_change 
set_percent_change_format(){
	local change=$1
	local color_code=$(tput setaf 1)
	if (( $(echo "$change >= 0 " | bc -l) )); then
		color_code=$(tput setaf 2)
	fi
	echo -e $(printf "%s%-9.2f%%$(tput sgr0)" "${color_code}" "$change")
}

set_title(){
	local interval_list=$1
	local percent_change_title=""
	IFS=',' read -r -a intervals <<< "$interval_list"
	for interval in "${intervals[@]}"; do
		percent_change_title+=$(printf "%-9s" ${interval})
	done
	printf "%-5s %-5s \$%-10s %s\n"\
		"Token" "Rank" "Price" "${percent_change_title}"
}


check_user_exist(){
	if [[ $(postsql "${check_user}") != ${uid} ]]; then
		postsql "${add_user}" > /dev/null
		printf "Cannot found user \e[1:34m${uid}\e[0m.\nCreating new user as \e[1:34m${uid}\e[0m.\n"
		printf "Creating Default Watchlist: \e[1;32mBTC, ETH, BNB\e[0m\n"
	fi
}

save_to_config(){
	check_user_exist
	add_token "${tokens}" > /dev/null
	printf "Watchlist updated: \e[1;34m$tokens\e[0m\n"
}


read_from_config(){
	check_user_exist
	tokens=$(postsql "${check_watchlist}")
	if [[ ! $tokens ]]; then
		printf "Your watchlist is empty.\nAdding default watchlist: \e[1;34mBTC, ETH, BNB\e[0m\n"
		add_token "BTC,ETH,BNB" > /dev/null
	fi
	tokens=$(postsql "$check_watchlist")
}

add_to_config(){
	read_from_config
	local add_list=($@)
	IFS=',' read -ra tokens_list <<< "${tokens}"
	
	#合并config中的token和输入的token，并且去重排序
	merged_list=($(echo "${add_list[@]}" " ${tokens_list[@]}" | tr ' ' '\n' | sort -u))
	tokens=$(convert2API_format ${merged_list[@]})
	save_to_config
}

delete_from_config(){
	read_from_config
	local delete_list=($@)
	local config_token_list=($(echo "${tokens}" | tr ',' ' '))
	local delete_token_found=false
	tokens=""

	for token in "${config_token_list[@]}"; do
		if [[ " ${delete_list[@]} " =~ " ${token} " ]]; then
			delete_token_found=true
			printf "Delete token from watch list: \e[1;31m${token}\e[0m\n"
		else
			tokens+="$token,"
		fi
	done
	tokens="${tokens%?}"
	save_to_config
}

remove_input_duplicated(){
    	local array=($@)
    	sorted_unique_array=($(echo "${array[@]}" | tr ' ' '\n' | sort -u))
	echo ${sorted_unique_array[@]}
}

convert2API_format(){
	local raw_data=$@
	#format: array 2 "token,token,token"
	formatted_data=$(echo "$raw_data" | awk '{gsub(/ +/, ","); print toupper($0)}')
	echo $formatted_data
}

price_format(){
	local price=$(printf "%.10f" $1)
	local decimal_part=$(echo "$price" | awk -F'.' '{print $2}')
	#get first 5 digits after dot in price
	if [[ "${decimal_part:0:5}" == "00000" ]]; then
		local remaining_digits=${price:7}
		echo "0.5x|$remaining_digits"
	else
		echo $price
	fi
}

#define $tokens here
parse_params(){
	local save_tokens=false
	local add_tokens=false
	local delete_tokens=false
	local params=()
	local token=""
	tokens=""
  	if [[ $# -eq 0 ]]; then
		read_from_config
	else
		while [[ $# -gt 0 ]]; do
			case "$1" in
				-a|--add)
					add_tokens=true
					shift
					;;
				-d|--delete)
					delete_tokens=true
					shift
					;;
				-s|--save)
					save_tokens=true
					shift
					;;
				-h|--help)
					helper
					exit 0
					;;
				*)
					token=$(echo $1 | tr '[:lower:]' '[:upper:]')
					params+=("$token")
					shift
					;;
			esac
		done
		params=($(remove_input_duplicated ${params[@]}))
		if [[ $save_tokens == true ]]; then
			tokens=$(convert2API_format ${params[@]})
			save_to_config 
		elif [[ $add_tokens == true ]]; then
			add_to_config ${params[@]}	
		elif [[ $delete_tokens == true ]]; then
			delete_from_config ${params[@]}
		else
			tokens=$(convert2API_format ${params[@]})
		fi
	fi
}

get_data(){
	local api_response=$1
	local token_list=$2
	local interval_list=$3
	local data=""
	local non_exist_list=()
	data+="$(set_title "${interval_list}")\n"

	IFS=',' read -r -a tokens <<< "$token_list"
	IFS=',' read -r -a intervals <<< "$interval_list"
	for token in "${tokens[@]}"; do
		local price=$(echo "$api_response" | jq -r ".data.${token}.quote.USD.price")
		local rank=$(echo "$api_response" | jq -r ".data.${token}.cmc_rank")
		local percent_change_list=""
		if [[ $rank -ne "null" ]]; then
			for interval in "${intervals[@]}"; do
				local percent_change=$(echo "$api_response" | jq -r ".data.${token}.quote.USD.percent_change_${interval}")
				percent_change_list+=$(printf "%-10s" $(set_percent_change_format ${percent_change}))
			done
			#format price
			if (( $(echo "$price >= 10" | bc -l) ));then
				data+="$(printf "%-5s %-5s \$%-10.2f %s\n" "$token" "$rank"  "$price" "$percent_change_list")\n"
			elif (( $(echo "$price <= 0.00001" | bc -l) ));then
				price=$(price_format $price)
				data+="$(printf "%-5s %-5s \$%-10s %s\n" "$token" "$rank" "$price" "$percent_change_list")\n"
			else
				data+="$(printf "%-5s %-5s \$%-10.6f %s\n" "$token" "$rank" "$price" "$percent_change_list")\n"
			fi
		else
			non_exist_list+=("$token")
		fi
	done
	if [[ ${#non_exist_list[@]} -ge 1 ]];then
		non_exist_tokens=$(convert2API_format ${non_exist_list[@]})
		echo -e "Following tokens are not existed: ${non_exist_tokens}"
		delete_from_config ${non_exist_list[@]}
	fi
	echo -e "$data" | column -t -s $'\t'
}

price_request(){
	local sysbol_param=$1
	api_response=$(curl -s -H "X-CMC_PRO_API_KEY:${API_KEY}" \
	  -H "Accept: application/json" \
	  -d "symbol=$symbol_param" \
	  -G https://pro-api.coinmarketcap.com/v1/cryptocurrency/quotes/latest \
	  -m 10 )
	#check connection and API request error
	error_code=$?
	if (( error_code > 0 )); then
		echo "Internet Connection Failed. Please check your connection or proxy. error code: $error_code"
		return 1
	fi
	error_code=$(echo "$api_response" | jq -r ".status.error_code")
	if (( error_code > 0 )); then
		error_message=$(echo "$api_response" | jq -r ".status.error_message")
		printf "CryptoMarketCap API request was failed.\n"
		printf "Error Code: \e[1;31m$error_code\e[0m\n"
		printf "Error Message: \e[1;31m$error_message\e[0m\n"
		return 1
  	fi
	echo $api_response
}

check_error(){
	if [[ $? -ne 0 ]]; then
		echo "$@"
		exit 1
	fi
}

main(){
	parse_params "$@"
	symbol_param=$(echo "$tokens" | jq -nRr --arg tokens "$tokens" '$tokens | split(",") | map(@uri) | join(",")')
	price_response=$(price_request $symbol_param)
	check_error "$price_response"
	get_data "$price_response" "$tokens" "$DEFAULT_INTERVALS"
}

main "$@"
