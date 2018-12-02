# ddns-aliyun-sample

## 这里提供三种方式来动态绑定阿里云的域名
```
java
nodejs
shell
```
都经过本人的测试，是可用的

*************************************************************************
Java和nodejs版本待后续更新，先上传shell命令的。
## shell

**如果是修改子域名绑定的IP就是用下面的命令：**

`sh ./shell/aliyun-domain.sh accessKeyId accessKeySecret Domain DomainRR`

**如果是修改一级域名绑定的IP就是用下面的命令：**

`sh ./shell/aliyun-subdomain.sh accessKeyId accessKeySecret Domain @`

shell命令会先去通过[dyndns](http://members.3322.org/dyndns/getip)获取本地公网ip，然后获取域名绑定的IP，如果不相等就会把阿里云上的域名绑定的ip改为本地公网ip。如果域名记录不存在就会新增加一条解析记录解析到本地公网ip。

**aliyun.sh脚本会出现问题。**

**aliyun-domain.sh脚本是用来更新一级域名绑定的ip，经过亲自测试是可行的。**

**aliyun-subdomain.sh脚本是用来更新子域名绑定的ip，经过亲自测试是可行的。**

**在家里的服务器设置一个定时任务执行这两个脚本就可以实现动态的阿里云万网的域名DDNS了**