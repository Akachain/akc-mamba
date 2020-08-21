## Setup step
1. Deploy couchdb stateful & services
k apply -f couchdb-cluster-stateful.yaml
k apply -f couchdb-cluster-service.yaml

2. Configure a Cluster
- exec into 1 replicate (node 0)
k exec -it -n akctest couchdb1-akctest-0 bash
- setup cluster
curl -X POST -H "Content-Type: application/json" http://admin:password@127.0.0.1:5984/_cluster_setup -d '{"action": "enable_cluster", "bind_address":"0.0.0.0", "username": "admin", "password":"password", "port": 5984, "node_count": "3", "remote_node": "couchdb1-akctest-1.couch-service", "remote_current_user": "admin", "remote_current_password": "password" }'
- add note 1
curl -X POST -H "Content-Type: application/json" http://admin:password@127.0.0.1:5984/_cluster_setup -d '{"action": "add_node", "host":"couchdb1-akctest-1.couch-service", "port": 5984, "username": "admin", "password":"password"}'
- add note 2
curl -X POST -H "Content-Type: application/json" http://admin:password@127.0.0.1:5984/_cluster_setup -d '{"action": "add_node", "host":"couchdb1-akctest-2.couch-service", "port": 5984, "username": "admin", "password":"password"}'
- add note 3
curl -X POST -H "Content-Type: application/json" http://admin:password@127.0.0.1:5984/_cluster_setup -d '{"action": "add_node", "host":"couchdb1-akctest-3.couch-service", "port": 5984, "username": "admin", "password":"password"}'
- add note 4
curl -X POST -H "Content-Type: application/json" http://admin:password@127.0.0.1:5984/_cluster_setup -d '{"action": "add_node", "host":"couchdb1-akctest-4.couch-service", "port": 5984, "username": "admin", "password":"password"}'
- add note 5
curl -X POST -H "Content-Type: application/json" http://admin:password@127.0.0.1:5984/_cluster_setup -d '{"action": "add_node", "host":"couchdb1-akctest-5.couch-service", "port": 5984, "username": "admin", "password":"password"}'

- finish setup
curl -X POST -H "Content-Type: application/json" http://admin:password@127.0.0.1:5984/_cluster_setup -d '{"action": "finish_cluster"}'

- add note 3
curl -X PUT "http://admin:password@127.0.0.1:5986/_nodes/couchdb1-akctest-3.couch-service" -d {}
- add note 4
curl -X PUT "http://admin:password@127.0.0.1:5986/_nodes/couchdb1-akctest-4.couch-service" -d {}
- add note 5
curl -X PUT "http://admin:password@127.0.0.1:5986/_nodes/couchdb1-akctest-5.couch-service" -d {}

3. Check cluster
curl -X GET http://admin:password@127.0.0.1:5984/_membership

4. Deploy peer
k apply -f peer-using-couchdb-cluster-stateful.yaml

5. Join channel, install, init chaincode

## Some useful APIs:
* Get all database
curl -X GET http://admin:password@127.0.0.1:5984/_all_dbs

* Get all shards of 1 database
curl -s http://admin:password@127.0.0.1:5984/akctestchannel_fabcar1/_shards

* Get all shards of 1 document
curl -s http://admin:password@127.0.0.1:5984/akctestchannel_fabcar1/_shards/cc66ecd783d1559158aace7c7e000605
