# ddns-aliyun-sample

## 这里提供三种方式来动态绑定阿里云的域名
```
java
nodejs
shell
```
都经过本人的测试，是可用的

*************************************************************************

## shell

**如果是修改二级域名绑定的IP就是用下面的命令：**

`sh ./shell/aliyun.sh accessKeyId accessKeySecret Domain DomainRR`

**如果是修改一级域名绑定的IP就是用下面的命令：**

`sh ./shell/aliyun.sh accessKeyId accessKeySecret Domain @`

shell命令会先去通过[dyndns](http://members.3322.org/dyndns/getip)获取本地公网ip，然后获取域名绑定的IP，如果不相等就会把阿里云上的域名绑定的ip改为本地公网ip。如果域名记录不存在就会新增加一条解析记录解析到本地公网ip。