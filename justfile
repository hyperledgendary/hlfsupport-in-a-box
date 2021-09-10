default:
  @just --list

network:
    cp /workspace/_cfg/auth-vars.yml /workspace/playbooks/fabric-test-network/
    /workspace/scripts/build_network.sh build
    /workspace/scripts/join_network.sh join

console:
    /workspace/scripts/install_console.sh
    cp /workspace/playbooks/fabric-test-network/auth-vars.yml /workspace/_cfg/
