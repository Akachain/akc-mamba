## The list of crypto-configs is required to start network components:

1. ICA
 - FABRIC_CA_SERVER_INTERMEDIATE_TLS_CERTFILES: /data/rca-cert.pem
2. Orderer
 - FABRIC_CA_CLIENT_TLS_CERTFILES: /data/ica-orderer-ca-chain.pem
 - ORDERER_GENERAL_LOCALMSPDIR: /shared/crypto-config/ordererOrganizations/orderer/orderers/
 orderer0-orderer.orderer/msp
    ```
    |-- admincerts
    |   `-- cert.pem
    |-- cacerts
    |   `-- ca.orderer-cert.pem
    |-- keystore
    |   `-- key.pem
    |-- signcerts
    |   `-- cert.pem
    `-- tlscacerts
        `-- tlsca.orderer-cert.pem
    ```
 - ORDERER_GENERAL_GENESISFILE: /shared/genesis.block
 - ORDERER_GENERAL_TLS_PRIVATEKEY: /shared/crypto-config/ordererOrganizations/orderer/orderers/orderer0-orderer.orderer/tls/server.key
 - ORDERER_GENERAL_TLS_CERTIFICATE: /shared/crypto-config/ordererOrganizations/orderer/orderers/orderer0-orderer.orderer/tls/server.crt
 - ORDERER_GENERAL_TLS_ROOTCAS: /shared/crypto-config/ordererOrganizations/orderer/orderers/orderer0-orderer.orderer/tls/tlsca.orderer-cert.pem
3. Peer
 - FABRIC_CA_CLIENT_TLS_CERTFILES: /data/ica-org-ca-chain.pem
 - CORE_PEER_MSPCONFIGPATH: /shared/peers/peer0.org1/msp/
   ```
    |-- admincerts
    |   `-- cert.pem
    |-- cacerts
    |   `-- ca.org1-cert.pem
    |-- keystore
    |   `-- key.pem
    |-- signcerts
    |   `-- cert.pem
    `-- tlscacerts
        `-- tlsca.org1-cert.pem
   ```
 - CORE_PEER_TLS_CERT_FILE: /shared/peers/peer0.org1/tls/server.crt
 - CORE_PEER_TLS_KEY_FILE: /shared/peers/peer0.org1/tls/server.key
 - CORE_PEER_TLS_ROOTCERT_FILE: /shared/peers/peer0.org1/tls/tlsca.org1-cert.pem
4. Admin-App and D-app
 - organizations_adminPrivateKey_path:  /shared/crypto-config/peerOrganizations/org1/users/admin/msp/keystore/key.pem
 - organizations_adminPrivateKey_signedCert: /shared/crypto-config/peerOrganizations/org1/users/admin/msp/signcerts/cert.pem
 - orderers_orderer0.orderer_tlsCACerts: /shared/ica-orderer-ca-chain.pem
 - peers_peer0.org1_tlsCACerts: /shared/ica-org1-ca-chain.pem
 - peers_peer1.org1_tlsCACerts: /shared/ica-org1-ca-chain.pem
 - peers_peer0.org2_tlsCACerts: /shared/ica-org2-ca-chain.pem
 - peers_peer1.org2_tlsCACerts: /shared/ica-org2-ca-chain.pem
 - certificateAuthorities_ca-org1_tlsCACerts_path: /shared/ica-org1-ca-chain.pem