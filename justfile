default:
  @just --list

application: 
    cp /workspace/_cfg/auth-vars.yml /workspace/playbooks/fabric-test-network/
    /workspace/scripts/deploy_smart_contract.sh
    cp /workspace/playbooks/fabric-test-network/*.json /workspace/_cfg/

network:
    cp /workspace/_cfg/auth-vars.yml /workspace/playbooks/fabric-test-network/
    /workspace/scripts/build_network.sh build
    /workspace/scripts/join_network.sh join
    /workspace/scripts/generate_connection_info.sh
    cp /workspace/playbooks/fabric-test-network/*.json /workspace/_cfg/

console:
    /workspace/scripts/install_console.sh
    cp /workspace/playbooks/fabric-test-network/auth-vars.yml /workspace/_cfg/
