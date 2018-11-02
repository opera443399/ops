docker深入2-UI之portainer通过API来更新service的ACL
2018/11/2


### 准备工作
1. 阅读文档
2. 本例在 mac 下操作，使用 httpie 来发送请求
`brew install httpie`
3. 通过 jq 来格式化数据
`brew install jq`
4. 干活的目录
`/tmp/httpie`


### 原因
portainer升级至1.19.2后，有比较特别的变化：

1.19.2
---
Breaking changes
---

This version changes the default ownership for externally created resources from Public to Administrator restricted (#960, #2137). The migration process will automatically migrate any existing resource declared as Public to Administrators only.

`尽管之前为 service 设置过 ACL ，但在升级后发现还是全部重置为 Administrators 权限`


### 临时解决办法: 通过API来重置ACL
下面是具体示范：

##### *1. 拿到认证 token*
```bash
http POST http://your-portainer-addr/api/auth Username="admin" Password="portainer"
{
    "jwt": "xxJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcm5hbWUiOiJhZG1pbiIsInJvbGUiOjEsImV4cCI6MTUzOTYxNzcwNX0.ifadEaqEo7LNWPuPBl8zQMZqeFvxfVPgAD6asNdMQYY"
}

```

##### *2. 列出teams信息*
```bash
http GET http://your-portainer-addr/api/teams \
"Authorization: Bearer xxJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcm5hbWUiOiJhZG1pbiIsInJvbGUiOjEsImV4cCI6MTUzOTYxNzcwNX0.ifadEaqEo7LNWPuPBl8zQMZqeFvxfVPgAD6asNdMQYY"

[
    {
        "Id": 1,
        "Name": "dev"
    },
    {
        "Id": 2,
        "Name": "qa"
    },
    {
        "Id": 3,
        "Name": "ops"
    }
]

```

##### *示例: 从文本中读取json数据来发送POST请求*
```bash
mkdir /tmp/httpie && cd /tmp/httpie

```

```bash
http POST http://your-portainer-addr/api/resource_controls \
"Authorization: Bearer xxJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcm5hbWUiOiJhZG1pbiIsInJvbGUiOjEsImV4cCI6MTUzOTYxNzcwNX0.ifadEaqEo7LNWPuPBl8zQMZqeFvxfVPgAD6asNdMQYY" \
@/tmp/httpie/1.json

```


##### *示例: 获得通过service前缀过滤后的状态*
```bash
http GET http://your-portainer-addr/api/endpoints/5/docker/services\?filters\='{"name":["dev-app1"]}' \
"Authorization: Bearer xxJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcm5hbWUiOiJhZG1pbiIsInJvbGUiOjEsImV4cCI6MTUzOTYxNzcwNX0.ifadEaqEo7LNWPuPBl8zQMZqeFvxfVPgAD6asNdMQYY" |jq '.[] | {name: .Spec.Name, id: .ID, teams: .Portainer.ResourceControl.TeamAccesses[0].TeamId}'

```


##### *3. 获得通过service前缀过滤后的ID*
```bash
http GET http://your-portainer-addr/api/endpoints/5/docker/services\?filters\='{"name":["dev-app1"]}' \
"Authorization: Bearer xxJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcm5hbWUiOiJhZG1pbiIsInJvbGUiOjEsImV4cCI6MTUzOTYxNzcwNX0.ifadEaqEo7LNWPuPBl8zQMZqeFvxfVPgAD6asNdMQYY" |jq '.[].ID' > .id

```


##### *4. 根据上述信息，批量执行API来设置team权限*
```bash
s1='{"Type": "service", "Public": false, "ResourceID": "'
s2='", "Users": [], "Teams": [2]}'

for ID in `cat .id |sed 's/"//g'`;do
  echo $ID
  echo ${s1}${ID}${s2} >setup.json

  http POST http://your-portainer-addr/api/resource_controls \
  "Authorization: Bearer xxJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcm5hbWUiOiJhZG1pbiIsInJvbGUiOjEsImV4cCI6MTUzOTYxNzcwNX0.ifadEaqEo7LNWPuPBl8zQMZqeFvxfVPgAD6asNdMQYY" \
  @/tmp/httpie/setup.json

  echo '---------'
done

```


##### *5. 根更新team权限*
```bash
s3='{"Public": false, "Users":[], "Teams":[2]}'


for ID in `cat .id |sed 's/"//g'`;do
  echo ${ID}
  echo ${s3} >modify.json

  echo '[+] Portainer.ResourceControl.ID:'
  portainer_svc_rc_id=`http GET "http://your-portainer-addr/api/endpoints/5/docker/services/${ID}" \
  "Authorization: Bearer xxJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcm5hbWUiOiJhZG1pbiIsInJvbGUiOjEsImV4cCI6MTUzOTYxNzcwNX0.ifadEaqEo7LNWPuPBl8zQMZqeFvxfVPgAD6asNdMQYY" |jq '.Portainer.ResourceControl.Id'`
  echo ${portainer_svc_rc_id}

  echo '[+] Update:'
  http PUT "http://your-portainer-addr/api/resource_controls/${portainer_svc_rc_id}" \
  "Authorization: Bearer xxJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6MSwidXNlcm5hbWUiOiJhZG1pbiIsInJvbGUiOjEsImV4cCI6MTUzOTYxNzcwNX0.ifadEaqEo7LNWPuPBl8zQMZqeFvxfVPgAD6asNdMQYY" \
  @/tmp/httpie/modify.json

  echo '---------'
done

```




### ZYXW、参考
1、swagger
https://app.swaggerhub.com/apis/deviantony/Portainer/1.19.2/#/
2、issuecomment
https://github.com/portainer/portainer/pull/2137#issuecomment-426421950
3、releases-tag-1.19.2
https://github.com/portainer/portainer/releases/tag/1.19.2
