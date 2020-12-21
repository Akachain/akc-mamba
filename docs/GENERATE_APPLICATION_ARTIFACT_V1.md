- Run admin-v1
Create github secret to pull image:
```
kubectl create secret docker-registry mamba --docker-server=docker.pkg.github.com --docker-username=your_username --docker-password=your_token --docker-email=your_email -n orderer
```
Use mamba to setup admin v1
```
mamba adminv1 setup
```

- Generate artifact
```
mamba gen-artifact setup
```

- Generate folder crypto-config v1
```
mamba updatefolder
```

- Create User
Exec to efs pod:
```ls
kubectl exec -it test-efs-xxxxxxxxxxx-xxxx bash
curl -s -X POST   http://localhost:4001/registerUser   -H "content-type: application/json"   -d '{
  "orgname":"Org1",
  "username":"User1"
}'
```
