#!/bin/sh

set -e

if [ $1 ]; then
	ApiId=$1
fi

if [ $2 ]; then
	ApiKey=$2
fi

if [ $3 ]; then
	Domain=$3
fi

if [ -z "$ApiId" -o -z "$ApiKey" -o -z "$Domain" ]; then
	echo "参数缺失"
	exit 1
fi

if [ $4 ]; then
	SubDomain=$4
fi

if [ -z "$SubDomain" ]; then
	SubDomain="@"
fi

Nonce=$(date -u "+%N")	# 有bug?
Timestamp=$(date -u "+%Y-%m-%dT%H%%3A%M%%3A%SZ")	# SB 阿里云, 什么鬼时间格式
Nonce=$Timestamp

urlencode() {
	local raw="$1";
	local len="${#raw}"
	local encoded=""

	for i in `seq 1 $len`; do
		local j=$((i+1))
		local c=$(echo $raw | cut -c$i-$i)

		case $c in [a-zA-Z0-9.~_-]) ;;
			*)
			c=$(printf '%%%02X' "'$c") ;;
		esac

		encoded="$encoded$c"
	done

	echo $encoded
}

# $1 = query string
getSignature() {
	local encodedQuery=$(urlencode $1)
	local message="GET&%2F&$encodedQuery"
	local sig=$(echo -n "$message" | openssl dgst -sha1 -hmac "$ApiKey&" -binary | openssl base64)
	echo $(urlencode $sig)
}

sendRequest() {
	local sig=$(getSignature $1)
	local result=$(wget -qO- --no-check-certificate --content-on-error "https://alidns.aliyuncs.com?$1&Signature=$sig")
	echo $result
}

getRecordId() {
	echo "获取 $SubDomain.$Domain 的 IP..." >&2
	local queryString="AccessKeyId=$ApiId&Action=DescribeSubDomainRecords&Format=JSON&SignatureMethod=HMAC-SHA1&SignatureNonce=$Nonce&SignatureVersion=1.0&SubDomain=$SubDomain.$Domain&Timestamp=$Timestamp&Type=A&Version=2015-01-09"
	local result=$(sendRequest "$queryString")
	echo "getRecordId()-------result----------$result------------" >&2
	local recordId=$(echo $result | sed 's/.*,"RecordId":"\([0-9]*\)",.*/\1/')
	echo "getRecordId()-----recordId-------$recordId------" >&2

	if [ ! "$recordId" = "$result" ]; then
		local ip=$(echo $result | sed 's/.*,"Value":"\([0-9\.]*\)",.*/\1/')
		echo "getRecordId() -------------ip------------- $ip---------------------------" >&2
		echo "getRecordId() --------------NewIP------------ $NewIP---------------------------" >&2
		if [ "$ip" == "$NewIP" ]; then
			echo "IP 无变化, 退出脚本..." >&2
			echo "quit"
		else
			echo $recordId
		fi
	else
		echo "null"
	fi
}

# $1 = record ID, $2 = new IP
updateRecord() {
	local queryString="AccessKeyId=$ApiId&Action=UpdateDomainRecord&DomainName=$Domain&Format=JSON&RR=$SubDomain&RecordId=$1&SignatureMethod=HMAC-SHA1&SignatureNonce=$Nonce&SignatureVersion=1.0&Timestamp=$Timestamp&Type=A&Value=$2&Version=2015-01-09"
	echo "updateRecord------------queryString--------" >&2
	echo $queryString >&2
	local result=$(sendRequest $queryString)
	local code=$(echo $result | sed 's/^{"RecordId":"\([0-9]*\)".*/\1/g')
	echo "updateRecord()-------result----------- $result" >&2
    echo "updateRecord()------code--------------- $code" >&2
	if [ "$code" = "$result" ]; then
		echo "更新失败." >&2
		echo $result >&2
	else
		echo "$SubDomain.$Domain 已指向 $NewIP." >&2
	fi
}

# $1 = new IP
addRecord() {
	local queryString="AccessKeyId=$ApiId&Action=AddDomainRecord&DomainName=$Domain&Format=JSON&RR=$SubDomain&SignatureMethod=HMAC-SHA1&SignatureNonce=$Nonce&SignatureVersion=1.0&Timestamp=$Timestamp&Type=A&Value=$1&Version=2015-01-09" >&2
	echo "addRecord------------queryString--------" >&2
	echo $queryString >&2
	local result=$(sendRequest $queryString)
	local code=$(echo $result | sed 's/^{"RecordId":"\([0-9]*\)".*/\1/g')
	echo "addRecord()-----result------- $result" >&2
	echo "addRecord()------code------------ $code" >&2
	if [ "$code" = "$result" ]; then
		echo "添加失败." >&2
		echo $result >&2
	else
		echo "$SubDomain.$Domain 已指向 $NewIP." >&2
	fi
}

# Get new IP address
echo "获取当前 IP..." >&2
NewIP=$(wget -qO- --no-check-certificate "http://members.3322.org/dyndns/getip")
echo "当前 IP 为 $NewIP." >&2

# Get record ID of sub domain
recordId=$(getRecordId) >&2
echo "获取当前 IP...recordId------------$recordId---------------" >&2
if [ ! "$recordId" = "quit" ]; then
	if [ "$recordId" = "null" ]; then
		echo "域名记录不存在, 添加 $SubDomain.$Domain 至 $NewIP..."
		addRecord $NewIP
	else
		echo "域名记录已存在, 更新 $SubDomain.$Domain $recordId至 $NewIP..."
		updateRecord $recordId $NewIP
	fi
fi