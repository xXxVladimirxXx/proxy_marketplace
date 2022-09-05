#!/bin/sh

set -xe

account=Test2
module=market
module_wasm="${module}.wasm"
module_name="${module}_module"

market_contract="MarketplaceBeatoken"
market_instance="market_instance"

proxy_contract="MarketplaceBeatoken-Proxy"
proxy_instance="proxy_instance"

confirm() {
    printf 'y\n123456\n'
}

concordium() {
    confirm | concordium-client $* 
}



deploy_module() {
    cargo concordium build      \
        --out "${module_wasm}"

    concordium \
        module remove-name "${module_name}" || echo "name not exists."

    concordium \
        module deploy "${module_wasm}"  \
        --sender $account               \
        --name $module_name
}


init_marketplace() {
    concordium \
        contract remove-name "${market_instance}" || echo "${market_instance} name not exists."

    concordium \
        contract init $module_name           \
        --sender      $account               \
        --contract    $market_contract       \
        --name        $market_instance       \
        --energy 10000
}


init_proxy() {
    cat <<'EOF' > init_proxy_param.json
    {
        "implementation_address": {"index":947,"subindex":0}
    }
EOF

    concordium \
        contract remove-name "${proxy_instance}" || echo "${proxy_instance} name not exists."

    concordium \
        contract init $module_name              \
        --sender      $account                  \
        --contract    $proxy_contract           \
        --name        $proxy_instance           \
        --schema      schema-place-for-sale.bin \
        --parameter-json=init_proxy_param.json  \
        --energy 10000
}


proxy_list_for_sale() {
    concordium \
        contract invoke $proxy_instance     \
        --schema schema-get-listed.bin      \
        --entrypoint view_list_for_sale             
}


proxy_place_for_sale() {
    cat <<'EOF' > place_for_sale.json
    {
        "token_id": "02000000",
        "price":    "00000000"
    }
EOF
    concordium \
        contract update $proxy_instance         \
        --sender      $account                  \
        --energy 10000                          \
        --schema      schema-place-for-sale.bin \
        --entrypoint  place_for_sale            \
        --parameter-json=place_for_sale.json
}

proxy_withdraw() {
    cat <<'EOF' > withdraw.json
    {
        "token_id": "01000000"
    }
EOF
    concordium \
        contract update $proxy_instance         \
        --sender      $account                  \
        --energy 10000                          \
        --schema      schema-withdraw.bin       \
        --entrypoint  withdraw                  \
        --parameter-json=withdraw.json
}

proxy_list_for_sale

