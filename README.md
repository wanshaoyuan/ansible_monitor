# ansible_monitor
# ansible_monitor

1 先执行service_ip.sh 生成一些变量信息
2 修改/etc/ansible/host 修改对应的ip
3 执行 ansible-playbook /etc/ansible/site.yml
4 部署完后记得修改grafana的datasource zabbix的地址

2017年4月13日
v1.1
1,关闭fact功能加快执行速度，默认情况下ansible 会使用facts来检查目标服务器的环境变量，我们这里不需要使用，关闭此功>能。
2,增加ansible任务执行并发
3,修复执行顺许先解压包在scp的bug

2017年5月26日
1,增加自动插入iptables规则允许10050通过
2，增加zabbix用户sudo权限

2017年8月2日
1，修复telegraf权限问题
2，ansible将安装tlegraf给control角色去做，telegraf不会在安装到osd节点了，只会到mon节点
3，给osd节点添加metadata数据zabbix内配置了自动注册当不是融合节点情况下监控osd节点信息。

2017年9月16日
1，添加zabbix-agent开机自启

2017年10月14日
1，添加恢复环境初始化代码
~                        

```
/etc/ansible/
|-- ansible.cfg
|-- hosts
|-- readme
|-- roles
|   |-- ceph
|   |   |-- handlers
|   |   |   `-- main.yml
|   |   |-- tasks
|   |   |   `-- main.yml
|   |   |-- templates
|   |   |   `-- zabbix_agentd.conf.j2
|   |   `-- vars
|   |       `-- main.yml
|   |-- common
|   |   |-- 1
|   |   |-- handlers
|   |   |   `-- main.yml
|   |   |-- tasks
|   |   |   |-- 1
|   |   |   `-- main.yml
|   |   |-- templates
|   |   |   `-- zabbix_agentd.conf.j2
|   |   `-- vars
|   |       `-- main.yml
|   `-- telegraf
|       |-- handlers
|       |   `-- main.yml
|       |-- tasks
|       |   `-- main.yml
|       |-- templates
|       |   `-- telegraf.conf.j2
|       `-- vars
|           `-- main.yml
|-- server_ip.sh
|-- site.retry
|-- site.yml
`-- zabbix_agent.tar

```



我这里分为3个roles ，ceph、common、telegraf


ceph主要做的操作有
1、拷贝配置文件

common 主要做的操作有
1、环境初始化
2、拷贝软件包到对应节点
3、解压tar包
4、安装软件
5、修改对应的配置文件
6、修改执行权限
7、修改防火墙开放端口
8、启动服务、设置开机自启


telegraf主要做的操作有
1、安装telegraf
2、修改telegraf systemd的启动用户
3、拷贝telegraf配置文件
4、重启telegraf并设置开机启动


因为每个节点所对应的角色不一样，ansible所跑的脚本也是不一样的，所以定义这3个roles，服务器的角色通过hosts文件控制
```
[Controller] #control节点
10.10.1.[3:5]

[Computer] #非融合节点时compute节点写这

[Storage] #osd节点ip都加上(融合节点时不用写)

[ceph&compute] #融合节点时compute节点写这
10.10.1.[6:7]
[Controller:vars] #control节点变量
metadata="Controller_host"
Group="Controller"

[Computer:vars] #计算节点变量
metadata="Computer_host"
Group="Computer"

[Storage:vars]
metadata="Storager_host"
Group="Storager"

[ceph&compute:vars]
metadata="ceph&compute"
Group="ceph&compute"
```

定义了三组角色，控制节点、计算节点、存储节点、融合节点、每组角色设置了不同的metadata，这个metadata是通过templates/zabbix_agentd.conf.j2传给对应节点zabbix-agent里面的HostMetadata参数，然后zabbix-server根据不同的metadata去调用不同的模板。定义group是为了在task里面调用不同的命令。

```
---
- name: apply common configuration to all nodes
  hosts: all
  remote_user: root
  gather_facts: False
  roles:
    - common

- name: telegraf install and config
  hosts: Controller
  remote_user: root
  gather_facts: False
  roles:
    - telegraf

- name: ceph && compute config
  hosts: Storage
  remote_user: root
  gather_facts: False
  roles:
    - ceph
```

每个roles下面分handlers、tasks、templates、vars  

handlers：也是task，但只有其关注的条件满足时，才会被触发执行 。  
task：定义的是具体执行的任务。  

templates：定义的是配置文件模板，比如我们这里定义好了zabbix_agent、和telegraf的配置文件模板。  

vars：定义变量，我在templates里面定义了zabbix_agent变量，里面的server 和server_active我都是以变量方式存储的，然后在执行ansible前先把变量改好，这样在不同的环境配置文件里的ip也会根着变。  


使用方法将对应的hosts里面的ip修改然后执行ansible-playbook site.yml。




