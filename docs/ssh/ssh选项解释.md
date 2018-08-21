# ssh选项解释
2018/8/21

```bash
##### 典型的一个端口转发示例：
ssh -o StrictHostKeyChecking=no -o ServerAliveInterval=3 -o ServerAliveCountMax=10 -NfL 11111:192.168.1.107:22222 test@192.168.1.105
##### 此时，访问 127.0.0.1:11111 则意味着是： 192.168.1.105 -> 192.168.1.107:22222


##### ssh 连过去的时候，通常会有一个交互式的动作，来检查 key，这个选项则静默处理掉了
-o StrictHostKeyChecking=no

##### 字面意义
-o ServerAliveInterval=3

##### 字面意义
-o ServerAliveCountMax=10

```
