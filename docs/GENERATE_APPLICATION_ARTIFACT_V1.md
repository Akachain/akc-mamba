- Run admin-v1
```
python3 mamba.py adminv1 setup
```

- Generate artifact
```
python3 mamba.py gen-artifact setup
```

- Generate folder crypto-config v1
```
python3 mamba.py updatefolder
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